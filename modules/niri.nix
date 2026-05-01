_:
{
  programs.niri.settings = {
    spawn-at-startup = [
      { command = [ "xwayland-satellite" ]; }
      { command = [ "mako" ]; }
      { command = [ "swww" "img" "/home/jd/.config/nix/wallpapers/halls.png" ]; }
      { command = [ "swaybg" "-m" "fill" "-i" "/home/jd/.config/nix/wallpapers/halls-blur.png" ]; }
    ];

    hotkey-overlay.skip-at-startup = true;

    environment.DISPLAY = ":0";

    overview = {
      backdrop-color = "#1c1c1c";
      zoom = 0.6;
      workspace-shadow = {
        softness = 0;
        spread = 2;
        offset = { x = 0; y = 0; };
        color = "#af5f5f";
      };
    };

    gestures.hot-corners.enable = false;

    input = {
      keyboard.xkb.layout = "gb";
      focus-follows-mouse = {
        enable = true;
        max-scroll-amount = "0%";
      };
    };

    outputs = {
      "eDP-1" = {
        scale = 1.0;
        focus-at-startup = true;
      };
      "HDMI-A-1" = {
        scale = 1.0;
        focus-at-startup = true;
      };
    };

    layout = {
      background-color = "#1c1c1c";
      gaps = 24;
      center-focused-column = "never";

      preset-column-widths = [
        { proportion = 0.33333; }
        { proportion = 0.5; }
        { proportion = 0.66667; }
      ];

      default-column-width = { proportion = 0.5; };

      focus-ring.enable = false;

      border = {
        enable = true;
        width = 2;
        active.color = "#af5f5f";
        inactive.color = "#523636";
      };

      shadow = {
        enable = true;
        spread = 4;
        softness = 0;
        offset = { x = 0; y = 0; };
        color = "#101010";
        inactive-color = "#1c1c1c";
      };

      struts = {
        top = 0;
        bottom = 0;
        left = 0;
        right = 0;
      };
    };

    prefer-no-csd = true;

    screenshot-path = "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";

    window-rules = [
      {
        geometry-corner-radius = {
          top-left = 1.0;
          top-right = 1.0;
          bottom-left = 1.0;
          bottom-right = 1.0;
        };
        clip-to-geometry = true;
        draw-border-with-background = true;
      }
      {
        matches = [{ title = "Firefox"; }];
        opacity = 1.0;
        default-column-width = { proportion = 1.0; };
      }
      {
        matches = [{ app-id = "Spotify"; }];
        opacity = 1.0;
        default-column-width = { proportion = 1.0; };
      }
      {
        matches = [{ app-id = "Slack"; }];
        opacity = 1.0;
        default-column-width = { proportion = 1.0; };
      }
      {
        matches = [
          { title = "^(file_progress)$"; }
          { title = "^(confirm)$"; }
          { title = "^(dialog)$"; }
          { title = "^(download)$"; }
          { title = "^(notification )$"; }
          { title = "^(error)$"; }
          { title = "^(splash)$"; }
          { title = "^(nwg-look)$"; }
          { title = "^(confirmreset)$"; }
          { title = "^(Delete profile)$"; }
          { title = "^File Operation Progress$"; }
          { title = "^Confirm to replace files$"; }
          { title = "^KDE Connect URL handler$"; }
          { title = "^(Open File)(.*)$"; }
          { title = "^(Select a File)(.*)$"; }
          { title = "^(Choose wallpaper)(.*)$"; }
          { title = "^(Open Folder)(.*)$"; }
          { title = "^(Save As)(.*)$"; }
          { title = "^(Library)(.*)$"; }
          { title = "^(File Upload)(.*)$"; }
          { title = "^(hyprland-share-picker)$"; }
          { title = "^(.*)-Google$"; }
          { title = "^(.*)System Update$"; }
          { title = "(.*) - Google (.*) - (.*)"; }
          { app-id = "^xdm-app$"; }
          { app-id = "^org.qbittorrent.qBittorrent$"; }
          { app-id = "^net.davidotek.pupgui2$"; }
        ];
        open-floating = true;
        max-width = 800;
      }
      {
        matches = [
          { app-id = ".*blueman.*"; }
          { app-id = "^org.pulseaudio.pavucontrol$"; }
        ];
        open-floating = true;
        min-width = 800;
        max-width = 800;
        min-height = 500;
        max-height = 500;
      }
    ];

    layer-rules = [
      {
        matches = [{ namespace = "^wallpaper$"; }];
        place-within-backdrop = true;
      }
      {
        matches = [{ namespace = "^eww$"; }];
        place-within-backdrop = true;
      }
    ];

    binds = {
      "Mod+Space".action.spawn = "firefox";
      "Mod+Return".action.spawn = [ "alacritty" "-e" "zellij" ];
      "Mod+R".action.spawn = "fuzzel";

      "Mod+Q".action.close-window = [ ];
      "Ctrl+Q".action.spawn = "true";

      "Mod+Shift+O".action.toggle-window-rule-opacity = [ ];
      "Mod+O".action.toggle-overview = [ ];

      "Mod+Shift+C".action.spawn = [ "killall" "-SIGUSR1" "waybar" ];

      "Mod+H".action.focus-column-left = [ ];
      "Mod+J".action.focus-window-or-workspace-down = [ ];
      "Mod+K".action.focus-window-or-workspace-up = [ ];
      "Mod+L".action.focus-column-right = [ ];

      "Mod+Shift+H".action.move-column-left = [ ];
      "Mod+Shift+J".action.move-window-down-or-to-workspace-down = [ ];
      "Mod+Shift+K".action.move-window-up-or-to-workspace-up = [ ];
      "Mod+Shift+L".action.move-column-right = [ ];

      "Mod+Ctrl+H".action.focus-monitor-left = [ ];
      "Mod+Ctrl+J".action.focus-monitor-down = [ ];
      "Mod+Ctrl+K".action.focus-monitor-up = [ ];
      "Mod+Ctrl+L".action.focus-monitor-right = [ ];

      "Mod+Shift+Ctrl+H".action.move-window-to-monitor-left = [ ];
      "Mod+Shift+Ctrl+J".action.move-window-to-monitor-down = [ ];
      "Mod+Shift+Ctrl+K".action.move-window-to-monitor-up = [ ];
      "Mod+Shift+Ctrl+L".action.move-window-to-monitor-right = [ ];

      "Mod+Shift+WheelScrollDown".action.focus-column-right = [ ];
      "Mod+Shift+WheelScrollUp".action.focus-column-left = [ ];
      "Mod+Ctrl+Shift+WheelScrollDown".action.move-column-right = [ ];
      "Mod+Ctrl+Shift+WheelScrollUp".action.move-column-left = [ ];

      "Mod+1".action.focus-workspace = 1;
      "Mod+2".action.focus-workspace = 2;
      "Mod+3".action.focus-workspace = 3;
      "Mod+4".action.focus-workspace = 4;
      "Mod+Ctrl+1".action.move-window-to-workspace = 1;
      "Mod+Ctrl+2".action.move-window-to-workspace = 2;
      "Mod+Ctrl+3".action.move-window-to-workspace = 3;
      "Mod+Ctrl+4".action.move-window-to-workspace = 4;

      "Mod+Comma".action.consume-window-into-column = [ ];
      "Mod+Period".action.expel-window-from-column = [ ];

      "Mod+F".action.maximize-column = [ ];
      "Mod+Shift+F".action.fullscreen-window = [ ];
      "Mod+Ctrl+F".action.reset-window-height = [ ];

      "Mod+G".action.switch-preset-column-width = [ ];
      "Mod+Shift+G".action.switch-preset-window-height = [ ];

      "Mod+C".action.center-column = [ ];

      "Mod+Minus".action.set-column-width = "-10%";
      "Mod+Equal".action.set-column-width = "+10%";
      "Mod+Shift+Minus".action.set-window-height = "-10%";
      "Mod+Shift+Equal".action.set-window-height = "+10%";

      "Mod+P".action.screenshot = [ ];
      "Ctrl+Print".action.screenshot-screen = [ ];
      "Alt+Print".action.screenshot-window = [ ];

      "Mod+Shift+E".action.quit = [ ];
      "Ctrl+Alt+Delete".action.quit = [ ];

      "Mod+Shift+P".action.power-off-monitors = [ ];
    };

    animations.slowdown = 1.0;
  };
}
