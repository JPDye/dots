{
  config,
  lib,
  colors,
  monoFont,
  pkgs,
  ...
}:

let
  # The launcher uses an 11px font and no icons (fuzzel.nix); the text
  # clipboard picker gets the same merged settings re-serialised with a
  # smaller font (clipboard entries are dense text, so more fits per row) and
  # icons turned back on — so the current-clipboard image can be pinned at the
  # top with a thumbnail icon (the rest of the list is text; those rows just
  # carry no icon). Bulk images still go to nsxiv (Mod+Shift+V).
  fuzzel-clip-config = pkgs.writeText "fuzzel-clip.ini" (
    lib.generators.toINI { } (
      lib.recursiveUpdate config.programs.fuzzel.settings {
        main = {
          font = "${monoFont}:size=8";
          icons-enabled = true;
        };
      }
    )
  );

  # nsxiv keybindings are compile-time (config.h), so the picker UX is patched
  # in at build time, mirroring the hyprpicker-outlined override below: Enter
  # drills into an image / copies it, q backs out / closes. See the patch for
  # the per-mode binding rationale.
  nsxiv-picker = pkgs.nsxiv.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [ ./nsxiv-picker-keys.patch ];
  });

  # nsxiv reads its colors only from X resources under the class "Nsxiv",
  # and specifically via XResourceManagerString — i.e. the X server's
  # RESOURCE_MANAGER property, the thing `xrdb` populates. It ignores
  # XENVIRONMENT and ~/.Xdefaults entirely. xwayland-satellite starts with an
  # empty RESOURCE_MANAGER and there's no X-session startup to load anything,
  # so the picker `xrdb -merge`s this file just before launching nsxiv (see
  # below). Colors come from the stylix palette so the grid matches the rest
  # of the desktop.
  nsxiv-theme = pkgs.writeText "nsxiv-theme.xresources" ''
    Nsxiv.window.background: #${colors.bg0}
    Nsxiv.window.foreground: #${colors.fg1}
    Nsxiv.bar.background: #${colors.bg1}
    Nsxiv.bar.foreground: #${colors.fg1}
    Nsxiv.bar.font: ${monoFont}:size=10
    Nsxiv.mark.foreground: #${colors.yellow}
  '';

  # Two-mode clipboard picker over cliphist:
  #   text   (Mod+V)       — fuzzel list of text entries (labels, delete, prune)
  #   images (Mod+Shift+V) — nsxiv thumbnail grid of the image entries
  # The "[[ binary data … ]]" line cliphist prints for images is matched by
  # this regex; group 1 is the id every action keys off.
  clipboard-picker = pkgs.writeShellApplication {
    name = "clipboard-picker";
    runtimeInputs = with pkgs; [
      cliphist
      fuzzel
      nsxiv-picker
      wl-clipboard
      libnotify
      xorg.xrdb
      imagemagick
    ];
    text = ''
      mode=''${1:-text}
      labels_file=''${XDG_DATA_HOME:-$HOME/.local/share}/cliphist-labels
      re=$'^([0-9]+)\t\\[\\[ binary data .* (png|jpe?g|bmp|webp|gif) [0-9]+x[0-9]+ \\]\\]$'

      list=$(cliphist list)
      if [ -z "$list" ]; then
        notify-send "Clipboard" "empty"
        exit 0
      fi

      # Image mode: decode each image entry into a persistent cache (named by
      # id so nsxiv's own thumbnail cache stays warm between runs), show them
      # as a grid, and copy whichever the grid returns. nsxiv prints the
      # marked file(s) on quit, or — pressing Q — the focused one; we take
      # the first line and map its filename back to the cliphist id.
      if [ "$mode" = images ]; then
        imgdir=''${XDG_CACHE_HOME:-$HOME/.cache}/cliphist-images
        mkdir -p "$imgdir"
        files=()
        while IFS= read -r line; do
          [[ $line =~ $re ]] || continue
          f=$imgdir/''${BASH_REMATCH[1]}.''${BASH_REMATCH[2]}
          [ -s "$f" ] || printf '%s\t' "''${BASH_REMATCH[1]}" | cliphist decode > "$f"
          files+=("$f")
        done <<< "$list"
        # Drop cached images whose entries have left the history.
        for f in "$imgdir"/*; do
          [ -e "$f" ] || continue
          bid=$(basename "$f"); bid=''${bid%.*}
          grep -q "^$bid"$'\t' <<< "$list" || rm -f "$f"
        done
        if [ ''${#files[@]} -eq 0 ]; then
          notify-send "Clipboard" "no images in history"
          exit 0
        fi
        # -nocpp: skip the C preprocessor (no cpp in the closure, and the
        # '#rrggbb' values must not be read as directives). || true so a
        # missing DISPLAY never aborts the picker.
        xrdb -nocpp -merge ${nsxiv-theme} 2>/dev/null || true
        sel=$(nsxiv -t -o -N nsxiv-clipboard -g 1200x800 "''${files[@]}" 2>/dev/null) || exit 0
        [ -z "$sel" ] && exit 0
        id=$(basename "''${sel%%$'\n'*}"); id=''${id%.*}
        printf '%s\t' "$id" | cliphist decode | wl-copy
        notify-send "Copied image to clipboard"
        exit 0
      fi

      # Text mode. Labels ("<id>\t<label>", attached with Alt+1) render as a
      # searchable [label] prefix.
      declare -A label=()
      if [ -f "$labels_file" ]; then
        while IFS=$'\t' read -r lid ltext; do
          [ -n "$lid" ] && label[$lid]=$ltext
        done < "$labels_file"
      fi

      # Pin the current clipboard entry at the top of the list when it's an
      # image: fuzzel only loads .png/.svg paths as icons, so decode a small
      # PNG thumbnail (imagemagick) and prepend a row carrying fuzzel's rofi
      # icon directive (NUL + 0x1F). Cached by id; bulk/older images stay in
      # the nsxiv grid (Mod+Shift+V).
      pin_id=""
      thumbdir=''${XDG_CACHE_HOME:-$HOME/.cache}/cliphist-thumbs
      if [[ ''${list%%$'\n'*} =~ $re ]]; then
        pin_id=''${BASH_REMATCH[1]}
        pin_thumb=$thumbdir/$pin_id.png
        mkdir -p "$thumbdir"
        [ -s "$pin_thumb" ] || printf '%s\t' "$pin_id" | cliphist decode \
          | magick - -thumbnail 128x128 png:"$pin_thumb" 2>/dev/null || true
        [ -s "$pin_thumb" ] || pin_id=""
        # Drop thumbnails whose entries have left the history.
        for t in "$thumbdir"/*.png; do
          [ -e "$t" ] || continue
          grep -q "^$(basename "$t" .png)"$'\t' <<< "$list" || rm -f "$t"
        done
      fi

      # cliphist truncates previews at 100 chars by default; widen it so the
      # small-font rows can actually show more text. Image entries are skipped
      # here (the current one is pinned above; the rest live in the nsxiv
      # grid). --with-nth 2 hides the id column from display while keeping it
      # in fuzzel's returned line.
      sel=$(
        {
          if [ -n "$pin_id" ]; then
            printf '%s\tcurrent clipboard image\0icon\x1f%s\n' "$pin_id" "$pin_thumb"
          fi
          cliphist -preview-width 200 list \
            | while IFS= read -r line; do
                [[ $line =~ $re ]] && continue
                id=''${line%%$'\t'*}
                rest=''${line#*$'\t'}
                [ -n "''${label[$id]:-}" ] && rest="[''${label[$id]}] $rest"
                printf '%s\t%s\n' "$id" "$rest"
              done
        } \
          | fuzzel --dmenu --config ${fuzzel-clip-config} \
              --with-nth 2 --width 90 --lines 15 \
              --placeholder "enter copy · alt+1 label · alt+2 delete · alt+3 purge unlabelled"
      ) && rc=0 || rc=$?
      [ -z "$sel" ] && exit 0
      id=''${sel%%$'\t'*}

      case $rc in
        0)
          printf '%s' "$sel" | cliphist decode | wl-copy
          notify-send "Copied to clipboard"
          ;;
        10)
          # Alt+1: (re)label the highlighted entry. Empty prompt clears the
          # label; Escape leaves it unchanged. Reopen the picker either way.
          if new=$(fuzzel --dmenu --prompt "label: " < /dev/null); then
            tmp=$(mktemp)
            [ -f "$labels_file" ] && grep -v "^$id"$'\t' "$labels_file" > "$tmp" || true
            [ -n "$new" ] && printf '%s\t%s\n' "$id" "$new" >> "$tmp"
            mv "$tmp" "$labels_file"
          fi
          exec "$0" "$mode"
          ;;
        11)
          # Alt+2: delete just this entry (cliphist matches by leading id).
          printf '%s\t' "$id" | cliphist delete
          notify-send "Deleted from history"
          exec "$0" "$mode"
          ;;
        12)
          # Alt+3: prune everything that isn't labelled (text and images).
          if [ "$(printf 'no\nyes' | fuzzel --dmenu --prompt "purge all unlabelled? ")" = yes ]; then
            while IFS= read -r l; do
              lid=''${l%%$'\t'*}
              [ -n "''${label[$lid]:-}" ] || printf '%s\t' "$lid" | cliphist delete
            done <<< "$list"
            notify-send "Clipboard" "pruned unlabelled entries"
          fi
          exec "$0" "$mode"
          ;;
        *) exit 0 ;;
      esac

      # Drop labels whose entries have left the history.
      if [ -s "$labels_file" ]; then
        tmp=$(mktemp)
        while IFS= read -r lline; do
          grep -q "^''${lline%%$'\t'*}"$'\t' <<< "$list" && printf '%s\n' "$lline"
        done < "$labels_file" > "$tmp" || true
        mv "$tmp" "$labels_file"
      fi
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

  # Clipboard transformers (the Mod+Shift/Ctrl+P binds): each rewrites the
  # clipboard in place, so they compose with Mod+P (niri's screenshot UI
  # leaves the selected region on the clipboard) and with images copied from
  # anywhere else (Slack, Firefox, cliphist). The image type is sniffed and
  # requested explicitly because not every source offers image/png.
  annotate-clipboard = pkgs.writeShellApplication {
    name = "annotate-clipboard";
    runtimeInputs = with pkgs; [
      wl-clipboard
      libnotify
      (config.dotfiles.wrapGL satty)
    ];
    text = ''
      types=$(wl-paste --list-types 2>/dev/null || true)
      type=$(grep -m1 '^image/' <<< "$types" || true)
      if [ -z "$type" ]; then
        notify-send "annotate" "No image in clipboard"
        exit 0
      fi
      mkdir -p "$HOME/Pictures/Screenshots"
      wl-paste --type "$type" | satty --filename - \
        --output-filename "$HOME/Pictures/Screenshots/Screenshot from $(date '+%Y-%m-%d %H-%M-%S') (annotated).png" \
        --copy-command wl-copy --early-exit
    '';
  };

  ocr-clipboard = pkgs.writeShellApplication {
    name = "ocr-clipboard";
    runtimeInputs = with pkgs; [
      wl-clipboard
      libnotify
      imagemagick
      # English-only traineddata keeps the closure small; add languages
      # here if ever needed.
      (tesseract.override { enableLanguages = [ "eng" ]; })
    ];
    text = ''
      types=$(wl-paste --list-types 2>/dev/null || true)
      type=$(grep -m1 '^image/' <<< "$types" || true)
      if [ -z "$type" ]; then
        notify-send "OCR" "No image in clipboard"
        exit 0
      fi
      # Upscale before recognition: tesseract is tuned for ~300 DPI scans,
      # so screen-resolution UI text reads far better at 3x. --psm 6 expects
      # a uniform block of text rather than full-page layout.
      text=$(wl-paste --type "$type" \
        | magick - -resize 300% png:- \
        | tesseract stdin stdout --psm 6 2>/dev/null || true)
      if [ -z "$text" ]; then
        notify-send "OCR" "No text recognised"
        exit 0
      fi
      printf '%s' "$text" | wl-copy
      notify-send "OCR" "$text"
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
      "Mod+Shift+V".action.spawn = [
        (lib.getExe clipboard-picker)
        "images"
      ];
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

      # The recent-windows switcher (niri 25.11+) needs no binds: Alt+Tab,
      # Mod+Tab and the Alt/Mod+grave per-app variants are compositor
      # defaults that apply because nothing here claims those keys. The
      # `next-window` actions for remapping them aren't in 26.04 yet.

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

      # Indices include the named "scratch" workspace (scratchpad.nix), which
      # always sorts first — the first dynamic workspace is index 2.
      "Mod+1".action.focus-workspace = 2;
      "Mod+2".action.focus-workspace = 3;
      "Mod+3".action.focus-workspace = 4;
      "Mod+4".action.focus-workspace = 5;
      "Mod+Ctrl+1".action.move-window-to-workspace = 2;
      "Mod+Ctrl+2".action.move-window-to-workspace = 3;
      "Mod+Ctrl+3".action.move-window-to-workspace = 4;
      "Mod+Ctrl+4".action.move-window-to-workspace = 5;

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

      # The P family: Mod+P selects with niri's frozen-frame UI and leaves
      # the image on the clipboard; the Shift/Ctrl variants transform
      # whatever image the clipboard holds. They chain — e.g. Mod+P, then
      # Mod+Shift+P to crop tight in satty, then Mod+Ctrl+P to OCR the crop.
      "Mod+P".action.screenshot = [ ];
      "Mod+Shift+P".action.spawn = lib.getExe annotate-clipboard;
      "Mod+Ctrl+P".action.spawn = lib.getExe ocr-clipboard;

      "Ctrl+Print".action.screenshot-screen = [ ];
      "Alt+Print".action.screenshot-window = [ ];
      "Print".action.spawn = lib.getExe annotate-screenshot;

      "Mod+Shift+E".action.quit = [ ];
      "Ctrl+Alt+Delete".action.quit = [ ];

      # Was Mod+Shift+P until the clipboard transformers took that over.
      "Mod+Ctrl+Shift+P".action.power-off-monitors = [ ];
    };
  };
}
