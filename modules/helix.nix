{
  colors,
  config,
  hostname,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  programs.helix = {
    enable = true;
    defaultEditor = true;
    package = inputs.helix.packages.${pkgs.stdenv.hostPlatform.system}.default;

    extraPackages = with pkgs; [
      nixd
      nixfmt
      taplo
      marksman
      tinymist
      harper
      typos-lsp

      bash-language-server
      yaml-language-server
      dockerfile-language-server
      basedpyright
      ruff
    ];

    themes.stylix-jumps = {
      inherits = "stylix";

      "ui.virtual.jump-label" = {
        fg = "#${colors.blue}";
        modifiers = [ "bold" ];
      };

      "ui.statusline.normal" = {
        fg = "#${colors.bg0}";
        bg = "#${colors.green}";
      };
      "ui.statusline.insert" = {
        fg = "#${colors.bg0}";
        bg = "#${colors.red}";
      };
      "ui.statusline.select" = {
        fg = "#${colors.bg0}";
        bg = "#${colors.pink}";
      };

    };

    settings = {
      theme = lib.mkForce "stylix-jumps";

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
        gutters = [
          "diagnostics"
          "spacer"
          "line-numbers"
          "spacer"
          "diff"
        ];
        bufferline = "always";

        jump-label-alphabet = "asdfghjklweruio";

        completion-replace = true;
        completion-trigger-len = 2;
        idle-timeout = 50;

        trim-trailing-whitespace = true;
        insert-final-newline = true;

        color-modes = true;

        statusline = {
          left = [
            "mode"
            "spinner"
            "file-name"
            "file-modification-indicator"
          ];
          center = [ "diagnostics" ];
          right = [
            "version-control"
            "selections"
            "register"
            "position"
            "file-encoding"
            "file-line-ending"
            "file-type"
          ];
          separator = "│";
          mode = {
            normal = "NORMAL";
            insert = "INSERT";
            select = "SELECT";
          };
        };

        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };

        indent-guides = {
          render = true;
          character = "|";
          skip-levels = 1;
        };

        file-picker = {
          hidden = false;
          follow-symlinks = true;
          git-ignore = true;
          git-global = true;
          parents = true;
        };

        lsp = {
          display-messages = true;
          display-inlay-hints = true;
        };

        end-of-line-diagnostics = "hint";
        inline-diagnostics.cursor-line = "disable";

        auto-save = {
          focus-lost = true;
          after-delay.enable = true;
          after-delay.timeout = 3000;
        };
      };
    };

    languages = {
      language-server = {
        rust-analyzer.config = {
          cargo = {
            buildScripts.enable = true;
            allFeatures = true;
            extraArgs = [ "--keep-going" ];
            targetDir = true;
          };
          procMacro.enable = true;
          check = {
            command = "clippy";
            extraArgs = [
              "--"
              "-W"
              "clippy::pedantic"
            ];
            allTargets = true;
          };
          cachePriming.enable = true;

          inlayHints = {
            bindingModeHints.enable = false;
            closureReturnTypeHints.enable = "with_block";
            lifetimeElisionHints.enable = "skip_trivial";
            maxLength = 25;
          };

          imports.granularity.group = "module";
          imports.prefix = "self";

          completion.autoimport.enable = true;
          completion.callable.snippets = "fill_arguments";

          diagnostics.experimental.enable = true;
          hover.actions.references.enable = true;
          restartServerOnConfigChange = true;
          lru.capacity = 256;
          "workspace.symbol.search".scope = "workspace";
        };

        nixd = {
          command = "nixd";
          config.nixd = {
            formatting.command = [ "nixfmt" ];
            nixpkgs.expr = "import <nixpkgs> { }";
            options.home-manager.expr = ''(builtins.getFlake "${config.home.homeDirectory}/.config/nix").homeConfigurations.${hostname}.options'';
          };
        };

        taplo = {
          command = "taplo";
          args = [
            "lsp"
            "stdio"
          ];
        };

        marksman = {
          command = "marksman";
          args = [ "server" ];
        };

        tinymist = {
          command = "tinymist";
        };

        harper-ls = {
          command = "harper-ls";
          args = [ "--stdio" ];
        };

        typos = {
          command = "typos-lsp";
        };
      };

      language = [
        {
          name = "rust";
          roots = [
            "Cargo.toml"
            "Cargo.lock"
            "rust-toolchain.toml"
          ];
          language-servers = [
            "rust-analyzer"
            "typos"
          ];
        }
        {
          name = "nix";
          auto-format = true;
          formatter = {
            command = "nixfmt";
          };
          language-servers = [
            "nixd"
            "typos"
          ];
        }
        {
          name = "toml";
          language-servers = [
            "taplo"
            "typos"
          ];
        }
        {
          name = "typst";
          file-types = [ "typ" ];
          text-width = 100;
          soft-wrap = {
            enable = true;
            wrap-at-text-width = true;
            wrap-indicator = " ";
          };
          language-servers = [
            "tinymist"
            "harper-ls"
          ];
        }
        {
          name = "markdown";
          file-types = [ "md" ];
          text-width = 100;
          soft-wrap = {
            enable = true;
            wrap-at-text-width = true;
            wrap-indicator = " ";
          };
          language-servers = [
            "marksman"
            "harper-ls"
            "typos"
          ];
        }
        {
          name = "bash";
          language-servers = [
            "bash-language-server"
            "typos"
          ];
        }
        {
          name = "yaml";
          language-servers = [
            "yaml-language-server"
            "typos"
          ];
        }
        {
          name = "dockerfile";
          language-servers = [
            "docker-langserver"
            "typos"
          ];
        }
        {
          name = "python";
          auto-format = true;
          formatter = {
            command = "ruff";
            args = [
              "format"
              "-"
            ];
          };
          language-servers = [
            "basedpyright"
            "ruff"
            "typos"
          ];
        }
      ];
    };
  };
}
