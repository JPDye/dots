# shellcheck shell=bash
# Guided from-ISO installer for this flake. Wrapped by writeShellApplication
# in installer/iso.nix, which provides bash strict mode plus:
#   FLAKE_SRC     - store path of the bundled repo (offline fallback)
#   REPO_URL      - canonical remote, cloned first to preserve history
#   SELF_REV      - repo revision the ISO was built from ("" if dirty)
#   TEMPLATE_DIR  - store path of installer/host-template
#   STATE_VERSION - nixpkgs release at ISO build time (system.stateVersion)
: "${FLAKE_SRC:?}" "${REPO_URL:?}" "${SELF_REV?}" "${TEMPLATE_DIR:?}" "${STATE_VERSION:?}"

if [[ $EUID -ne 0 ]]; then
  exec sudo "$0" "$@"
fi

# modules/system/boot.nix is systemd-boot only — no BIOS/MBR fallback.
if [[ ! -d /sys/firmware/efi ]]; then
  echo "this machine did not boot via UEFI; fix that in firmware setup first" >&2
  exit 1
fi

# ---- Gather every input up front, so the install runs unattended after the
# ---- final confirmation (the closure copy is the long part).

# The medium we booted from must not be an install target.
boot_disk=""
iso_src=$(findmnt --noheadings --output SOURCE /iso 2>/dev/null || true)
if [[ -n $iso_src ]]; then
  boot_disk=$(lsblk --noheadings --output PKNAME "$iso_src" 2>/dev/null || true)
  if [[ -n $boot_disk ]]; then boot_disk="/dev/$boot_disk"; else boot_disk=$iso_src; fi
fi

echo "Disks:"
lsblk --nodeps --paths --output NAME,SIZE,MODEL --exclude 7,11
if [[ -n $boot_disk ]]; then
  echo "(note: $boot_disk is the installer medium itself)"
fi
echo
read -rp "Disk to install to (WILL BE COMPLETELY WIPED): " disk
if [[ ! -b $disk ]]; then
  echo "not a block device: $disk" >&2
  exit 1
fi
if [[ -n $boot_disk && $disk == "$boot_disk" ]]; then
  echo "$disk is the medium you booted the installer from" >&2
  exit 1
fi

read -rp "Hostname for the new machine: " host
if [[ ! $host =~ ^[a-z0-9][a-z0-9-]*$ ]]; then
  echo "hostname must be lowercase alphanumerics/hyphens" >&2
  exit 1
fi
if [[ -e "$FLAKE_SRC/hosts/$host" ]]; then
  echo "hosts/$host already exists in the bundled repo" >&2
  exit 1
fi

read -rp "Encrypt the root partition with LUKS? [y/N]: " encrypt
encrypt=${encrypt,,}
luks_pw=""
if [[ $encrypt == y ]]; then
  while true; do
    read -rsp "LUKS passphrase: " luks_pw && echo
    read -rsp "Confirm passphrase: " luks_pw2 && echo
    if [[ -n $luks_pw && $luks_pw == "$luks_pw2" ]]; then break; fi
    echo "empty or mismatched — try again"
  done
  unset luks_pw2
fi

while true; do
  read -rsp "Login password for jd: " user_pw && echo
  read -rsp "Confirm password: " user_pw2 && echo
  if [[ -n $user_pw && $user_pw == "$user_pw2" ]]; then break; fi
  echo "empty or mismatched — try again"
done
unset user_pw2

echo
echo "About to WIPE $disk and install NixOS host '$host' onto it."
read -rp "Type the disk path again to confirm: " confirm
if [[ $confirm != "$disk" ]]; then
  echo "aborted" >&2
  exit 1
fi

# ---- Prepare the repo + new host in a temp dir BEFORE touching the disk, so
# ---- any failure here (clone, sed drift, ...) aborts with the disk intact.

tmp=$(mktemp --directory)
repo="$tmp/repo"
branch="install-$host"

# Prefer a real clone so the installed machine keeps history and a remote;
# fall back to the bundled snapshot (single orphan commit) when offline or
# the repo is unreachable.
if timeout 30 git clone --quiet -- "$REPO_URL" "$repo" 2>/dev/null; then
  if [[ -n $SELF_REV ]] && git -C "$repo" cat-file -e "$SELF_REV" 2>/dev/null; then
    git -C "$repo" checkout --quiet -B "$branch" "$SELF_REV"
  else
    echo "note: ISO was built from an unpushed/dirty tree; installing from remote HEAD"
    git -C "$repo" checkout --quiet -B "$branch"
  fi
else
  echo "note: clone of $REPO_URL failed — using the ISO's bundled copy (no history)"
  mkdir "$repo"
  cp -rT "$FLAKE_SRC" "$repo"
  chmod -R u+w "$repo"
  git -C "$repo" init --quiet --initial-branch "$branch"
  git -C "$repo" remote add origin "$REPO_URL"
