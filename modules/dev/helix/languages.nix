{
  config,
  hostname,
  inputs,
  lib,
  pkgs,
  ...
}:

{
  config = lib.mkIf config.dotfiles.dev.helix.enable {
    programs.helix.languages = {
      language-server = {
        rust-analyzer.config = {
          cargo = {
            buildScripts.enable = true;
            allFeatures = true;
            targetDir = true;
          };
          procMacro.enable = true;
          check = {
            command = "clippy";
            extraArgs = [
              "--keep-going"
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
            options.home-manager.expr = ''(builtins.getFlake "${inputs.self}").homeConfigurations.${hostname}.options'';
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
          config."harper-ls".dialect = "British";
        };

        typos = {
          command = "typos-lsp";
          config.config = toString (
            pkgs.writeText "typos.toml" ''
              [default]
              locale = "en-gb"
            ''
          );
        };

        # Rust-only variant — accepts both en-gb and en-us spellings, since
        # crate APIs and upstream code mix the two.
        typos-rust = {
          command = "typos-lsp";
          config.config = toString (
            pkgs.writeText "typos-rust.toml" ''
              [default]
              locale = "en"
            ''
          );
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
            "typos-rust"
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
          name = "text";
          scope = "text.plain";
          file-types = [ "txt" ];
          roots = [ ];
          text-width = 100;
          soft-wrap = {
            enable = true;
            wrap-at-text-width = true;
            wrap-indicator = " ";
          };
          language-servers = [
            "harper-ls"
            "typos"
          ];
        }
        {
          name = "git-commit";
          text-width = 72;
          soft-wrap = {
            enable = true;
            wrap-at-text-width = true;
            wrap-indicator = " ";
          };
          language-servers = [
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
