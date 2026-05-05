{
  colorsDark,
  colorsLight,
  config,
  hostname,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.dotfiles.dev.helix;

  # Self-contained theme based on the stylix-generated helix theme,
  # with our accent overrides layered on top. Defining both standalone
  # (rather than inheriting from `stylix`) means each variant renders
  # correctly regardless of the system polarity.
  mkTheme = palette: {
    attribute = "base09";
    comment = {
      fg = "base03";
      modifiers = [ "italic" ];
    };
    constant = "base09";
    "constant.character.escape" = "#${palette.yellow}";
    "constant.numeric" = "#${palette.pink}";
    constructor = "base0D";
    debug = "base03";
    diagnostic.modifiers = [ "underlined" ];
    "diff.delta" = "base09";
    "diff.minus" = "base08";
    "diff.plus" = "base0B";
    error = "#${palette.red}";
    function = "base0D";
    hint = "#${palette.fg3}";
    info = "#${palette.blue}";
    keyword = "base0E";
    label = "base0E";
    namespace = "base0E";
    operator = "base05";
    special = "base0D";
    string = "#${palette.pink}";
    tag = "base08";
    type = "#${palette.blue}";
    variable = "base08";
    "variable.other.member" = "base0D";
    warning = "#${palette.orange}";

    "markup.bold" = {
      fg = "base0A";
      modifiers = [ "bold" ];
    };
    "markup.heading.1" = {
      fg = "base0D";
      modifiers = [ "bold" ];
    };
    "markup.heading.2" = {
      fg = "base08";
      modifiers = [ "bold" ];
    };
    "markup.heading.3" = {
      fg = "base09";
      modifiers = [ "bold" ];
    };
    "markup.heading.4" = {
      fg = "base0A";
      modifiers = [ "bold" ];
    };
    "markup.heading.5" = {
      fg = "base0B";
      modifiers = [ "bold" ];
    };
    "markup.heading.6" = {
      fg = "base0C";
      modifiers = [ "bold" ];
    };
    "markup.italic" = {
      fg = "base0E";
      modifiers = [ "italic" ];
    };
    "markup.link.text" = "base08";
    "markup.link.url" = {
      fg = "base09";
      modifiers = [ "underlined" ];
    };
    "markup.list" = "base08";
    "markup.quote" = "base0C";
    "markup.raw" = "base0B";
    "markup.strikethrough".modifiers = [ "crossed_out" ];

    "diagnostic.warning".underline = {
      color = "#${palette.orange}";
      style = "curl";
    };
    "diagnostic.error".underline = {
      color = "#${palette.red}";
      style = "curl";
    };
    "diagnostic.info".underline = {
      color = "#${palette.blue}";
      style = "curl";
    };
    "diagnostic.hint".underline = {
      color = "#${palette.fg3}";
      style = "curl";
    };

    "ui.background".bg = "base00";
    "ui.bufferline" = {
      fg = "base04";
      bg = "base00";
    };
    "ui.bufferline.active" = {
      fg = "base00";
      bg = "base03";
      modifiers = [ "bold" ];
    };
    "ui.cursor" = {
      fg = "base06";
      modifiers = [ "reversed" ];
    };
    "ui.cursor.primary" = {
      fg = "base05";
      modifiers = [ "reversed" ];
    };
    "ui.cursorline.primary" = {
      fg = "base05";
      bg = "base01";
    };
    "ui.cursor.match" = {
      fg = "base05";
      bg = "base02";
      modifiers = [ "bold" ];
    };
    "ui.cursor.select" = {
      fg = "base05";
      modifiers = [ "reversed" ];
    };
    "ui.gutter".bg = "base00";
    "ui.help" = {
      fg = "base06";
      bg = "base01";
    };
    "ui.linenr" = {
      fg = "base03";
      bg = "base00";
    };
    "ui.linenr.selected" = {
      fg = "base04";
      bg = "base01";
      modifiers = [ "bold" ];
    };
    "ui.menu" = {
      fg = "base05";
      bg = "base01";
    };
    "ui.menu.scroll" = {
      fg = "base03";
      bg = "base01";
    };
    "ui.menu.selected" = {
      fg = "base01";
      bg = "base04";
    };
    "ui.popup".bg = "base01";
    "ui.selection".bg = "base02";
    "ui.selection.primary".bg = "base02";
    "ui.statusline" = {
      fg = "base04";
      bg = "base01";
    };
    "ui.statusline.inactive" = {
      bg = "base01";
      fg = "base03";
    };
    "ui.statusline.normal" = {
      fg = "#${palette.bg0}";
      bg = "#${palette.green}";
    };
    "ui.statusline.insert" = {
      fg = "#${palette.bg0}";
      bg = "#${palette.red}";
    };
    "ui.statusline.select" = {
      fg = "#${palette.bg0}";
      bg = "#${palette.pink}";
    };
    "ui.text" = "base05";
    "ui.text.directory" = "base0D";
    "ui.text.focus" = "base05";
    "ui.virtual.indent-guide".fg = "base03";
    "ui.virtual.inlay-hint".fg = "base03";
    "ui.virtual.ruler".bg = "base01";
    "ui.virtual.jump-label" = {
      fg = "#${palette.yellow}";
      modifiers = [ "bold" ];
    };
    "ui.virtual.whitespace".fg = "base03";
    "ui.window".bg = "base01";

    palette = {
      base00 = "#${palette.bg0}";
      base01 = "#${palette.bg1}";
      base02 = "#${palette.bg2}";
      base03 = "#${palette.bg3}";
      base04 = "#${palette.fg3}";
      base05 = "#${palette.fg1}";
      base06 = "#${palette.fg1}";
      base07 = "#${palette.fg0}";
      base08 = "#${palette.orange}";
      base09 = "#${palette.yellow}";
      base0A = "#${palette.pink}";
      base0B = "#${palette.green}";
      base0C = "#${palette.orange}";
      base0D = "#${palette.green}";
      base0E = "#${palette.red}";
      base0F = "#${palette.fg2}";
    };
  };

  # Wraps mkTheme with a layer that swaps syntax-foreground colors and the
  # base16 accent slots (base08–base0E) for an alternate set of accents.
  # Bg/fg ramps and statusline backgrounds keep the original palette.
  # Pass `accents = { red = ...; green = ...; yellow = ...; orange = ...;
  # blue = ...; pink = ...; }` to override.
  mkAccentTheme =
    {
      palette,
      accents,
    }:
    lib.recursiveUpdate (mkTheme palette) {
      "constant.character.escape" = "#${accents.yellow}";
      "constant.numeric" = "#${accents.pink}";
      error = "#${accents.red}";
      info = "#${accents.blue}";
      string = "#${accents.pink}";
      type = "#${accents.blue}";
      warning = "#${accents.orange}";

      "ui.virtual.jump-label".fg = "#${accents.yellow}";

      "diagnostic.warning".underline.color = "#${accents.orange}";
      "diagnostic.error".underline.color = "#${accents.red}";
      "diagnostic.info".underline.color = "#${accents.blue}";

      palette = {
        base08 = "#${accents.orange}";
        base09 = "#${accents.yellow}";
        base0A = "#${accents.pink}";
        base0B = "#${accents.green}";
        base0C = "#${accents.orange}";
        base0D = "#${accents.green}";
        base0E = "#${accents.red}";
      };
    };
in
{
  options.dotfiles.dev.helix.enable = lib.mkEnableOption "helix editor" // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
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

      themes = {
        stylix-jumps-dark = mkTheme colorsDark;
        stylix-jumps-light = mkTheme colorsLight;

        # Dark bg, all syntax accents promoted to *Light shades.
        # Statusline/borders keep the muted mid-tones.
        stylix-jumps-pop = mkAccentTheme {
          palette = colorsDark;
          accents = {
            red = colorsDark.redLight;
            green = colorsDark.greenLight;
            yellow = colorsDark.yellowLight;
            orange = colorsDark.orangeLight;
            blue = colorsDark.blueLight;
            pink = colorsDark.pinkLight;
          };
        };

        # Light bg, all syntax accents pulled down to *Dark shades.
        # High-contrast on cream — gruvbox-light-hard feel.
        stylix-jumps-deep = mkAccentTheme {
          palette = colorsLight;
          accents = {
            red = colorsLight.redDark;
            green = colorsLight.greenDark;
            yellow = colorsLight.yellowDark;
            orange = colorsLight.orangeDark;
            blue = colorsLight.blueDark;
            pink = colorsLight.pinkDark;
          };
        };

        # Dark bg, tiered. Loud channels (red/orange/blue → keywords, errors,
        # warnings, types, info) get *Light; quiet channels (green/pink/yellow
        # → strings, numerics, escapes, functions) keep the muted mid-tones.
        stylix-jumps-mixed = mkAccentTheme {
          palette = colorsDark;
          accents = {
            red = colorsDark.redLight;
            orange = colorsDark.orangeLight;
            blue = colorsDark.blueLight;
            inherit (colorsDark) green pink yellow;
          };
        };
      };

      settings = {
        theme = lib.mkForce "stylix-jumps-${config.dotfiles.theme.variant}";

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

      languages = {
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
  };
}
