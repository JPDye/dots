{lib, config, pkgs, inputs, colors, ... }:

let
  border-style = {
    radius-float = 1.0;
    radius-int = 1;
    width = 1;
  };
in
{
  home.username = "jd";
  home.homeDirectory = "/home/jd";
  home.stateVersion = "25.11";

  gtk.enable = true;
  qt.enable = true;

  programs.home-manager.enable = true;

  nixpkgs.config.allowUnfree = true;
  home.packages = [
    # App Launcher
    pkgs.fuzzel


    # Bar
    pkgs.eww

    # Shell
    pkgs.nushell
    pkgs.starship
    pkgs.fastfetch

    # Terminal
    pkgs.alacritty

    # Editor
    pkgs.helix

    # Media
    pkgs.vlc

    # Work
    pkgs.slack
    pkgs.termius

    pkgs.qbittorrent
  ];

  services.mako = {
    enable = true;

    settings = {
      border-color = "#${colors.primary}";
      background-color = "#${colors.bg0}";
      text-color = "#${colors.fg2}";

      border-radius = border-style.radius-int;

      timeout = 5000;
    };
  };

  programs.eww = {
    enable = true;
    configDir = "/home/jd/.config/nix/eww";
  };

  programs.fuzzel = {
    enable = true;

    settings = {
      main = {
        icons-enabled = false;
        terminal = "alacritty";
        lines = 5;
        dpi-aware = "no"; # enable for high DPI displays
        font = lib.mkForce "DroidSans Mono:size=11";

        horizontal-pad = 16;
        vertical-pad = 16;
      };

      colors = {
        border = lib.mkForce "${colors.primary}ff";

        input = lib.mkForce "${colors.primary}ff";
        text = lib.mkForce "${colors.fg2}ff";

        prompt = lib.mkForce "${colors.secondary}ff";
        match = lib.mkForce "${colors.secondary}ff";

        selection = lib.mkForce "282828ff";
        selection-text = lib.mkForce "${colors.fg1}ff";
        selection-match = lib.mkForce "${colors.secondary}ff";
      };

      border = { 
        width = lib.mkForce border-style.width;
        radius = lib.mkForce border-style.radius-int;
      };
    };
  };

  programs.starship = {
    enable = true;
    enableNushellIntegration = true;
    settings = {
      format = ''
        [┌](#504945)[ ](#504945)$os$username [󰅂 ](#${colors.red})$directory[󰅂](#${colors.orange})$git_branch$git_status[󰅂](#${colors.yellow})$time[󰅂](#${colors.green})
        [└](#504945)[󰅂 ](#504945)
      '';

      add_newline = true;
      command_timeout = 3600;

      username = {
        show_always = true;
        style_user = "#${colors.red}";
        style_root = "#${colors.red}";
        format = "[$user]($style)";
        disabled = false;
      };

      os = {
        style = "#D65D0E";
        disabled = true;
      };

      directory = {
        style = "#${colors.orange}";
        format = "[$path ]($style)";
        truncation_length = 3;
        truncation_symbol = "󰇘/";
        substitutions = {
          "Documents" = "󰈙 ";
          "Downloads" = " ";
          "Music" = " ";
          "Pictures" = " ";
        };
      };
      
      git_branch = {
        symbol = "";
        style = "#${colors.yellow}";
        format = "[ $symbol $branch]($style)";
      };
      
      git_status = {
        style = "#${colors.yellow}";
        format = "[$all_status$ahead_behind ]($style)";
      };
      
      time = {
        disabled = false;
        time_format = "%R";
        style = "#${colors.green}";
        format = "[  $time ]($style)";
      };
    };
  }; 

  # Terminal setup
  programs.alacritty = {
    enable = true;

    settings = {
      terminal.shell = "nu";

      selection = {
        save_to_clipboard = true;
      };

      cursor = {
        style = {
          shape = "beam";
          blinking = "never";
        };
      };

      font = {
        size = lib.mkForce 12.0;
      };

      window = {
        padding = {
          x = 5;
          y = 5;
        };
      };
    };
  };

  programs.nushell = {
    enable = true;
    settings.show_banner = false;

    environmentVariables = {
      EDITOR = "hx"; 
      VISUAL = "hx";
    };

    shellAliases = {
     vi = "hx";
     vim = "hx";
     nano = "hx";
    };

    extraConfig = ''
       $env.config = {
        hooks: {
          pre_prompt: [{ ||
            if (which direnv | is-empty) {
              return
            }

            direnv export json | from json | default {} | load-env
          }]
        }  
      } 
      
      $env.PATH = ($env.PATH | 
        split row (char esep) |
        prepend /home/myuser/.apps |
        append /usr/bin/env |
        append /home/linuxbrew/.linuxbrew/bin |
        append /home/jd/eww/target/release
      )

      # Make fastfetch centered in console
      let term_size = (term size)
      let width = $term_size.columns

      if $width < 80 {
        let size = 45
        let padding = [((($width - $size) / 2) | math floor) 0] | math max
        
        fastfetch --logo nixos_small --logo-padding-top 6 --logo-padding-left $padding        
        
      } else {
        let size = 68
        let padding = [((($width - $size) / 2) | math floor) 0] | math max

        fastfetch --logo nixos --logo-padding-top 1 --logo-padding-left $padding        
      }
    '';
  };

  stylix.targets.zellij.enable = false;
  stylix.targets.mako.enable = false;
  stylix.targets.spicetify.enable = false;
  stylix.targets.starship.enable = false;
  stylix.targets.helix.enable = true;
  stylix = {
    enable = true;
    polarity = "dark";
    base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-hard.yaml";
    override = lib.mkForce {
       base00 = "${colors.bg0}";
       base01 = "${colors.bg1}";
       base02 = "${colors.bg2}";
       base03 = "${colors.bg3}"; 
       base04 = "${colors.fg3}";
       base05 = "${colors.white}";     # ::<>, ()
       base06 = "${colors.fg1}";
       base07 = "${colors.fg0}";

       base08 = "${colors.orange}";    # self, fields, variables
       base09 = "${colors.yellow}";    # ints, booleans, constants
       base0A = "${colors.pink}";      # HashMap<String, String>;
       base0B = "${colors.green}";     # "abcdefg" and fields
       base0C = "${colors.orange}";    # "\n"
       base0D = "${colors.green}";     # println!, methods
       base0E = "${colors.red}";       # pub, impl, &, &mut
       base0F = "ffffff";     
    };

    fonts = {
      # monospace = {
      #   name = "DroidSans Mono";
      # };

      # serif = {
      #   name = "DroidSans Mono";
      # };

      # sansSerif = {
      #   name = "DroidSans Mono";
      # };

      sizes = {
        applications = 14;
        desktop = 14;
        popups = 14;
        terminal = 14;
      };
    };

    cursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Original-Amber";
      size = 16;
    };

  };


  # Multiplexing setup
  programs.zellij = {
    enable = true;

    settings = {
      default_shell = "nu";
      default_layout = "compact";
      pane_frames = false;
      show_startup_tips = false;

      theme = "custom";
      themes.custom = {

        frame_selected = {
          base = "#${colors.primary}";

          emphasis_0 =  "#${colors.secondary}";
          emphasis_1 =  "#${colors.pink}";
          emphasis_2 =  "#${colors.grey}";
          emphasis_3 =  "#${colors.yellow}";
        };

        frame_unselected = {
          base = "#${colors.bg2}";

          emphasis_0 =  "#${colors.secondary}";
          emphasis_1 =  "#${colors.pink}";
          emphasis_2 =  "#${colors.green}";
          emphasis_3 =  "#${colors.yellow}";
        };

        frame_highlight = {
          base = "#${colors.secondary}"; 

          emphasis_0 =  "#${colors.orange}"; 
          emphasis_1 =  "#${colors.pink}"; 
          emphasis_2 =  "#${colors.green}";  
          emphasis_3 =  "#${colors.yellow}";          
        };

        ribbon_selected = {
          base =  "#${colors.bg0}";
          background =  "#${colors.secondary}";

          emphasis_0 =  "#${colors.secondary}";
          emphasis_1 =  "#${colors.pink}";
          emphasis_2 =  "#${colors.primary}";
          emphasis_3 =  "#${colors.yellow}";
        };

        ribbon_unselected = {
          base =  "#${colors.secondary}";
          background =  "#${colors.bg0}";


          emphasis_0 =  "#${colors.secondary}";
          emphasis_1 =  "#${colors.pink}";
          emphasis_2 =  "#${colors.primary}";
          emphasis_3 =  "#${colors.yellow}";
        };

        text_unselected = {
          base = "#${colors.mid}";
          background =  "#${colors.bg0}";

          emphasis_0 =  "#${colors.secondary}";
          emphasis_1 =  "#${colors.pink}";
          emphasis_2 =  "#${colors.primary}";
          emphasis_3 =  "#${colors.yellow}";
        };

        text_selected = {
          base = "#${colors.bg2}";
          background =  "#${colors.bg0}";

          emphasis_0 =  "#${colors.secondary}";
          emphasis_1 =  "#${colors.pink}";
          emphasis_2 =  "#${colors.primary}";
          emphasis_3 =  "#${colors.yellow}";
        };

        list_unselected = {
          base = "#${colors.mid}";
          background =  "#${colors.bg0}";

          emphasis_0 =  "#${colors.secondary}";
          emphasis_1 =  "#${colors.pink}";
          emphasis_2 =  "#${colors.primary}";
          emphasis_3 =  "#${colors.yellow}";
        };

        list_selected = {
          base = "#${colors.mid}";
          background =  "#${colors.bg1}";

          emphasis_0 =  "#${colors.secondary}";
          emphasis_1 =  "#${colors.pink}";
          emphasis_2 =  "#${colors.primary}";
          emphasis_3 =  "#${colors.yellow}";
        };


        table_title = {
          base = "#${colors.grey}";
          background =  "#${colors.bg0}";

          emphasis_0 =  "#${colors.secondary}";
          emphasis_1 =  "#${colors.pink}";
          emphasis_2 =  "#${colors.primary}";
          emphasis_3 =  "#${colors.yellow}";
        };

        table_cell_selected = {
          base = "#${colors.mid}";
          background =  "#${colors.bg1}";

          emphasis_0 =  "#${colors.secondary}";
          emphasis_1 =  "#${colors.pink}";
          emphasis_2 =  "#${colors.primary}";
          emphasis_3 =  "#${colors.yellow}";
        };

        table_cell_unselected = {
          base = "#${colors.mid}";
          background =  "#${colors.bg0}";


          emphasis_0 =  "#${colors.secondary}";
          emphasis_1 =  "#${colors.pink}";
          emphasis_2 =  "#${colors.primary}";
          emphasis_3 =  "#${colors.yellow}";
        };
      };
    };
  };

  # Dev shell
  programs.direnv = {
    enable = true;
    enableNushellIntegration = true;
    nix-direnv.enable = true;
    silent = true;
  };

  # Editor
  home.sessionVariables.EDITOR = "hx";
  programs.helix = {
    enable = true;
    defaultEditor = true;


    settings =  {
      keys = {
        normal = {
          C-v = ":toggle lsp.display-inlay-hints";
          ret = "goto_word";
        };
      };
      

      editor = {
        auto-format = true;
        line-number = "relative";

        cursorline = true;

        continue-comments = false;

        gutters = ["line-numbers" "diagnostics"];

        bufferline= "multiple";

        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };

        indent-guides = {
          render = true;
          character =  "|";
          skip-levels = 1;
        };

        file-picker.hidden = false;

        lsp.display-messages = true;
      };
    };


    languages = {
      language-server.rust-analyzer = {
        config = {
          # More robust settings for large projects
          cargo = {
            loadOutDirsFromCheck = true;
            buildScripts.overrideCommand = ["cargo" "check" "--message-format=json" "--all-targets"];
            # Specify features if needed
            features = "all";
          };

          # Critical for large repositories like Hyper
          procMacro.enable = true;
          # Avoid running clippy by default on large codebases
          check.command = "check";
          # Better memory management
          cachePriming.enable = true;
          # Increase these limits for large projects
          lruCapacity = 1000;
          # Helpful for finding issues
          diagnostics.experimental.enable = true;
          # Only run analysis on the current workspace
          workspace.symbol.search.scope = "workspace";
          # Skip certain analysis passes on large files
          diagnostics.disabled = ["unresolved-proc-macro" "macro-error"];
        };
      };

      language-server.clangd = {
        command = "clangd";
        args = [
          "--background-index=false"      # Disable background indexing for performance
          "--clang-tidy=false"            # Disable clang-tidy for large codebases
          "--completion-style=detailed"   # Less verbose completions
          "--header-insertion=never"      # Don't auto-insert headers
          "--pch-storage=memory"          # Use memory for PCH storage
          "--malloc-trim"                 # Reduce memory usage
          "--limit-results=20"            # Limit completion results
          "--log=error"                   # Reduce log verbosity
          "-j=4"                          # Limit to 4 threads
        ];
        timeout = 30;
      };

      language = [
        {
          name = "rust";
          auto-format = true;
        }
      
        {
          name = "typst";
          file-types = ["typ"];

          text-width = 100;
          soft-wrap.enable = true;
          soft-wrap.wrap-at-text-width = true;
          soft-wrap.wrap-indicator = " ";
        }

        {
          name = "markdown";
          file-types = ["md"];
          text-width = 100;
          soft-wrap.enable = true;
          soft-wrap.wrap-at-text-width = true;
          soft-wrap.wrap-indicator = " ";
        }
      ];
    };
  };

  programs.nixcord = {
    enable = true;

    config = {
      themeLinks = [
        "https://github.com/refact0r/system24/blob/main/theme/flavors/gruvbox-material.theme.css"
      ];
    };
  };


  textfox = {
    enable = true;
    profile = "jd";
    config = {
      tabs.horizontal.enable = false;
    
      background = {
        color = "#1d2021";
      };

      border = {
          color = "#af5f5f";
          width = "1px";
          radius = "1px";
      };
    };
  };

  

  # Browser
  stylix.targets.firefox.profileNames = [ "jd" ];
  programs.firefox = {    
    enable = true;

    policies = {
      ExtensionSettings = {
        "*".installation_mode = "allowed";

        # "{cb7f7992-81db-492b-9354-99844440ff9b}" = {
        #   install_url = " https://addons.mozilla.org/firefox/downloads/latest/bento/latest.xpi";
        #   installation_mode = "force_installed";
        # };
      };
    };

    profiles.jd = {
      settings = {
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        "layers.acceleration.force-enabled" = true;
        "gfx.webrender.all" = true;
        "svg.context-properties.content.enabled" = true;
      };


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

            definedAliases = [ "@lib" ];
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
    
      extensions.packages = with inputs.firefox-addons.packages."x86_64-linux"; [
        # bitwarden

        ublock-origin 
        sponsorblock

        foxyproxy-standard

        darkreader
        gruvbox-dark-theme

        youtube-shorts-block
        return-youtube-dislikes
      ];    
    };
  };

  programs.fastfetch = {
    enable = true;

    settings = {
      logo = {
        # source = "arch";
        source = "nixos";

        padding = {
          top = 1;
          left = 1;
          right = 4;
        };

        color = {
          "1" = "#${colors.accent}";
          "2" = "#${colors.primary}";
        };
      };

      display = {
        separator = " : ";
        # brightColor = true;

        color = {
          keys = "#${colors.secondary}";
        };

        key = {
          type = "string";
        };
      };

      modules = [
        "break"
        "break"

        "break"
        "break"

        {
          type = "Datetime";
          key = "";
          format = "{12} {5} {1}";
        }

        {
          type = "Datetime";
          key = "󰥔";
          format = "{14}:{18}";
        }

        "break"
        
        {
          type = "wm";
          key = "";
          format = "{2}";
        }
        
        {
          type = "terminal";
          key = "";
          format = "{5}";
        }

        
        {
          type = "editor";
          key = "";
          format = "{2}";
        }        

        "break"


        {
          type = "media";
          key = "";
          format = "{3}";

        }
        {
          type = "media";
          key = "󰀥";
          format = "{4}";

        }
        {
          type = "media";
          key = "";
          format = "{1}";
        }

        "break"

        {
          type = "cpuusage";
          key = "";
          percent = {
            type = 6;
            green = 30;
            cyan = 60;
            red = 100;
          };
        }
        
        {
          type = "memory";
          key = "";
          percent = {
            type = 6;
            green = 30;
            cyan = 60;
            red = 100;
          };
        }
        
        {
          type = "disk";
          percent = {
            type = 6;
            green = 30;
            cyan = 60;
            red = 100;
          };
          key = "󰋊";
        }
        
        # "break"      
        # "break"
        # "break"

        # "colors"

      ];
    };
  };
}
