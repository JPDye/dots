# shellcheck shell=bash
# Root-level PAM plumbing that nix-run desktop apps need on Arch:
#   1. the two root-owned files hyprlock needs to authenticate
#   2. gnome-keyring PAM integration, so a login keyring exists for apps
#      that store secrets (Termius keeps its database key there)
# Wrapped by writeShellApplication in hosts/laptop-arch/pam-setup.nix, which
# provides bash strict mode plus:
#   PAM_SERVICE_FILE - store path of the /etc/pam.d/hyprlock content
#   TMPFILES_RULE    - store path of the /etc/tmpfiles.d rule
: "${PAM_SERVICE_FILE:?}" "${TMPFILES_RULE:?}"

if [[ $EUID -ne 0 ]]; then
  exec sudo -- "$0" "$@"
fi

# Arch ships this in the `pam` package. Without it the tmpfiles rule below
# only makes a dangling symlink, so fail early with a clear reason.
if [[ ! -u /usr/bin/unix_chkpwd ]]; then
  echo "error: /usr/bin/unix_chkpwd is missing or not setuid root." >&2
  echo "       reinstall the pam package, then run this again." >&2
  exit 1
fi

echo "==> install /etc/pam.d/hyprlock"
install -Dm644 "$PAM_SERVICE_FILE" /etc/pam.d/hyprlock

echo "==> install /etc/tmpfiles.d/nix-pam-wrappers.conf"
install -Dm644 "$TMPFILES_RULE" /etc/tmpfiles.d/nix-pam-wrappers.conf
systemd-tmpfiles --create /etc/tmpfiles.d/nix-pam-wrappers.conf

# The tmpfiles rule is applied, not just written. Confirm the helper now
# resolves to a setuid binary, because a dangling link fails the same silent
# way the original bug did.
if [[ ! -u $(readlink -f /run/wrappers/bin/unix_chkpwd) ]]; then
  echo "error: /run/wrappers/bin/unix_chkpwd does not resolve to a setuid binary." >&2
  exit 1
fi

# Every unlock attempt made before this fix counted as an authentication
# failure, so pam_faillock can still hold the account locked. Clear it.
if [[ -n ${SUDO_USER:-} ]]; then
  echo "==> reset pam_faillock counters for $SUDO_USER"
  faillock --reset --user "$SUDO_USER"
fi

# --- gnome-keyring: create and unlock a login keyring at login --------------
# The nix-run gnome-keyring daemon answers the Secret Service bus name, but
# on a TTY login nothing creates or unlocks a keyring, and the dialog that
# would create one on demand has no prompter on this session. Any app that
# stores a secret then fails (Termius hangs on a blank splash).
# pam_gnome_keyring fixes the root cause: at login it takes the password and
# creates or unlocks ~/.local/share/keyrings/login.keyring. The module must
# link Arch's libpam, so it comes from Arch's gnome-keyring package, same as
# unix_chkpwd above comes from Arch's pam.
if [[ ! -e /usr/lib/security/pam_gnome_keyring.so ]]; then
  echo "==> install Arch's gnome-keyring (provides pam_gnome_keyring.so)"
  pacman -S --needed gnome-keyring
fi

# This host starts niri from a TTY, so /etc/pam.d/login is the session entry
# point. Appending is correct: the auth line needs the password captured by
# system-local-login first, and auto_start needs pam_systemd's session.
if ! grep -q pam_gnome_keyring /etc/pam.d/login; then
  echo "==> add pam_gnome_keyring to /etc/pam.d/login"
  printf '%s\n' \
    'auth       optional     pam_gnome_keyring.so' \
    'session    optional     pam_gnome_keyring.so auto_start' \
    >>/etc/pam.d/login
fi

# libsecret reaches the keyring through the "default" alias, which resolves
# via this plain file. Point it at the login keyring, because no prompter
# runs on this session to pick one interactively.
if [[ -n ${SUDO_USER:-} ]]; then
  user_home=$(getent passwd "$SUDO_USER" | cut -d: -f6)
  user_group=$(id -gn "$SUDO_USER")
  keyrings_dir="$user_home/.local/share/keyrings"
  if [[ ! -e "$keyrings_dir/default" ]]; then
    echo "==> set the default keyring alias to 'login'"
    install -d -m 700 -o "$SUDO_USER" -g "$user_group" "$keyrings_dir"
    printf 'login\n' >"$keyrings_dir/default"
    chown "$SUDO_USER:$user_group" "$keyrings_dir/default"
    chmod 644 "$keyrings_dir/default"
  fi
fi

if [[ ! -e /usr/lib/security/pam_gnome_keyring.so ]] ||
  ! grep -q pam_gnome_keyring /etc/pam.d/login; then
  echo "error: gnome-keyring PAM integration is incomplete." >&2
  exit 1
fi

echo "done."
echo "hyprlock: lock the session and enter your password to confirm."
echo "keyring:  log out to the TTY and back in, then start termius to confirm."
