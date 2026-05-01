{ lib, pkgs, colors, ... }:

{
  textfox = {
    enable = true;
    profiles = lib.mkForce [ "jd" ];
    config = {
      tabs.horizontal.enable = false;

      font = {
        family = "Berkeley Mono Variable";
        accent = "#${colors.red}";
      };


      background = {
        color = "#${colors.bg0}";
      };

      border = {
        color = "#${colors.bg1}";
      };
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
            urls = [{
              template = "https://doc.rust-lang.org/stable/std/";
              params = [
                { name = "search"; value = "{searchTerms}"; }
              ];
            }];

            definedAliases = [ "@rs" ];
          };

          "Rust Crates" = {
            urls = [{
              template = "https://lib.rs/search";
              params = [
                { name = "q"; value = "{searchTerms}"; }
              ];
            }];

            definedAliases = [ "@crs" ];
          };

          "Nix Packages" = {
            urls = [{
              template = "https://search.nixos.org/packages";
              params = [
                { name = "type"; value = "packages"; }
                { name = "query"; value = "{searchTerms}"; }
              ];
            }];

            definedAliases = [ "@np" ];
          };


          "HM Packages" = {
            urls = [{
              template = "https://mynixos.com/search";
              params = [
                { name = "q"; value = "{searchTerms}"; }
              ];
            }];

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
        tabliss

        foxyproxy-standard

        sidebery
      ];
    };
  };
}
