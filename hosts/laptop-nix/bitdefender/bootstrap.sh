#!/usr/bin/env bash
#
# Install Bitdefender Security Tools (GravityZone) on NixOS.
#
# Bitdefender does not support NixOS. The shipped `installer` asks
# `bdconfigure --distro-pkgmgr` / `--distro-pkgfmt` which package format to
# use, and both fail here. This script stages a patched copy of the installer
# with those answers hardcoded (apt/deb), then installs the .deb with
# `dpkg -i --path-exclude='/etc/*'`.
#
# The exclusion matters. /etc/systemd/system on NixOS is a symlink to a
# read-only store path, so a package that writes units there fails. Every file
# the package would put under /etc is declared in modules/system/bitdefender.nix
# instead: the eight systemd units, the two hourly jobs (as timers) and the
# bduitool sudoers rule.
#
# Patches applied to `installer`:
#   1. pkgmgr=apt / PKGMGR=apt / pkgfmt=deb   (5 sites) -- branch selectors
#   2. logsetup -> plain redirect             (1 site)  -- keeps die() readable
#   3. apt_too_old() -> return 0              (1 site)  -- forces the dpkg path
#   4. dpkg -i gains --path-exclude='/etc/*'  (1 site)  -- the live install
#   5. `apt-get -q install -y -f || die 75` -> `die 75`
#   6. the unused apt-get install branch -> dpkg
#   7. `apt-get purge ...` -> `dpkg --purge ...`        -- uninstall path
#
# Run modules/system/bitdefender.nix first. This script refuses to start until
# that module is active, because the install depends on the users, the /bin
# shims and the nix-ld loader it provides.
#
# Usage: sudo ./bootstrap.sh [options]
#
# The patch table below is full of single-quoted regexes and sed replacements
# that must keep their '$' literal. Expanding them is exactly what we do not
# want, so silence the file-wide hint about it.
# shellcheck disable=SC2016

set -euo pipefail

SELF_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
SELF_PATH="$SELF_DIR/$(basename -- "${BASH_SOURCE[0]}")"

SRC_DIR="$SELF_DIR"
WORK_DIR="/var/tmp/bdst-nixos-install"
INSTALL_DIR="/opt/bitdefender-security-tools"
LD_ENV_FILE="/etc/bitdefender/ld-env"
ACTION=1
TRACE=0
DRY_RUN=0
RESET=0
ASSUME_YES=0
INTERNAL_DPKG=0
INTERNAL_DEB=""

REQUIRED_FILES=(installer installer.xml bdconfigure)

usage ()
{
    cat <<-EOF
	Usage: sudo $0 [options]

	  --src DIR      directory holding installer, installer.xml, bdconfigure
	                 (default: $SELF_DIR)
	  --work DIR     staging directory for the patched installer
	                 (default: $WORK_DIR)
	  --action N     1=install (default) 2=reconfigure 3=repair 4=uninstall
	  --trace        run the installer under 'sh -x'
	  --dry-run      preflight and patch only; do not run the installer
	  --reset        purge a failed install and exit, so the next run is a
	                 fresh install rather than an upgrade. Keeps the
	                 downloaded components and makes removal fstab-safe first
	  -y, --yes      do not prompt for confirmation
	  -h, --help     this message
	EOF
}

log  () { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn () { printf '\033[1;33m==> WARNING:\033[0m %s\n' "$*" >&2; }
die  () { printf '\033[1;31m==> ERROR:\033[0m %s\n' "$*" >&2; exit 1; }

confirm ()
{
    [ "$ASSUME_YES" -eq 1 ] && return 0
    local reply
    printf '\033[1;33m==>\033[0m %s [y/N] ' "$1"
    read -r reply
    [ "$reply" = "y" ] || [ "$reply" = "Y" ]
}

parse_args ()
{
    while [ $# -gt 0 ]; do
        case "$1" in
            --src)     SRC_DIR=$(readlink -f "$2"); shift 2 ;;
            --work)    WORK_DIR=$(readlink -f "$2"); shift 2 ;;
            --action)  ACTION="$2"; shift 2 ;;
            --trace)   TRACE=1; shift ;;
            --dry-run) DRY_RUN=1; shift ;;
            --reset)   RESET=1; shift ;;
            # Not for humans. The staged helper re-enters the script with this
            # so the installer's package step becomes unpack, patch, configure.
            --internal-dpkg-install)
                       INTERNAL_DPKG=1; INTERNAL_DEB="$2"; shift 2 ;;
            -y|--yes)  ASSUME_YES=1; shift ;;
            -h|--help) usage; exit 0 ;;
            *)         usage >&2; die "unknown argument: $1" ;;
        esac
    done

    case "$ACTION" in
        1|2|3|4) ;;
        *) die "--action must be 1, 2, 3 or 4" ;;
    esac
}

