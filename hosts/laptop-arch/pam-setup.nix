# Root-level PAM setup for the Arch host, exposed as `nix run .#arch-pam-setup`
# (wired in flake.nix). Run it once per machine, and again after a `pam`
# package rebuild only if the check at the end of the script fails.
#
# It covers two jobs: the two root-owned files hyprlock needs to
# authenticate, and gnome-keyring PAM integration so a login keyring exists
# for apps that store secrets through the Secret Service (Termius keeps its
# database key there and hangs on a blank splash without one).
#
# Why this is not a home-manager module: `laptop-arch` runs standalone
# home-manager as the user jd, so it can write ~/ but never /etc. The files
# and PAM lines below are root-owned. On the NixOS hosts
# `security.pam.services.hyprlock` and `gnome.gnome-keyring.enable` in
# modules/system/desktop.nix cover the same ground declaratively.
#
# The file contents live here (in the store, one source of truth) and the
# script only copies them into place. See modules/desktop/lock.nix for the
# failure this fixes.
{
  coreutils,
  writeText,
  writeShellApplication,
}:

let
  # hyprlock calls pam_start("hyprlock"), so libpam reads /etc/pam.d/hyprlock.
  # When that file is missing libpam falls back to /etc/pam.d/other, which is
  # a pam_deny stack on Arch, so every password is rejected.
  #
  # A screen locker only needs the auth stack. Arch's system-auth is the same
  # stack that `login` ends up including, minus the console-login extras
  # (securetty, nologin, motd) that mean nothing here.
  pamService = writeText "pam-hyprlock" ''
    #%PAM-1.0
    auth include system-auth
  '';

  # nixpkgs patches pam_unix.so to exec the setuid password helper from the
  # NixOS path /run/wrappers/bin/unix_chkpwd. The nix-built hyprlock links nix
  # libpam, so it uses that path on Arch too, where the helper is installed at
  # /usr/bin/unix_chkpwd instead. The symlink below reconciles the two.
  #
  # A copy would not work: the store cannot hold a setuid binary, and the
  # setuid bit comes from the target inode, so a symlink to Arch's helper is
  # both sufficient and the only option. /run is a tmpfs, which is why this is
  # a tmpfiles rule and not a one-time `ln`: systemd-tmpfiles-setup.service
  # recreates the link on every boot, well before the graphical session.
  tmpfilesRule = writeText "nix-pam-wrappers.conf" ''
    d /run/wrappers 0755 root root -
    d /run/wrappers/bin 0755 root root -
    L+ /run/wrappers/bin/unix_chkpwd - - - - /usr/bin/unix_chkpwd
  '';
in
writeShellApplication {
  name = "arch-pam-setup";
  # coreutils supplies install and readlink. systemd-tmpfiles, faillock and
  # sudo are deliberately absent: this script configures the Arch system, so it
  # uses Arch's own copies of those. writeShellApplication only prepends to
  # PATH, so they stay reachable from /usr/bin.
  runtimeInputs = [ coreutils ];
  runtimeEnv = {
    PAM_SERVICE_FILE = "${pamService}";
    TMPFILES_RULE = "${tmpfilesRule}";
  };
  text = builtins.readFile ./pam-setup.sh;
}
