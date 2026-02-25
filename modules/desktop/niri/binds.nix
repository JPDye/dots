{
  config,
  lib,
  pkgs,
  ...
}:

let
  clipboard-picker = pkgs.writeShellApplication {
    name = "clipboard-picker";
    runtimeInputs = with pkgs; [
      cliphist
      fuzzel
      wl-clipboard
      libnotify
    ];
    text = ''
      sel=$(cliphist list | fuzzel --dmenu) || exit 0
      [ -z "$sel" ] && exit 0
      printf '%s' "$sel" | cliphist decode | wl-copy
      notify-send "Copied to clipboard"
    '';
  };

  color-picker = pkgs.writeShellApplication {
    name = "color-picker";
    runtimeInputs = [
      (config.dotfiles.wrapGL pkgs.hyprpicker)
      pkgs.libnotify
    ];
    text = ''
      hex=$(hyprpicker -a -f hex)
      notify-send "Color picked" "$hex copied to clipboard"
    '';
  };

  calc = pkgs.writeShellApplication {
    name = "calc";
    runtimeInputs = with pkgs; [
      fuzzel
      libqalculate
      wl-clipboard
      libnotify
    ];
    text = ''
      query=$(fuzzel --dmenu --prompt="= " < /dev/null) || exit 0
      [ -z "$query" ] && exit 0
      result=$(qalc -t "$query")
      printf '%s' "$result" | wl-copy
      notify-send "$query" "$result"
      printf '%s\n' "$result" | fuzzel --dmenu --prompt="$query = " || true
    '';
  };
in
{
  config = lib.mkIf config.dotfiles.desktop.niri.enable {
    programs.niri.settings.binds = {
      "Mod+Space".action.spawn = "firefox";
      "Mod+Return".action.spawn = "ghostty";
      "Mod+R".action.spawn = "fuzzel";
      "Mod+V".action.spawn = lib.getExe clipboard-picker;
      "Mod+I".action.spawn = lib.getExe color-picker;

      "XF86AudioRaiseVolume".action.spawn = [
        "swayosd-client"
        "--output-volume"
        "raise"
      ];
      "XF86AudioLowerVolume".action.spawn = [
        "swayosd-client"
        "--output-volume"
        "lower"
      ];
      "XF86AudioMute".action.spawn = [
        "swayosd-client"
        "--output-volume"
        "mute-toggle"
      ];
      "XF86AudioMicMute".action.spawn = [
        "swayosd-client"
        "--input-volume"
        "mute-toggle"
      ];
      "XF86MonBrightnessUp".action.spawn = [
        "swayosd-client"
        "--brightness"
        "raise"
      ];
      "XF86MonBrightnessDown".action.spawn = [
        "swayosd-client"
        "--brightness"
        "lower"
      ];

      "Mod+Q".action.close-window = [ ];
      "Ctrl+Q".action.spawn = "true";

      "Mod+Shift+O".action.toggle-window-rule-opacity = [ ];
      "Mod+O".action.toggle-overview = [ ];

      "Mod+Shift+C".action.spawn = [
        "killall"
        "-SIGUSR1"
        "waybar"
      ];

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

      "Mod+Shift+Minus".action.set-window-height = "-10%";
      "Mod+Shift+Equal".action.set-window-height = "+10%";

      "Mod+Equal".action.spawn = lib.getExe calc;

      "Mod+P".action.screenshot = [ ];
      "Ctrl+Print".action.screenshot-screen = [ ];
      "Alt+Print".action.screenshot-window = [ ];

      "Mod+Shift+E".action.quit = [ ];
      "Ctrl+Alt+Delete".action.quit = [ ];

      "Mod+Shift+P".action.power-off-monitors = [ ];
    };
  };
}