preflight ()
{
    [ "$(id -u)" -eq 0 ] || die "must run as root"
    [ -e /etc/NIXOS ] || die "this host is not NixOS; use the Arch or vendor path instead"

    local f
    for f in "${REQUIRED_FILES[@]}"; do
        [ -f "$SRC_DIR/$f" ] || die "missing $SRC_DIR/$f -- point --src at the unpacked installer.tar"
    done

    [ "$(uname -m)" = "x86_64" ] || die "the patched installer hardcodes an amd64 deb name"

    # Everything below comes from modules/system/bitdefender.nix. Without it
    # the install half-succeeds and leaves a broken agent behind.
    [ -f "$LD_ENV_FILE" ] \
        || die "$LD_ENV_FILE is missing -- set dotfiles.system.bitdefender.enable and rebuild first"
    [ -e /lib64/ld-linux-x86-64.so.2 ] \
        || die "no nix-ld loader at /lib64/ld-linux-x86-64.so.2 -- is programs.nix-ld.enable set?"
    [ -x /bin/systemctl ] \
        || die "/bin/systemctl shim is missing -- rebuild with the bitdefender module active"
    getent group bitdefender >/dev/null \
        || die "the 'bitdefender' group does not exist -- rebuild with the bitdefender module active"
    command -v dpkg >/dev/null \
        || die "dpkg not on PATH -- rebuild with the bitdefender module active"

    # bdconfigure fails these two here; that is the whole reason for patch 1.
    if "$SRC_DIR/bdconfigure" --distro-pkgmgr >/dev/null 2>&1; then
        warn "bdconfigure --distro-pkgmgr now succeeds; the pkgmgr patch may be unnecessary"
    fi
}

# The package maintainer scripts call the product's own jq and bdconfigure,
# which are foreign FHS binaries. They inherit this environment through dpkg.
export_ld_env ()
{
    set -a
    # shellcheck disable=SC1090
    . "$LD_ENV_FILE"
    set +a
    log "nix-ld loader: $NIX_LD"
}

# Nothing on NixOS creates the dpkg admin directory, and dpkg refuses to run
# without it.
init_dpkg_db ()
{
    if [ -f /var/lib/dpkg/status ]; then
        log "dpkg database already present"
        return 0
    fi

    log "initialising the dpkg database at /var/lib/dpkg"
    mkdir -p /var/lib/dpkg/{info,updates,triggers,alternatives,parts}
    : >>/var/lib/dpkg/status
    : >>/var/lib/dpkg/available
}

# A failed install leaves dpkg reporting 'half-configured'. The installer reads
# that as an existing version and takes its upgrade path, which skips
# configure_epag and therefore skips enrolment. Purging first makes the next
# run a real install.
reset_install ()
{
    local setup="$INSTALL_DIR/var/tmp/setup/linux-amd64"

    dpkg-query --show bitdefender-security-tools >/dev/null 2>&1 \
        || { log "nothing to reset; dpkg does not know the package"; return 0; }

    log "current state: $(dpkg-query -f '${Status}' --show bitdefender-security-tools)"

    # postrm 'remove' runs rm -rf on the install directory, so rescue the
    # downloaded components first. stage_and_patch picks them up next run.
    if [ -d "$setup" ] && [ ! -d "$SRC_DIR/linux-amd64" ]; then
        log "keeping the downloaded components in $SRC_DIR/linux-amd64"
        cp -a -- "$setup" "$SRC_DIR/linux-amd64"
    fi

    neuter_prerm_systemctl
    neuter_postrm_fstab
    prune_dpkg_etc_list

    confirm "purge bitdefender-security-tools and delete $INSTALL_DIR?" \
        || { log "aborted"; exit 0; }

    dpkg --purge bitdefender-security-tools || die "purge failed"

    # postrm removes this, and the module declares it, so put it back rather
    # than wait for the next rebuild.
    getent group bduitool >/dev/null \
        || warn "the bduitool group is gone until the next nixos-rebuild switch"

    log "reset done. Re-run without --reset for a fresh install."
}

