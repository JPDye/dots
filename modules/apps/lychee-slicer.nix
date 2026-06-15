{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.dotfiles.apps.lychee-slicer;

  # Electron exports GDK_BACKEND=x11 into its own environment, and every
  # child of shell.openExternal inherits it. When no browser runs yet, the
  # cold-started browser hangs inside the AppImage bwrap sandbox and no
  # window appears. In the app this looks like dead "Free trial" and login
  # buttons. The shim replaces xdg-open inside the sandbox and hands the
  # URL to the host through the XDG desktop portal, so the host opens it
  # with a clean environment. If no portal answers, it strips the poison
  # and runs the real xdg-open.
  xdgOpenShim = lib.hiPrio (
    pkgs.writeShellScriptBin "xdg-open" ''
      if ${pkgs.glib}/bin/gdbus call --session \
        --dest org.freedesktop.portal.Desktop \
        --object-path /org/freedesktop/portal/desktop \
        --method org.freedesktop.portal.OpenURI.OpenURI \
        "" "$1" "{}" >/dev/null 2>&1; then
        exit 0
      fi
      exec env -u GDK_BACKEND -u LD_LIBRARY_PATH -u GTK_PATH \
        ${pkgs.xdg-utils}/bin/xdg-open "$@"
    ''
  );

  # Vendored from nixpkgs pkgs/by-name/ly/lycheeslicer, because nixpkgs
  # lags upstream and cannot inject the xdg-open shim.
  version = "7.6.6";

  desktopItem = pkgs.makeDesktopItem {
    name = "Lychee Slicer";
    genericName = "Resin Slicer";
    comment = "All-in-one 3D slicer for Resin and Filament";
    desktopName = "LycheeSlicer";
    noDisplay = false;
    exec = "lycheeslicer";
    terminal = false;
    mimeTypes = [ "model/stl" ];
    categories = [ "Graphics" ];
    keywords = [
      "STL"
      "Slicer"
      "Printing"
    ];
  };

  lycheeslicer = pkgs.appimageTools.wrapType2 {
    pname = "lycheeslicer";
    inherit version;

    src = pkgs.fetchurl {
      url = "https://mango-lychee.nyc3.cdn.digitaloceanspaces.com/LycheeSlicer-${version}.AppImage";
      hash = "sha256-eDMhA8fCD++BYK58t4/2XUlzrhcwtbAuOzRsThQAiVs=";
    };

    extraInstallCommands = ''
      install -Dm444 -t $out/share/applications ${desktopItem}/share/applications/*
    '';

    extraPkgs = _: [
      xdgOpenShim
      pkgs.libxshmfence
      pkgs.wayland
      pkgs.wayland-protocols
    ];
  };
in
{
  options.dotfiles.apps.lychee-slicer.enable =
    lib.mkEnableOption "Lychee Slicer (resin MSLA slicer)"
    // {
      default = true;
    };

  config = lib.mkIf cfg.enable {
    home.packages = [ (config.dotfiles.wrapGL lycheeslicer) ];

    # Browser login returns to the app as a lycheeslicer:// deep link.
    # The app cannot register that scheme itself: Electron's
    # setAsDefaultProtocolClient cannot write from the read-only FHS wrapper,
    # and the stock desktop entry declares no scheme and no %u. This entry
    # receives the URL. The spawned second instance forwards it to the running
    # one through Electron's single-instance lock.
    #
    # The default-handler line in ~/.config/mimeapps.list stays imperative,
    # because apps must keep write access to that file (claude-cli registered
    # its scheme the same way). One-time setup on a new host:
    #   xdg-mime default lycheeslicer-url.desktop x-scheme-handler/lycheeslicer
    xdg.desktopEntries.lycheeslicer-url = {
      name = "Lychee Slicer (URL handler)";
      exec = "lycheeslicer %u";
      mimeType = [ "x-scheme-handler/lycheeslicer" ];
      noDisplay = true;
    };
  };
}