fi

hostdir_rel="hosts/$host"
mkdir "$repo/$hostdir_rel"
for f in configuration.nix home.nix; do
  sed -e "s/@HOSTNAME@/$host/g" -e "s/@STATE_VERSION@/$STATE_VERSION/g" \
    "$TEMPLATE_DIR/$f" >"$repo/$hostdir_rel/$f"
done

# Register the host in flake.nix's hand-maintained nixosHosts list. Anchor on
# the opening bracket only (formatting-proof) and insert on its own line.
sed -i "0,/nixosHosts = \[/s//nixosHosts = [\n        \"$host\"/" "$repo/flake.nix"
if ! grep -qF "\"$host\"" "$repo/flake.nix"; then
  echo "failed to register $host in flake.nix's nixosHosts list" >&2
  exit 1
fi

# ---- Point of no return: partition, (encrypt,) format, mount.

# Best-effort teardown of a previous half-finished attempt, so a re-run
# doesn't die at wipefs on a busy device.
umount --recursive /mnt 2>/dev/null || true
cryptsetup close cryptroot 2>/dev/null || true

wipefs --all "$disk"
parted --script "$disk" -- \
  mklabel gpt \
  mkpart ESP fat32 1MiB 1GiB \
  set 1 esp on \
  mkpart root ext4 1GiB 100%
udevadm settle

# /dev/sda -> /dev/sda1, /dev/nvme0n1 -> /dev/nvme0n1p1
part() {
  if [[ $disk =~ [0-9]$ ]]; then echo "${disk}p$1"; else echo "${disk}$1"; fi
}

root_dev=$(part 2)
if [[ $encrypt == y ]]; then
  printf %s "$luks_pw" | cryptsetup luksFormat --type luks2 --batch-mode "$(part 2)" -
  printf %s "$luks_pw" | cryptsetup open --key-file=- "$(part 2)" cryptroot
  root_dev=/dev/mapper/cryptroot
fi
unset luks_pw

mkfs.fat -F 32 -n BOOT "$(part 1)"
mkfs.ext4 -F -L nixos "$root_dev"
mount "$root_dev" /mnt
mkdir -p /mnt/boot
# 0077 masks so nixos-generate-config records the same /boot options
# hosts/laptop-nix has (keeps loader entries/random-seed non-world-readable).
mount -o fmask=0077,dmask=0077 "$(part 1)" /mnt/boot

# ---- Land the repo where it lives on every host and finish the host config
# ---- with the bits that need real hardware/partitions.

dest=/mnt/home/jd/.config/nix
mkdir -p /mnt/home/jd/.config
cp -aT "$repo" "$dest"
hostdir="$dest/$hostdir_rel"

nixos-generate-config --root /mnt --show-hardware-config \
  >"$hostdir/hardware-configuration.nix"

if [[ $encrypt == y ]]; then
  luks_uuid=$(blkid -s UUID -o value "$(part 2)")
  sed -i "s|# installer:luks.*|boot.initrd.luks.devices.cryptroot.device = \"/dev/disk/by-uuid/$luks_uuid\";|" \
    "$hostdir/configuration.nix"
else
  sed -i "/# installer:luks/d" "$hostdir/configuration.nix"
fi

# Flakes only see git-tracked files — commit the stamped host so the
# nixos-install evaluation can see it.
git -C "$dest" add --all
git -C "$dest" -c user.name=installer -c user.email=installer@localhost \
  commit --quiet --message "install: add host $host"

# The ISO store carries the prebuilt host closure + all flake input sources
# (installer/iso.nix bakes them in), so this is mostly a local copy — only the
# delta from this machine's hardware-configuration.nix gets built/fetched.
nixos-install --root /mnt --no-root-passwd --no-channel-copy --flake "$dest#$host"

# users.nix declares jd without a password — set the one gathered up front,
# and let the installed system resolve jd's real uid/gid for the chown.
printf '%s\n' "jd:$user_pw" | nixos-enter --root /mnt -c chpasswd
unset user_pw
nixos-enter --root /mnt -c 'chown -R jd: /home/jd'

# Carry wifi credentials over so the machine boots online.
if compgen -G '/etc/NetworkManager/system-connections/*' >/dev/null; then
  mkdir -p /mnt/etc/NetworkManager/system-connections
  cp -a /etc/NetworkManager/system-connections/. /mnt/etc/NetworkManager/system-connections/
fi

echo
echo "Done. After rebooting into '$host':"
echo "  - review + push the new host: git push -u origin $branch (then merge)"
echo "    (if the clone fallback was used the repo has no history — fetch"
echo "     origin and cherry-pick the install commit onto it)"
echo "  - swapfile/hibernate is machine-specific and NOT set up — crib from"
echo "    hosts/laptop-nix/configuration.nix if wanted"
echo
echo "Reboot with: reboot"