# Rewrites lines of the staged installer matching an ERE, asserting the match
# count first so a changed installer version fails loudly instead of silently
# installing something unpatched. '%' is the sed delimiter, so neither the
# pattern nor the replacement may contain it.
patch_line ()
{
    local pattern="$1" replacement="$2" want="$3" label="$4"
    local target="$WORK_DIR/installer"
    local before after got

    got=$(grep -cE -- "$pattern" "$target" || true)
    [ "$got" -eq "$want" ] || die "patch '$label': expected $want matching line(s), found $got -- installer version changed?"

    before=$(md5sum < "$target")
    sed -i -E "s%${pattern}%${replacement}%" "$target"
    after=$(md5sum < "$target")
    [ "$before" != "$after" ] || die "patch '$label': sed made no change"

    log "patched $label ($want site(s))"
}

stage_and_patch ()
{
    log "staging into $WORK_DIR"
    rm -rf "$WORK_DIR"
    mkdir -p "$WORK_DIR"
    chmod 0700 "$WORK_DIR"

    # bdconfigure mktemp's into its own directory, so the whole set must be
    # staged together and the directory must be writable.
    local f
    for f in "${REQUIRED_FILES[@]}"; do
        cp -p -- "$SRC_DIR/$f" "$WORK_DIR/$f"
    done
    chmod u+x "$WORK_DIR/installer" "$WORK_DIR/bdconfigure"

    # copy_or_download() prefers a local file over a download, which is how the
    # vendor full kit works. Staging a linux-amd64 directory next to the
    # installer therefore turns a downloader kit into a full kit and skips the
    # 212MB fetch on every retry.
    #
    # Trade-off: the installer only verifies signatures on files it downloaded,
    # so a reused directory is trusted rather than checked. Populate it from a
    # run that did verify, or from the GravityZone console.
    if [ -d "$SRC_DIR/linux-amd64" ]; then
        cp -a -- "$SRC_DIR/linux-amd64" "$WORK_DIR/linux-amd64"
        warn "reusing $SRC_DIR/linux-amd64; the installer will not verify its signature"
    fi

    # The installer calls this in place of `dpkg -i`. It re-enters this script,
    # so the unpack, patch and configure steps stay in one file.
    cat >"$WORK_DIR/dpkg-install.sh" <<-EOF
	#!/bin/sh
	exec "$SELF_PATH" --internal-dpkg-install "\$1"
	EOF
    chmod 0700 "$WORK_DIR/dpkg-install.sh"

    # 1. Hardcode the package manager and format bdconfigure cannot detect.
    patch_line '^([[:space:]]*)pkgmgr=\$\("\$BDCONFIGURE" --distro-pkgmgr 2>/dev/null\)$' \
        '\1pkgmgr=apt' 3 'pkgmgr=apt'
    patch_line '^([[:space:]]*)PKGMGR=\$\("\$BDCONFIGURE" --distro-pkgmgr 2>/dev/null\)$' \
        '\1PKGMGR=apt' 1 'PKGMGR=apt'
    patch_line '^([[:space:]]*)pkgfmt=\$\("\$BDCONFIGURE" --distro-pkgfmt 2>/dev/null\)$' \
        '\1pkgfmt=deb' 1 'pkgfmt=deb'

    # 2. logsetup() pipes stdout and stderr into a FIFO read by
    #    `bdconfigure --logger`. If that reader exits, every line the installer
    #    prints, including die() messages, is discarded. Write to the log file
    #    directly so a failure is readable.
    patch_line '^([[:space:]]*)exec >"\$\(_log info \$\$\)" 2>"\$\(_log error \$\$\)"$' \
        '\1exec >>"$LOG_FILE" 2>\&1 # nixos: do not rely on bdconfigure --logger' \
        1 'logsetup -> plain redirect'

    # 3. apt_too_old runs `apt-get --version`, which is not installed.
    #    Short-circuit it onto the dpkg -i branch.
    patch_line '^([[:space:]]*)local ver=\$\(apt-get --version .*$' \
        '\1return 0 # nixos: force the dpkg -i branch' 1 'apt_too_old -> return 0'

    # 4. The branch that actually runs. A single `dpkg -i` gives no window to
    #    patch the maintainer scripts, and postinst calls systemctl enable and
    #    disable, neither of which can work against a read-only
    #    /etc/systemd/system. The helper splits the install into unpack, patch
    #    and configure so that window exists. See internal_dpkg_install.
    patch_line '^([[:space:]]*)dpkg -i --refuse-downgrade "\$SETUP_DIR/\$PKG_REMOTE_DIR/\$PKG_FILE"' \
        "\\1$WORK_DIR/dpkg-install.sh \"\$SETUP_DIR/\$PKG_REMOTE_DIR/\$PKG_FILE\"" \
        1 'dpkg -i -> staged helper'

    # 5. Without apt there is no dependency fixup to fall back on.
    patch_line '^([[:space:]]*)apt-get -q install -y -f \|\| die 75$' \
        '\1die 75' 1 'drop apt-get -f fallback'

    # 6. The other install branch, so no live apt-get call remains.
    patch_line '^([[:space:]]*)apt-get -q install -y "\$SETUP_DIR/\$PKG_REMOTE_DIR/\$PKG_FILE" \|\| die 75$' \
        "\\1$WORK_DIR/dpkg-install.sh \"\$SETUP_DIR/\$PKG_REMOTE_DIR/\$PKG_FILE\" || die 75" \
        1 'install via staged helper'

    # 7. Uninstall path.
    patch_line '^([[:space:]]*)apt-get purge -qq -y bitdefender-security-tools \|\| true$' \
        '\1dpkg --purge bitdefender-security-tools || true' 1 'purge via dpkg'

    # 8/9. enable_arrakis and disable_arrakis, called from control_features
    #      once the package is in. Same problem as the postinst calls: disable
    #      tries to unlink the unit symlink under the read-only
    #      /etc/systemd/system. stop_arrakis is left alone, because the module
    #      defines bdsec-arrakis and stopping an inactive unit succeeds.
    patch_line '^([[:space:]]*)systemctl enable bdsec-arrakis$' \
        '\1: # nixos: unit state is owned by nix' 1 'enable_arrakis -> no-op'
    patch_line '^([[:space:]]*)systemctl disable bdsec-arrakis$' \
        '\1: # nixos: unit state is owned by nix' 1 'disable_arrakis -> no-op'

    verify_patch
}

