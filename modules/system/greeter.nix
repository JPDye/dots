{
  config,
  lib,
  pkgs,
  inputs,
  system,
  ...
}:

let
  cfg = config.dotfiles.system.greeter;

  # Login backdrop: the theme wallpaper, heavily gaussian-blurred at build
  # time (sigma 20 — matches the blur-wallpaper script default; the lighter
  # sigma-4 backdrop in theming/wallpaper.nix is a different surface).
  #
  # The wallpaper path is repeated here rather than read from
  # `dotfiles.theme.wallpaper`: that option lives in the home-manager scope
  # and isn't visible to this NixOS module. Keep in sync with the default in
  # modules/theming/wallpaper.nix.
  wallpaperBlurred =
    pkgs.runCommand "greeter-wallpaper-blur.png"
      {
        nativeBuildInputs = [ pkgs.imagemagick ];
      }
      ''
        magick ${../../wallpapers/istanbul.jpg} -blur 0x20 PNG:$out
      '';

  # ReGreet's centred login box, restyled to read like a niri window: dark
  # fill, 2px red border, square corners, and a hard 8px shadow with no blur.
  # Colours are hardcoded because the palette lives in the home-manager scope
  # and isn't visible to this NixOS module (see modules/theming/theme.nix and
  # the layout.nix border/shadow rules). Keep in sync:
  #   border    = colors.border (#af5f5f), width 2 (border-style.width)
  #   bg/shadow = colors.bg0    (#1c1c1c), shadow opacity 0.92 (shadow-style)
  #
  # ReGreet's UI is a GtkOverlay: the background Picture is child 1, the
  # centred login Frame is child 2 (the first add_overlay), and the clock
  # Frame is child 3. Scoping to nth-child(2) styles the login box only and
  # leaves the clock with its default flush-to-top look.
  loginBoxCss = ''
    overlay > frame.background:nth-child(2) {
      background-color: #1c1c1c;
      border: 2px solid #af5f5f;
      border-radius: 0;
      box-shadow: 0 0 0 8px rgba(28, 28, 28, 0.92);
    }
  '';

  # "Shell (TTY)" session: hand the authenticated user straight to a bare
  # login shell on the VT instead of launching a compositor. greetd has
  # already opened the PAM session; exiting the shell drops back to the
  # greeter. The shell is read from /etc/passwd so it tracks
  # users.users.<name>.shell (currently nushell); if that shell's own config
  # is broken, just run `bash` from the prompt.
  ttyLauncher = pkgs.writeShellScript "regreet-shell-session" ''
    exec "$(${pkgs.getent}/bin/getent passwd "$(${pkgs.coreutils}/bin/id -un)" | ${pkgs.coreutils}/bin/cut -d: -f7)" -l
  '';

  # Wrap that launcher in a wayland-sessions desktop file so ReGreet lists it
  # in the session picker. It must live in wayland-sessions, not xsessions:
  # ReGreet prepends `startx` to xsessions entries, which would break a shell.
  # passthru.providedSessions lets services.displayManager.sessionPackages
  # accept it (and verify the desktop file exists).
  ttySession =
    (pkgs.writeTextDir "share/wayland-sessions/shell.desktop" ''
      [Desktop Entry]
      Name=Shell (TTY)
      Comment=Log in to a bare console shell (no compositor)
      Exec=${ttyLauncher}
      Type=Application
    '').overrideAttrs
      (_: {
        passthru.providedSessions = [ "shell" ];
      });

  # ReGreet has no declarative "default session" — it only remembers each
  # user's last pick in /var/lib/regreet/state.toml. Seed that file so a fresh
  # system pre-selects niri for jd. The session key is the desktop Name=
  # ("Niri"). tmpfiles writes it only when missing (type C below), so once
  # ReGreet records real login history it is never clobbered.
  stateSeed = pkgs.writeText "regreet-state.toml" ''
    last_user = "jd"

    [user_to_last_sess]
    jd = "Niri"
  '';
in
{
  options.dotfiles.system.greeter.enable =
    lib.mkEnableOption "graphical login greeter (ReGreet + greetd)"
    // {
      default = true;
    };

  config = lib.mkIf cfg.enable {
    # Graphical login. ReGreet (GTK) runs inside cage and launches niri on
    # success; hyprlock stays the in-session locker (modules/desktop/lock.nix).
    # Enabling regreet pulls in services.greetd, the cage session command, and
    # the greetd PAM stack automatically — nothing else to wire for auth.
    programs.regreet = {
      enable = true;

      # IoskeleyMono everywhere, including the login box. Installed system-wide
      # in modules/system/fonts.nix, but pin the package here too so cage's
      # fontconfig is guaranteed to resolve it.
      font = {
        name = "IoskeleyMono Nerd Font";
        package = inputs.myFonts.packages.${system}.ioskeley;
        size = 14;
      };

      settings = {
        # Blurred wallpaper filling the screen, password box centred on top.
        background = {
          path = "${wallpaperBlurred}";
          fit = "Cover";
        };

        # Dark Adwaita box so it reads against the dark backdrop.
        GTK.application_prefer_dark_theme = true;
      };

      # niri-window styling for the login box (see loginBoxCss above). Written
      # by the module to /etc/greetd/regreet.css.
      extraCss = loginBoxCss;
    };

    # ReGreet populates its session picker from wayland-sessions desktop files
    # and doesn't discover them on its own. Register niri so it shows up, and
    # put niri on the system PATH so the desktop file's `Exec=niri-session`
    # resolves when greetd launches the session (niri is otherwise only in the
    # home-manager profile). Same pkgs.niri the user's HM config runs, so no
    # version skew.
    #
    # ttySession adds the "Shell (TTY)" entry alongside niri.
    services.displayManager.sessionPackages = [
      pkgs.niri
      ttySession
    ];
    environment.systemPackages = [ pkgs.niri ];

    # Pre-select niri on a fresh system (see stateSeed above). Owned by the
    # greetd `greeter` user so ReGreet can rewrite it on subsequent logins; type
    # C copies only when the target is missing, so existing history is kept.
    systemd.tmpfiles.settings."10-regreet" = {
      "/var/lib/regreet".d = {
        user = "greeter";
        group = "greeter";
        mode = "0755";
      };
      "/var/lib/regreet/state.toml".C = {
        user = "greeter";
        group = "greeter";
        mode = "0644";
        argument = "${stateSeed}";
      };
    };
  };
}
