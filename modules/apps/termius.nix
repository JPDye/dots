{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.dotfiles.apps.termius;
in
{
  options.dotfiles.apps.termius.enable = lib.mkEnableOption "termius ssh client" // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
    # Termius reads its database key through libsecret before it draws a window,
    # so anything that stalls the Secret Service leaves it on the blue splash
    # with no error. Two host-side pieces have to work. A login keyring must
    # exist, which on Arch takes one `nix run .#arch-pam-setup`
    # (hosts/laptop-arch/pam-setup.nix). A gcr prompter must also be D-Bus
    # activatable, or no unlock dialog can ever appear and the read never
    # returns (hosts/laptop-arch/home.nix).
    #
    # The key lands in the keyring that the `default` alias points at, which is
    # runtime state under ~/.local/share/keyrings. Point that alias at the
    # PAM-unlocked login keyring to avoid an unlock dialog once per session.
    home.packages = [ pkgs.termius ];

    # The packaged desktop entry ships no MimeType and no %U, so nothing claims
    # `termius://`. Google SSO finishes by redirecting to
    # `termius://app/continue-sso?...`. With no handler the browser opens that
    # link as a web page and the login never completes.
    #
    # This entry reuses the packaged desktop ID on purpose. home-manager wraps
    # each xdg.desktopEntries item in `lib.hiPrio` and adds it to
    # `home.packages`, so this file wins the buildEnv collision and walker still
    # lists one launcher. Landing in `home-manager-path` is the point: that
    # buildEnv generates `share/applications/mimeinfo.cache`, which is where GIO
    # (and so firefox) looks up the owner of a scheme. No `mimeapps.list` entry
    # is needed, because no other app claims this scheme.
    xdg.desktopEntries.termius-app = {
      name = "Termius";
      genericName = "Cross-platform SSH client";
      comment = "The SSH client that works on Desktop and Mobile";
      icon = "termius-app";
      exec = "${lib.getExe' pkgs.termius "termius-app"} %U";
      categories = [ "Network" ];
      mimeType = [ "x-scheme-handler/termius" ];
    };
  };
}