verify_patch ()
{
    local target="$WORK_DIR/installer" leftover

    leftover=$(grep -c -- '--distro-pkg' "$target" || true)
    [ "$leftover" -eq 0 ] || die "verify: $leftover unpatched --distro-pkg call(s) remain"

    leftover=$(grep -vE '^[[:space:]]*#' "$target" | grep -c 'apt-get' || true)
    [ "$leftover" -eq 0 ] || die "verify: $leftover live apt-get call(s) remain"

    leftover=$(grep -c 'dpkg-install\.sh' "$target" || true)
    [ "$leftover" -eq 2 ] || die "verify: expected 2 helper call sites, found $leftover"

    leftover=$(grep -cE '^[[:space:]]*dpkg -i' "$target" || true)
    [ "$leftover" -eq 0 ] || die "verify: $leftover direct dpkg -i call(s) remain"

    leftover=$(grep -cE 'systemctl (enable|disable)' "$target" || true)
    [ "$leftover" -eq 0 ] || die "verify: $leftover systemctl enable/disable call(s) remain"

    sh -n "$target" || die "verify: patched installer is not valid POSIX sh"

    log "patched installer verified: $target"
    if command -v diff >/dev/null; then
        printf '\n--- diff vs original ---\n'
        diff -u "$SRC_DIR/installer" "$target" || true
        printf -- '------------------------\n\n'
    fi
}

