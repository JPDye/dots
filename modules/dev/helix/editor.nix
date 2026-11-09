{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  # The fork builds every grammar in its languages.toml (301) unless told
  # otherwise, and no cache holds the fork. Build only these. Names are
  # grammar names, which are not always language names: `gitcommit` serves
  # git-commit, `markdown_inline` serves markdown, `json` serves jsonc.
  # A file type whose grammar is missing still opens, with no highlighting.
  # `hx --health <lang>` shows which grammar a language needs.
  grammars = [
    # The languages in languages.nix.
    "bash"
    "c"
    "dockerfile"
    "gitcommit"
    "markdown"
    "markdown_inline"
    "nix"
    "python"
    "rust"
    "toml"
    "typst"
    "yaml"
    # Injected into the languages above.
    "comment"
    "diff"
    "regex"
    # Other files edited in this repo and in ~/Code.
    "cpp"
    "css"
    "git-config"
    "git-rebase"
    "gitattributes"
    "gitignore"
    "glsl"
    "go"
    "gomod"
    "html"
    "ini"
    "javascript"
    "json"
    "just"
    "kdl"
    "make"
    "nu"
    "scss"
    "sql"
    "xml"
  ];
in
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
      package = inputs.helix.packages.${pkgs.stdenv.hostPlatform.system}.default.override {
        includeGrammarIf = g: builtins.elem g.name grammars;
      };

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
        # themes.nix writes this one, standalone from the active scheme's
        # palette. No mkForce: stylix's helix target is off (see
        # theming/stylix.nix), so nothing else injects a theme name.
        theme = "dotfiles";

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
          # The fork turns bufferline into a table. Upstream takes the bare
          # string, `bufferline = "always"`, so a revert must change it back.
          bufferline.render-mode = "always";

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

          # Fork-only keys (gj1118/helix, see the helix input in flake.nix).
          # Upstream helix rejects unknown editor keys, so a revert to
          # upstream must also remove this block.
          breadcrumb.enable = true;
          cmdline.style = "popup";

          # Square, one-cell border, no drop shadow and no emoji or icon
          # prefix. The border colour is `ui.popup.border` in themes.nix.
          notifications = {
            show-emojis = false;
            show-icons = false;
            border = {
              width = 1;
              radius = 0;
            };
            shadow.enable = false;
          };

          # File locations, command history and search history persist in
          # ~/.local/state/helix. The internal clipboard stays off, so yanked
          # text never goes to disk.
          persistence = {
            old-files = true;
            commands = true;
            search = true;
          };

          # Reload a buffer that changed on disk, for example after an agent
          # edits it from another pane. The fork skips buffers with unsaved
          # changes. The periodic check (every 3 s) catches a change that
          # arrives with no focus event.
          auto-reload = {
            focus-gained = true;
            periodic.enable = true;
          };
        };
      };
    };
  };
}
