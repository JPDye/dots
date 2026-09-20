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
            # The flake's own nixpkgs, not <nixpkgs>: no host sets a
            # NIX_PATH, so the angle-bracket lookup fails everywhere.
            # allowUnfree matches the flake, so hover on steam/slack/etc.
            # does not throw.
            nixpkgs.expr = ''import (builtins.getFlake "${inputs.self}").inputs.nixpkgs { config.allowUnfree = true; }'';
            # `hmOptions.${hostname}` resolves to the right HM option tree
            # whether this host is standalone-HM or NixOS-embedded — see the
            # `hmOptions` derivation in flake.nix.
            options.home-manager.expr = ''(builtins.getFlake "${inputs.self}").hmOptions.${hostname}'';
            # NixOS option tree for modules/system, hosts/, profiles/ and
            # installer/ files. Any NixOS host works as the source;
            # laptop-nix has the most modules enabled.
            options.nixos.expr = ''(builtins.getFlake "${inputs.self}").nixosConfigurations.laptop-nix.options'';
          };
        };

        # C. The toolchain is per-project, not global: the "Modern C" repo's
        # shell.nix puts a version-matched clang-tools on PATH through direnv,
        # and writes a compile_flags.txt that carries -std=c23. clangd reads
        # that file itself, so no -std flag belongs here. Helix already
        # defaults C to clangd, so this block only adds the arguments.
        clangd = {
          command = "clangd";
          args = [
            "--background-index"
            # Lint diagnostics inline, in the spirit of the clippy::pedantic
            # check configured for rust-analyzer above.
            "--clang-tidy"
            "--completion-style=detailed"
            # Do not add an #include on completion. Writing the includes by
            # hand is part of learning the language.
            "--header-insertion=never"
          ];
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

        # Code: locale "en" accepts both en-US/en-GB so American identifiers
        # (the `colors` variable, `mold`, `rust-analyzer`, ...) aren't flagged.
        typos = {
          command = "typos-lsp";
          config.config = toString (
            pkgs.writeText "typos.toml" ''
              [default]
              locale = "en"
            ''
          );
        };

        # Prose (markdown, plain text): enforce British spelling. Mirrors the
        # md/txt locale overrides in the repo-root typos.toml.
        typos-prose = {
          command = "typos-lsp";
          config.config = toString (
            pkgs.writeText "typos-prose.toml" ''
              [default]
              locale = "en-gb"
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
            "typos"
          ];
        }
        {
          name = "c";
          auto-format = true;
          formatter = {
            command = "clang-format";
            # `--style=file` uses the project's .clang-format when it has one
            # and falls back to LLVM style otherwise, which matches helix's
            # own C indent defaults (2 spaces). `--assume-filename` sets the
            # language, because clang-format reads the buffer on stdin and
            # would otherwise guess.
            args = [
              "--assume-filename=x.c"
              "--style=file"
              "--fallback-style=LLVM"
            ];
          };
          # Helix maps `.h` to cpp, not c (its languages.toml carries a
          # literal `# TODO: ["h"]` on the C entry), so a C header would open
          # with C++ semantics. Claim it for C here. Reverse this if a C++
          # project ever lands on one of these hosts.
          file-types = [
            "c"
            "h"
          ];
          # Root the workspace where the flags file is, so clangd reads it for
          # a source file in a subdirectory. Helix defines no roots for C.
          roots = [
            "compile_flags.txt"
            "compile_commands.json"
            "Makefile"
          ];
          language-servers = [
            "clangd"
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
            "typos-prose"
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
            "typos-prose"
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