run_installer ()
{
    local log_file="$INSTALL_DIR/var/log/installer.log"
    local tail_pid="" rc=0

    # The installer redirects itself into the log file, so mirror it here to
    # keep the run observable rather than apparently hung.
    mkdir -p "$INSTALL_DIR/var/log"
    : >>"$log_file"
    tail -n 0 -F "$log_file" 2>/dev/null | sed 's/^/    | /' &
    tail_pid=$!

    log "running the patched installer (action $ACTION); mirroring $log_file"
    printf '\n'

    # The installer sets -e itself and trips over nounset/pipefail, so run it
    # from a shell with those explicitly off.
    local -a cmd=(sh)
    [ "$TRACE" -eq 1 ] && cmd+=(-x)
    cmd+=(-c 'set +o nounset; set +o pipefail; set -e; cd "$1"; CURRENT_ACTION="$2" ./installer' _ "$WORK_DIR" "$ACTION")

    LC_ALL=C DEBIAN_FRONTEND=noninteractive "${cmd[@]}" || rc=$?

    # Let the mirror drain the last lines before tearing it down.
    sleep 1
    kill "$tail_pid" 2>/dev/null || true
    wait "$tail_pid" 2>/dev/null || true

    if [ "$rc" -ne 0 ]; then
        printf '\n'
        warn "installer exited $rc. Full log: $log_file"
        warn "See the exit-code table near the top of the installer script for what $rc means."
        warn "Re-run with --trace for an execution trace."
        return "$rc"
    fi

    printf '\n'
    log "installer finished"
}

# postrm 'remove' rewrites /etc/fstab unconditionally to strip dazukofs mount
# lines, and dpkg runs it during --remove and --purge. /etc/fstab here is a
# symlink into the store, so `mv -f` would replace the symlink with a plain
# file and leave a stale fstab until the next rebuild. dpkg executes its own
# copy of the script, so patch that copy rather than the package.
neuter_postrm_fstab ()
{
    local p=/var/lib/dpkg/info/bitdefender-security-tools.postrm

    [ -f "$p" ] || { warn "no installed postrm at $p to patch"; return 0; }

    if grep -q '# nixos: fstab rewrite removed' "$p"; then
        log "postrm fstab rewrite already neutered"
        return 0
    fi

    if ! grep -q 'mv -f /etc/fstab.tmp /etc/fstab' "$p"; then
        warn "postrm does not contain the expected fstab rewrite; leaving it alone"
        return 0
    fi

    cp -p -- "$p" "$p.orig-unpatched"
    sed -i \
        -e 's%^\(\s*\)grep -E -v .*dazukofs.*/etc/fstab.tmp .*$%\1: # nixos: fstab rewrite removed%' \
        -e 's%^\(\s*\)cp -f /etc/fstab /etc/fstab.bak$%\1: # nixos: fstab rewrite removed%' \
        -e 's%^\(\s*\)mv -f /etc/fstab.tmp /etc/fstab$%\1: # nixos: fstab rewrite removed%' \
        "$p"

    if grep -q 'mv -f /etc/fstab.tmp /etc/fstab' "$p"; then
        die "failed to neuter the postrm fstab rewrite; do not remove this package yet"
    fi

    sh -n "$p" || die "patched postrm is not valid POSIX sh; restore $p.orig-unpatched"
    log "neutered the postrm fstab rewrite (original kept as $p.orig-unpatched)"
}

# --path-exclude stops dpkg unpacking a path, but the path still goes into the
# package file list, so removal later tries to unlink it. Every /etc entry in
# that list belongs to the module, and /etc/systemd/system/bdsec.service is a
# symlink into the read-only store, so dpkg cannot remove it and the whole
# removal fails. dpkg never created these paths, so drop them from its list.
prune_dpkg_etc_list ()
{
    local l=/var/lib/dpkg/info/bitdefender-security-tools.list
    local n

    if [ ! -f "$l" ]; then
        warn "no dpkg file list at $l"
        return 0
    fi

    n=$(grep -c '^/etc\(/\|$\)' "$l" || true)

    if [ "$n" -eq 0 ]; then
        log "dpkg file list holds no /etc entries"
        return 0
    fi

    [ -f "$l.orig-unpruned" ] || cp -p -- "$l" "$l.orig-unpruned"
    grep -v '^/etc\(/\|$\)' "$l" > "$l.tmp" || true
    mv -f "$l.tmp" "$l"

    log "pruned $n /etc entries from the dpkg file list (original kept as $l.orig-unpruned)"
}

