{
  config,
  inputs,
  lib,
  ...
}:

let
  cfg = config.dotfiles.desktop.niri;
in
{
  options.dotfiles.desktop.niri.enable = lib.mkEnableOption "niri compositor user config" // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
    programs.niri.settings = {
      spawn-at-startup = [
        { command = [ "xwayland-satellite" ]; }
        { command = [ "mako" ]; }
        {
          command = [
            "swww"
            "img"
            "${inputs.self}/wallpapers/abbey.jpg"
          ];
        }
        {
          command = [
            "swaybg"
            "-m"
            "fill"
            "-i"
            "${inputs.self}/wallpapers/abbey-blur.jpg"
          ];
        }
      ];

      hotkey-overlay.skip-at-startup = true;

      environment.DISPLAY = ":0";

      overview = {
        backdrop-color = "#1c1c1c";
        zoom = 0.6;
        workspace-shadow = {
          softness = 0;
          spread = 1;
          offset = {
            x = 0;
            y = 0;
          };
          color = "#af875f";
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

      layout = {
        background-color = "transparent";
        gaps = 8;
        center-focused-column = "never";

        preset-column-widths = [
          { proportion = 0.33333; }
          { proportion = 0.5; }
          { proportion = 0.66667; }
        ];

        default-column-width = {
          proportion = 0.3333;
        };

        focus-ring.enable = false;

        border = {
          enable = true;
          width = 1;
          active.color = "#af5f5f";
          inactive.color = "#523636";
        };

        shadow = {
          enable = true;
          spread = 5;
          softness = 0;
          offset = {
            x = 0;
            y = 0;
          };
          color = "#101010";
          inactive-color = "#1c1c1c";
        };

        struts = {
          top = -4;
          bottom = -4;
          left = -4;
          right = -4;
        };
      };

      prefer-no-csd = true;

      screenshot-path = "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";

      window-rules = [
        {
          geometry-corner-radius = {
            top-left = 0.0;
            top-right = 0.0;
            bottom-left = 0.0;
            bottom-right = 0.0;
          };
          clip-to-geometry = true;
          draw-border-with-background = false;
          opacity = 0.98;
        }
        {
          matches = [ { title = "Firefox"; } ];
          opacity = 1.0;
          default-column-width = {
            proportion = 1.0;
          };
        }
        {
          matches = [ { app-id = "Spotify"; } ];
          opacity = 1.0;
          default-column-width = {
            proportion = 1.0;
          };
        }
        {
          matches = [ { app-id = "Slack"; } ];
          opacity = 1.0;
          default-column-width = {
            proportion = 1.0;
          };
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
            { app-id = "^org.pulseaudio.pavucontrol$"; }
            { app-id = "^net.davidotek.pupgui2$"; }
          ];
          open-floating = true;
          max-width = 800;
        }
        {
          matches = [ { app-id = ".*blueman.*"; } ];
          open-floating = true;
          min-width = 500;
          max-width = 500;
          min-height = 400;
          max-height = 400;
        }
      ];

      layer-rules = [
        {
          matches = [ { namespace = "^wallpaper$"; } ];
          place-within-backdrop = true;
        }
        {
          matches = [ { namespace = "^eww$"; } ];
          place-within-backdrop = true;
        }
      ];

      binds = {
        "Mod+Space".action.spawn = "firefox";
        "Mod+Return".action.spawn = "ghostty";
        "Mod+R".action.spawn = "fuzzel";
        "Mod+V".action.spawn = [
          "sh"
          "-c"
          "cliphist list | fuzzel --dmenu | cliphist decode | wl-copy"
        ];

        "Mod+I".action.spawn = [
          "sh"
          "-c"
          ''hex=$(hyprpicker -a -f hex) && notify-send "Color picked" "$hex copied to clipboard"''
        ];

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

      animations = {
        slowdown = 1.0;

        window-open = {
          kind.easing = {
            duration-ms = 400;
            curve = "linear";
          };
          custom-shader = ''
            vec4 open_color(vec3 coords_geo, vec3 size_geo) {
                if (coords_geo.x < 0.0 || coords_geo.x > 1.0 ||
                    coords_geo.y < 0.0 || coords_geo.y > 1.0)
                    return vec4(0.0);

                // Square cells: pick a cell size in pixels, derive grid from window size.
                float cell_px = 32.0;
                vec2 grid = floor(size_geo.xy / cell_px);
                grid = max(grid, vec2(1.0));

                vec2 cell  = floor(coords_geo.xy * grid);
                vec2 local = fract(coords_geo.xy * grid);

                // Wavefront from top-left.
                float t = (cell.x / grid.x + cell.y / grid.y) / 2.0;
                float d = 0.4;
                float cell_progress = clamp((niri_clamped_progress - t * (1.0 - d)) / d, 0.0, 1.0);

                // Grow from cell centre.
                vec2 dist = abs(local - 0.5);
                if (dist.x > cell_progress * 0.5 || dist.y > cell_progress * 0.5)
                    return vec4(0.0);

                // Blend from cell-centre sample to real texel to avoid end-of-anim jump.
                vec2 centre     = (cell + 0.5) / grid;
                vec3 centre_geo = vec3(clamp(centre, 0.0, 1.0), 1.0);
                vec3 centre_tex = niri_geo_to_tex * centre_geo;
                vec4 mosaic     = texture2D(niri_tex, centre_tex.st);

                vec3 real_tex = niri_geo_to_tex * coords_geo;
                vec4 real     = texture2D(niri_tex, real_tex.st);

                // Crossfade: mosaic at the start, real texture as cell fills.
                vec4 color = mix(mosaic, real, cell_progress * cell_progress);

                return color;
            }
          '';
        };

        window-close = {
          kind.easing = {
            duration-ms = 400;
            curve = "linear";
          };
          custom-shader = ''
            vec4 close_color(vec3 coords_geo, vec3 size_geo) {
                if (coords_geo.x < 0.0 || coords_geo.x > 1.0 ||
                    coords_geo.y < 0.0 || coords_geo.y > 1.0)
                    return vec4(0.0);

                float cell_px = 32.0;
                vec2 grid = floor(size_geo.xy / cell_px);
                grid = max(grid, vec2(1.0));

                vec2 cell  = floor(coords_geo.xy * grid);
                vec2 local = fract(coords_geo.xy * grid);

                // Wavefront from bottom-right.
                float t = ((grid.x - 1.0 - cell.x) / grid.x + (grid.y - 1.0 - cell.y) / grid.y) / 2.0;
                float d = 0.4;
                float cell_progress = clamp((niri_clamped_progress - t * (1.0 - d)) / d, 0.0, 1.0);

                float scale = 1.0 - cell_progress;
                vec2 dist = abs(local - 0.5);
                if (dist.x > scale * 0.5 || dist.y > scale * 0.5)
                    return vec4(0.0);

                // Crossfade from real texture to mosaic as cell shrinks.
                vec2 centre     = (cell + 0.5) / grid;
                vec3 centre_geo = vec3(clamp(centre, 0.0, 1.0), 1.0);
                vec3 centre_tex = niri_geo_to_tex * centre_geo;
                vec4 mosaic     = texture2D(niri_tex, centre_tex.st);

                vec3 real_tex = niri_geo_to_tex * coords_geo;
                vec4 real     = texture2D(niri_tex, real_tex.st);

                vec4 color = mix(real, mosaic, cell_progress * cell_progress);

                return color;
            }
          '';
        };

        window-resize = {
          kind.easing = {
            duration-ms = 300;
            curve = "ease-out-cubic";
          };
          custom-shader = ''
            // Exponential Easing
            float easeInExpo(float t) {
                return t == 0.0 ? 0.0 : pow(2.0, 10.0 * (t - 1.0));
            }
            float easeOutExpo(float t) {
                return t == 1.0 ? 1.0 : 1.0 - pow(2.0, -10.0 * t);
            }
            float easeInOutExpo(float t) {
                if (t == 0.0) return 0.0;
                if (t == 1.0) return 1.0;
                return t < 0.5 ? 0.5 * pow(2.0, 20.0 * t - 10.0) : 1.0 - 0.5 * pow(2.0, -20.0 * t + 10.0);
            }
            // Sine Easing
            float easeInSine(float t) {
                return 1.0 - cos((t * 3.141592653589793) / 2.0);
            }
            float easeOutSine(float t) {
                return sin((t * 3.141592653589793) / 2.0);
            }
            float easeInOutSine(float t) {
                return -0.5 * (cos(3.141592653589793 * t) - 1.0);
            }
            // Quartic Easing
            float easeInQuart(float t) {
                return t * t * t * t;
            }
            float easeOutQuart(float t) {
                float f = t - 1.0;
                return 1.0 - f * f * f * f;
            }
            float easeInOutQuart(float t) {
                return t < 0.5 ? 8.0 * t * t * t * t : 1.0 - 8.0 * (t - 1.0) * (t - 1.0) * (t - 1.0) * (t - 1.0);
            }

            vec4 resize_color(vec3 coords_curr_geo, vec3 size_curr_geo) {

                float p = niri_clamped_progress;
                vec3 coords_tex_next = niri_geo_to_tex_next * coords_curr_geo;

                float distance = 0.0075;

                vec4 outColor = vec4(0.0);

                vec2 rXY = mix(
                    vec2(-distance),
                    vec2(0.0),
                    easeInQuart(p)
                );

                vec2 gXY = mix(
                    vec2(0.0,0.0),
                    vec2(0.0),
                    easeInQuart(p)
                );

                vec2 bXY = mix(
                    vec2(distance),
                    vec2(0.0),
                    easeInSine(p)
                );

                outColor.r = texture2D(niri_tex_next, coords_tex_next.st + rXY).r;
                outColor.g = texture2D(niri_tex_next, coords_tex_next.st + gXY).g;
                outColor.b = texture2D(niri_tex_next, coords_tex_next.st + bXY).b;
                outColor.a = texture2D(niri_tex_next, coords_tex_next.st ).a;

                return outColor;
            }
          '';
        };
      };
    };
  };
}
