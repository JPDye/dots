{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

{
  config = lib.mkIf config.dotfiles.dev.helix.enable {
    # Global ignore for helix file-picker / global search — applied even
    # outside git repos. Patterns are .gitignore syntax.
    xdg.configFile."helix/ignore".text = ''
      target/
      node_modules/
      .direnv/
      .venv/
      __pycache__/
      *.pyc
      dist/
      build/
      .next/
      .cache/
    '';

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

      settings = {
        # Pinned to the dark variant regardless of the system polarity
        # (dotfiles.theme.variant); mkForce overrides the theme stylix injects.
        # stylix-light is still defined (themes.nix) for runtime `:theme`.
        theme = lib.mkForce "stylix-dark";

        keys = {
          normal = {
            C-v = ":toggle lsp.display-inlay-hints";
            ret = "goto_word";

            # Silence / restore typos-lsp spelling diagnostics on demand,
            # without touching rust-analyzer/nixd/etc. typos attaches as
            # `typos` on code and `typos-prose` (en-gb) on markdown/text —
            # listing both makes the binds work in any buffer (unmatched names
            # are ignored). Helix has no per-server toggle, so silence and
            # restore are separate keys. Ctrl+q is freed for this in niri
            # (binds.nix) and zellij (zellij.nix); still gated at commit by the
            # typos pre-commit hook.
            C-q = ":lsp-stop typos typos-prose"; # silence typos
            C-S-q = ":lsp-restart typos typos-prose"; # restore typos
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

          completion-replace = true;
          completion-trigger-len = 2;
          idle-timeout = 50;

          trim-trailing-whitespace = true;
          insert-final-newline = true;

          color-modes = true;

          # Enable soft-wrap globally (wraps at viewport edge for code).
          # Per-language overrides (typst, markdown) still win and wrap at
          # text-width = 100 via wrap-at-text-width = true.
          soft-wrap = {
            enable = true;
            wrap-indicator = " ";
          };

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
    };
  };
}