# postinst enables and disables units, and neither can work here.
# `systemctl enable` on a NixOS unit is a harmless no-op, because the generated
# units carry no [Install] section, so systemd reports no installation config
# and exits 0. `systemctl disable` is not: it treats the symlink NixOS places
# in /etc/systemd/system as an enablement symlink and tries to unlink it, which
# the store refuses. Defining the unit and leaving it undefined therefore fail
# in opposite directions, so the calls themselves have to go. The module owns
# unit state.
neuter_postinst_systemctl ()
{
    local p=/var/lib/dpkg/info/bitdefender-security-tools.postinst

    if [ ! -f "$p" ]; then
        warn "no installed postinst at $p to patch"
        return 0
    fi

    if grep -q '# nixos: unit state is owned by nix' "$p"; then
        log "postinst systemctl block already neutered"
        return 0
    fi

    if ! grep -q '^[[:space:]]*systemctl enable bdsec ' "$p"; then
        warn "postinst does not contain the expected systemctl block; leaving it alone"
        return 0
    fi

    cp -p -- "$p" "$p.orig-unpatched"
    sed -i \
        -e 's%^\(\s*\)systemctl enable bdsec .*$%\1: # nixos: unit state is owned by nix%' \
        -e 's%^\(\s*\)\[ \$ENABLE_GZ_INTEGRATION = "ON" \] \&\& systemctl enable bdsec-epagng$%\1: # nixos: unit state is owned by nix%' \
        -e 's%^\(\s*\)( check_module .*systemctl disable bdsec-arrakis$%\1: # nixos: unit state is owned by nix%' \
        "$p"

    if grep -qE 'systemctl (enable|disable)' "$p"; then
        die "failed to neuter the postinst systemctl block"
    fi

    sh -n "$p" || die "patched postinst is not valid POSIX sh; restore $p.orig-unpatched"
    log "neutered the postinst systemctl block (original kept as $p.orig-unpatched)"
}

# Splits `dpkg -i` into unpack, patch, configure. dpkg writes the maintainer
# scripts to /var/lib/dpkg/info during unpack and only runs postinst at
# configure time, so this is the one point where postinst can be corrected
# before it executes.
internal_dpkg_install ()
{
    local deb="$1"

    [ -f "$deb" ] || die "no such package: $deb"

    log "unpacking $(basename -- "$deb")"
    dpkg --unpack --refuse-downgrade --path-exclude='/etc/*' "$deb" \
        || die "dpkg --unpack failed"

    prune_dpkg_etc_list
    neuter_postinst_systemctl
    neuter_prerm_systemctl
    neuter_postrm_fstab

    log "configuring bitdefender-security-tools"
    dpkg --configure bitdefender-security-tools || die "dpkg --configure failed"
}

# prerm 'remove' calls `systemctl disable` on a fixed list of units, including
# bdsec-arrakis, which this module only defines when patchManagement is on.
# Disabling a unit that does not exist fails, and prerm runs under set -e, so
# the whole removal aborts. Unit state here belongs to the module rather than
# to dpkg, so the disable calls come out entirely.
neuter_prerm_systemctl ()
{
    local p=/var/lib/dpkg/info/bitdefender-security-tools.prerm

    [ -f "$p" ] || { warn "no installed prerm at $p to patch"; return 0; }

    if grep -q '# nixos: unit state is owned by nix' "$p"; then
        log "prerm systemctl block already neutered"
        return 0
    fi

    if ! grep -q '^[[:space:]]*systemctl disable bdsec ' "$p"; then
        warn "prerm does not contain the expected systemctl block; leaving it alone"
        return 0
    fi

    cp -p -- "$p" "$p.orig-unpatched"
    sed -i \
        -e 's%^\(\s*\)systemctl stop bdsec$%\1systemctl stop bdsec || true # nixos: unit state is owned by nix%' \
        -e 's%^\(\s*\)systemctl disable bdsec .*$%\1: # nixos: unit state is owned by nix%' \
        -e 's%^\(\s*\)systemctl disable bdsec-epagng$%\1: # nixos: unit state is owned by nix%' \
        "$p"

    if grep -q '^[[:space:]]*systemctl disable' "$p"; then
        die "failed to neuter the prerm systemctl block; do not remove this package yet"
    fi

    sh -n "$p" || die "patched prerm is not valid POSIX sh; restore $p.orig-unpatched"
    log "neutered the prerm systemctl block (original kept as $p.orig-unpatched)"
}

