{
  config,
  lib,
  pkgs,
  colors,
  monoFont,
  ...
}:

let
  cfg = config.dotfiles.apps.firefox;
in
{
  options.dotfiles.apps.firefox.enable = lib.mkEnableOption "firefox + textfox theme + addons" // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
    textfox = {
      enable = true;
      profiles = lib.mkForce [ "jd" ];
      config = {
        tabs.horizontal.enable = false;

        # textfox paints every focused and hovered border from `--tf-accent`,
        # which this option sets, so the in-app active outline follows the
        # niri window border. The same variable also colours accent text and
        # links in the chrome, because textfox has one knob for both.
        font = {
          family = monoFont;
          accent = "#${colors.borderActive}";
        };

        background = {
          color = "#${colors.bg0}";
        };

        # A resting panel border is a dark grey, one step above the chrome
        # background. On hover or focus textfox swaps it to `--tf-accent`,
        # the niri active-border colour.
        border = {
          color = "#${colors.bg1}";
        };

        # The panel titles ("navbar", "tabs", "main" and the rest) are
        # `::before` labels. At rest they inherit the chrome text colour, and
        # on hover textfox paints them `--tf-accent`. This paints them gold at
        # rest and restates the hover rule after it. textfox imports
        # config.css last, so these rules win at equal specificity.
        extraConfig = ''
          #nav-bar::before,
          #PersonalToolbar::before,
          box#vertical-tabs::before,
          #TabsToolbar::before,
          #tabbrowser-tabbox::before,
          findbar::before,
          #sidebar-box::before,
          .buttons-wrapper::before {
            color: #${colors.gold} !important;
          }

          #nav-bar:hover::before,
          #PersonalToolbar:hover::before,
          box#vertical-tabs:hover::before,
          #TabsToolbar:hover::before,
          #tabbrowser-tabbox:hover::before,
          findbar:hover::before,
          #sidebar-box:hover::before,
          .buttons-wrapper:hover::before {
            color: var(--tf-accent) !important;
          }
        '';
      };
    };

    programs.firefox = {
      enable = true;
      configPath = ".mozilla/firefox";

      profiles.jd = {
        search = {
          force = true;
          engines = {
            "Rust Lib" = {
              urls = [
                {
                  template = "https://doc.rust-lang.org/stable/std/";
                  params = [
                    {
                      name = "search";
                      value = "{searchTerms}";
                    }
                  ];
                }
              ];

              definedAliases = [ "@rs" ];
            };

            "Nix Packages" = {
              urls = [
                {
                  template = "https://search.nixos.org/packages";
                  params = [
                    {
                      name = "type";
                      value = "packages";
                    }
                    {
                      name = "query";
                      value = "{searchTerms}";
                    }
                  ];
                }
              ];

              definedAliases = [ "@np" ];
            };

            "HM Packages" = {
              urls = [
                {
                  template = "https://mynixos.com/search";
                  params = [
                    {
                      name = "q";
                      value = "{searchTerms}";
                    }
                  ];
                }
              ];

              definedAliases = [ "@hm" ];
            };
          };
        };

        extensions.packages = with pkgs.firefox-addons; [
          bitwarden

          ublock-origin
          privacy-badger
          clearurls
          istilldontcareaboutcookies

          sponsorblock
          youtube-shorts-block
          return-youtube-dislikes

          languagetool

          darkreader
          humble-new-tab

          foxyproxy-standard

          sidebery
        ];
      };
    };
  };
}
