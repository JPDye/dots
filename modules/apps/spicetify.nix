{
  config,
  lib,
  pkgs,
  inputs,
  colors,
  ...
}:

let
  cfg = config.dotfiles.apps.spicetify;
in
{
  options.dotfiles.apps.spicetify.enable = lib.mkEnableOption "spicetify spotify theme" // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
    programs.spicetify =
      let
        spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
      in
      {
        enable = true;

        # The `text` theme, plus one rule of our own. `additionalCss` is
        # appended to the theme's user.css by spicetify-nix.
        theme = lib.mkForce (
          spicePkgs.themes.text
          // {
            # The song progress bar. Spotify paints the fill from
            # `--fg-color`, and the theme points that at `--spice-button-active`
            # (its user.css, the `.progress-bar` rule). Overriding the
            # variable on the bar is therefore enough to recolour the fill.
            #
            # The fade lives on `.x-progressBar-fillColor` rather than on the
            # variable: a custom property cannot be transitioned unless it is
            # registered with `@property`, but the `background-color` that
            # reads it can be, and that animates between the two resolved
            # colours.
            #
            # `--mg-color` paints the stretch between the play head and the
            # pointer while the pointer is on the bar. The theme leaves it at
            # Spotify's `--background-tinted-base`, which shows as red.
            #
            # The theme draws the time text in `--spice-button-active` with
            # `mix-blend-mode: difference`, so its colour shifts with whatever
            # sits under it. A fixed colour with no blend keeps it steady.
            # `fg1` is one step below the main text colour: pure white read
            # too bright against the bar.
            additionalCss = ''
              .main-nowPlayingBar-container .playback-bar .progress-bar,
              .main-nowPlayingBar-container .playback-bar [data-testid="progress-bar"] {
                --fg-color: #${colors.yellow} !important;
                --mg-color: #${colors.borderActive} !important;
              }

              .main-nowPlayingBar-container .playback-bar__progress-time-elapsed,
              .main-nowPlayingBar-container .main-playbackBarRemainingTime-container {
                mix-blend-mode: normal !important;
                color: #${colors.fg1} !important;
              }

              .main-nowPlayingBar-container .playback-bar:hover .progress-bar,
              .main-nowPlayingBar-container .playback-bar:hover [data-testid="progress-bar"] {
                --fg-color: #${colors.borderActive} !important;
              }

              .main-nowPlayingBar-container .playback-bar .x-progressBar-fillColor {
                transition: background-color 200ms ease-out;
              }
            '';
          }
        );
        customColorScheme = lib.mkForce {
          "accent" = "${colors.accent}";
          "accent-active" = "${colors.urgent}";
          "accent-inactive" = "${colors.bg3}";
          "banner" = "${colors.accent}";
          # A focused in-app element outline follows the niri active window
          # border, so a focused thing reads the same whether it is a window,
          # a pane or a panel inside an app. A resting outline stays a dark
          # grey.
          "border-active" = "${colors.borderActive}";
          "border-inactive" = "${colors.bg2}";
          "header" = "${colors.accent}";
          "highlight" = "${colors.urgent}";
          "main" = "${colors.bg0}";
          "notification" = "${colors.info}";
          "notification-error" = "${colors.urgent}";
          # Secondary lines (artist, "Playlist • owner", the track-list
          # header) take the cool blue, so they read apart from the gold
          # accents.
          "subtext" = "${colors.blue}";
          "text" = "${colors.fg0}";
        };
      };
  };
}