# Keeps the patched installer as the one the product re-runs for reconfigure,
# repair and uninstall, so those do not hit the bdconfigure failure again.
sync_patched_installer ()
{
    local d found=0
    for d in "$INSTALL_DIR/var/tmp/setup/installer" "$INSTALL_DIR/bin/installer"; do
        [ -f "$d" ] || continue
        found=1
        if cmp -s "$WORK_DIR/installer" "$d"; then
            log "already patched: $d"
            continue
        fi
        cp -p -- "$d" "$d.orig-unpatched"
        cp -f -- "$WORK_DIR/installer" "$d"
        chmod 0700 "$d"
        log "synced patched installer to $d (original kept as $d.orig-unpatched)"
    done
    [ "$found" -eq 1 ] || warn "found no installed copy of the installer under $INSTALL_DIR to patch"
}

# The package would have written these under /etc. dpkg was told to skip them,
# so confirm the module supplies each one instead.
verify_nix_side ()
{
    local u missing=0

    printf '\n  %-22s %-10s %-10s %s\n' unit enabled active substate
    for u in bdsec bdsec-daemon bdsec-epagng bdsec-update \
             bdsec-minidump.timer bdsec-redline.timer; do
        printf '  %-22s %-10s %-10s %s\n' "$u" \
            "$(systemctl is-enabled "$u" 2>&1)" \
            "$(systemctl is-active "$u" 2>&1)" \
            "$(systemctl show "$u" -p SubState --value 2>&1)"
        systemctl cat "$u" >/dev/null 2>&1 || missing=1
    done

    [ "$missing" -eq 0 ] \
        || warn "at least one unit is unknown to systemd; is the module active and the system rebuilt?"

    if [ -e /etc/systemd/system/bdsec.service ]; then
        warn "/etc/systemd/system/bdsec.service exists; dpkg should have skipped it"
    fi
}

report ()
{
    printf '\n'
    log "status"
    dpkg-query -f '  ${Package} ${Version} ${Status}\n' --show bitdefender-security-tools 2>/dev/null \
        || echo "  bitdefender-security-tools: not registered with dpkg"

    verify_nix_side

    printf '\n  running daemons:\n'
    pgrep -a -x 'bdsecd|epagngd|updated|osqueryd|arrakis' 2>/dev/null | sed 's/^/    /' \
        || echo "    NONE -- the product is installed but not running"

    printf '\n'
    echo "  install log:       $INSTALL_DIR/var/log/installer.log"
    echo "  patched installer: $WORK_DIR/installer"
    echo
    echo "  Patch Management stays off. Its Ixp libraries need OpenSSL 1.0/1.1"
    echo "  and libxml2.so.2, and nixpkgs has none of them. If GravityZone policy"
    echo "  turns that feature on, bdsec-arrakis will fail to load."
    echo
    echo "  Confirm the endpoint reports in via the GravityZone console."
}

main ()
{
    parse_args "$@"

    # Re-entry from the staged helper, mid-install. The environment is already
    # inherited from the parent run, so skip preflight and get on with it.
    if [ "$INTERNAL_DPKG" -eq 1 ]; then
        internal_dpkg_install "$INTERNAL_DEB"
        exit 0
    fi

    preflight
    export_ld_env

    printf '\n'
    # Fingerprint the running script. Several rounds of this install have
    # failed in ways that look alike in the log, so make it unambiguous which
    # revision produced a given run.
    log "script:  $SELF_PATH (md5 $(md5sum < "$SELF_PATH" | cut -c1-8))"
    log "source:  $SRC_DIR"
    log "staging: $WORK_DIR"
    log "action:  $ACTION"
    printf '\n'

    init_dpkg_db

    if [ "$RESET" -eq 1 ]; then
        reset_install
        exit 0
    fi

    stage_and_patch

    if [ "$DRY_RUN" -eq 1 ]; then
        log "--dry-run: stopping before running the installer"
        exit 0
    fi

    warn "This installs a Debian package onto NixOS. Files land under $INSTALL_DIR"
    warn "and are not tracked by Nix. The agent enrols this host into GravityZone."
    confirm "proceed?" || { log "aborted"; exit 0; }

    run_installer
    prune_dpkg_etc_list
    neuter_prerm_systemctl
    neuter_postrm_fstab
    sync_patched_installer
    report
}

main "$@"
