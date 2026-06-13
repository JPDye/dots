{
  colors,
  config,
  lib,
  themeLib,
  ...
}:

let
  # Darker than bg1 but still above the bg0 terminal backgrounds the
  # floats sit on — the palette has no step in between, so blend one a
  # quarter of the way up the bg0->bg1 ramp.
  float-shadow = themeLib.mix 0.25 colors.bg0 colors.bg1;
in

{
  config = lib.mkIf config.dotfiles.desktop.niri.enable {
    # Blur (niri 26.04+) isn't in niri-flake's settings schema yet, so these
    # ride the extraConfig escape hatch. Blur defaults to xray, which samples
    # only the wallpaper; menus and the launcher float over windows, so they
    # need `xray false` to frost what's actually beneath them.
    dotfiles.desktop.niri.extraConfig = ''
      // Milder frost than the default (passes 3, offset 3): dual-kawase
      // doubles the blur scale per pass, so one pass fewer roughly halves
      // it. Drop offset next if it's still too strong.
      blur {
          passes 2
          offset 2
      }

      // Right-click menus, dropdowns and tooltips of every window. The
      // opacity is what makes the blur visible — popups are opaque on
      // their own.
      window-rule {
          popups {
              opacity 0.92
              background-effect {
                  blur true
                  xray false
              }
          }
      }

      // Floating windows hover over other (often dark) windows, so they get
      // the popup treatment: a little translucency to let the blur show,
      // and a hard-edged halo lighter than the tiled bg0 shadow (which just
      // masks the gaps and would vanish against dark windows). The border
      // thins to 1px, matching fuzzel's.
      window-rule {
          match is-floating=true
          // Floats open a touch wider than their natural size. This is just a
          // default, so per-app rules still win: blueman's fixed max-width
          // clamps it back to 500, and the dialog list caps at max-width 1000.
          default-column-width {
              fixed 900
          }
          opacity 0.92
          border {
              width 1
          }
          background-effect {
              blur true
              xray false
          }
          shadow {
              on
              spread 8
              softness 0
              offset x=0 y=0
              color "#${float-shadow}"
              // Explicit so unfocused floats don't inherit the layout
              // shadow's bg0 and vanish; focus is already signalled by the
              // border colour.
              inactive-color "#${float-shadow}"
          }
      }

      // The clipboard image picker (nsxiv, Mod+Shift+V) is floating, so it
      // picks up the halo above. Override it for this one window: a solid 1px
      // red border and a hard 6px drop shadow. Same shadow idiom as the
      // floats, but offset instead of spread (so it's a displaced drop rather
      // than a halo) and dark bg0 rather than the lighter float halo. Placed
      // after the is-floating rule so it wins; matches the same "sxiv" app-id
      // as the open-floating rule below.
      window-rule {
          match app-id="sxiv"
          border {
              width 1
              active-color "#${colors.border}"
              inactive-color "#${colors.border}"
          }
          shadow {
              on
              spread 0
              softness 0
              offset x=6 y=6
              color "#${colors.bg0}"
              inactive-color "#${colors.bg0}"
          }
      }

      // fuzzel is layer-shell (not an xdg-popup), so the rules above can't
      // reach it; match its layer namespace instead. Its background gets the
      // translucency in fuzzel.nix; the shadow matches the floating windows'.
      layer-rule {
          match namespace="^launcher$"
          background-effect {
              blur true
              xray false
          }
          shadow {
              on
              spread 8
              softness 0
              offset x=0 y=0
              color "#${float-shadow}"
          }
      }
    '';

    programs.niri.settings = {
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
          opacity = 1.0;
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
        # Generic sizing classes: any window whose app-id ends in .thin/.wide/
        # .full opens at a preset column width, e.g.
        # `ghostty --class=com.mitchellh.ghostty.wide`. The suffix form is
        # because GTK application ids must contain a dot — a bare "thin" would
        # be rejected by ghostty.
        {
          matches = [ { app-id = "\\.thin$"; } ];
          default-column-width = {
            proportion = 0.33333;
          };
        }
        {
          matches = [ { app-id = "\\.wide$"; } ];
          default-column-width = {
            proportion = 0.66667;
          };
        }
        {
          matches = [ { app-id = "\\.full$"; } ];
          default-column-width = {
            proportion = 1.0;
          };
        }
        # Scratchpad class: opens floating wherever you are; nscratch
        # (scratchpad.nix) stashes it on the named "scratch" workspace from
        # the second press on. Deliberately NOT open-on-workspace "scratch":
        # new windows take focus, so opening there would drag you to the
        # scratch workspace on first spawn instead of bringing the terminal
        # to you. Floating via rule rather than nscratch's own flags because
        # niri can't float an already-mapped window's first frame.
        {
          matches = [ { app-id = "\\.scratch$"; } ];
          open-floating = true;
        }
        # The nsxiv image grid behind Mod+Shift+V (clipboard image picker in
        # binds.nix). It's an X11 client via xwayland-satellite, so niri sees
        # its WM_CLASS; "sxiv" matches whether that resolves to the instance
        # (nsxiv-clipboard, set with -N) or the class (Nsxiv). Floated and
        # centred so it reads as a picker rather than tiling into the layout.
        {
          matches = [ { app-id = "sxiv"; } ];
          open-floating = true;
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
          max-width = 1000;
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
    };
  };
}
