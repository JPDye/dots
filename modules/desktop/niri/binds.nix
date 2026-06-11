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

  # hyprpicker fills the lens border with the hovered pixel's color, so it
  # blends into the screen around it; the patch strokes a white+black outline
  # around the lens to keep its edge visible on any background.
  hyprpicker-outlined = pkgs.hyprpicker.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [ ./hyprpicker-lens-border.patch ];
  });

  color-picker = pkgs.writeShellApplication {
    name = "color-picker";
    runtimeInputs = [
      (config.dotfiles.wrapGL hyprpicker-outlined)
      pkgs.libnotify
    ];
    text = ''
      hex=$(hyprpicker -a -f hex)
      notify-send "Color picked" "$hex copied to clipboard"
    '';
  };

  # Prompt for a project directory (zoxide suggestions, but any typed path
  # works), then open a 33%/66% pair there: bacon on the left, a terminal on
  # the right. Widths come from the .thin/.wide window rules in
  # window-rules.nix. Spawning goes through
  # `niri msg` so the windows are parented to the compositor, and ghostty is
  # referenced by absolute wrapGL'd path because niri spawns with its own
  # PATH, not the script's.
  work-layout =
    let
      ghostty = lib.getExe (config.dotfiles.wrapGL pkgs.ghostty);
      zellij = lib.getExe config.programs.zellij.package;
      # Runs bacon inside zellij rather than as the terminal's direct child,
      # so the pane survives as a normal zellij session (new tabs, scrollback,
      # rerun on exit). Mirrors the `compact` default_layout from zellij.nix,
      # which a --layout file would otherwise override.
      bacon-layout = pkgs.writeText "bacon-layout.kdl" ''
        layout {
            default_tab_template {
                pane size=1 borderless=true {
                    plugin location="zellij:compact-bar"
                }
                children
            }
            tab {
                pane command="direnv" {
                    args "exec" "." "bacon"
                }
            }
        }
      '';
    in
    pkgs.writeShellApplication {
      name = "work-layout";
      runtimeInputs = with pkgs; [
        fuzzel
        zoxide
        jq
        libnotify
      ];
      text = ''
        input=$(zoxide query --list | fuzzel --dmenu --prompt="dir: ") || exit 0
        [ -z "$input" ] && exit 0

        # Resolve like the zoxide-powered `cd`: an existing path is used
        # as-is, anything else is a zoxide query ("ancelotti" -> the
        # highest-ranked match). `zoxide add` bumps the rank like a real cd.
        input="''${input/#\~/$HOME}"
        if [ -d "$input" ]; then
          dir=$input
        else
          read -ra words <<< "$input"
          if ! dir=$(zoxide query -- "''${words[@]}"); then
            notify-send "work-layout" "no zoxide match for: $input"
            exit 1
          fi
        fi
        zoxide add "$dir"

        thin_count() {
          niri msg --json windows | jq '[.[] | select(.app_id == "com.mitchellh.ghostty.thin")] | length'
        }

        # bacon comes from each project's dev shell (templates/rust), not the
        # user profile, so the layout launches it through `direnv exec` to
        # load the .envrc environment first.
        before=$(thin_count)
        niri msg action spawn -- ${ghostty} --class=com.mitchellh.ghostty.thin --working-directory="$dir" \
          -e ${zellij} --layout ${bacon-layout}

        # Wait until the thin window has opened (it takes focus) so the wide
        # one spawns into the column to its right.
        for _ in $(seq 1 40); do
          [ "$(thin_count)" -gt "$before" ] && break
          sleep 0.05
        done

        niri msg action spawn -- ${ghostty} --class=com.mitchellh.ghostty.wide --working-directory="$dir"
      '';
    };

  # Region screenshot piped into satty for annotation (arrows/text/redaction);
  # the result is copied to the clipboard and saved next to niri's own
  # screenshots. satty is GTK4 (GPU-rendered), hence wrapGL.
  annotate-screenshot = pkgs.writeShellApplication {
    name = "annotate-screenshot";
    runtimeInputs = with pkgs; [
      grim
      slurp
      wl-clipboard
      (config.dotfiles.wrapGL satty)
    ];
    text = ''
      geometry=$(slurp) || exit 0
      mkdir -p "$HOME/Pictures/Screenshots"
      grim -g "$geometry" - | satty --filename - \
        --output-filename "$HOME/Pictures/Screenshots/Screenshot from $(date '+%Y-%m-%d %H-%M-%S') (annotated).png" \
        --copy-command wl-copy --early-exit
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
      "Mod+Shift+Return".action.spawn = lib.getExe work-layout;
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
      # Ctrl+Q is intentionally left unbound here (and unbound in zellij) so it
      # reaches the focused app — Helix uses it to silence/restore typos-lsp.

      "Mod+Shift+O".action.toggle-window-rule-opacity = [ ];
      "Mod+O".action.toggle-overview = [ ];

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
      "Print".action.spawn = lib.getExe annotate-screenshot;

      "Mod+Shift+E".action.quit = [ ];
      "Ctrl+Alt+Delete".action.quit = [ ];

      "Mod+Shift+P".action.power-off-monitors = [ ];
    };
  };
}
