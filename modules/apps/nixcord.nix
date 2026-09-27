{
  config,
  lib,
  pkgs,
  colors,
  monoFont,
  border-style,
  ...
}:

let
  cfg = config.dotfiles.apps.nixcord;
  c = colors;

  # system24 by refact0r: a TUI-style Discord theme (MIT). It sits on top of
  # midnight-discord, the same author's base theme (MIT). Both are pinned by
  # rev and hash and built into one local file below, so Vencord loads the
  # theme from disk and not from github.io at runtime. Only the asciid title
  # font still loads from github.io, from a @font-face inside system24.css.
  # If it cannot load, titles fall back to the mono font.
  #
  # To bump: `nix flake prefetch --json github:refact0r/<repo>` prints the
  # latest rev and its hash.
  system24 = pkgs.fetchFromGitHub {
    owner = "refact0r";
    repo = "system24";
    rev = "bd20dd462ec17f8c03961b5ac620b167a89f3189";
    hash = "sha256-5xPspSPa9jwDIv0DYc25d/gps8jNGqebj0RhVHto/7A=";
  };
  midnight = pkgs.fetchFromGitHub {
    owner = "refact0r";
    repo = "midnight-discord";
    rev = "85dd67148cbbbfa027cb091e41a479a16ab16a65";
    hash = "sha256-T0IVLbZGwc/+vxSR8PwJt2EDmrECphDAl7dPw6B17QM=";
  };

  # A system24 flavour is its upstream `body { ... }` option block plus a
  # `:root { ... }` colour block. The option block is taken verbatim from
  # upstream's theme file, so its defaults track a bump. The overrides and
  # every colour below come from the palette, so Discord follows `scheme`
  # in modules/theming/palette.nix like every other surface.
  overrides = ''
    body {
      --font: '${monoFont}';
      --code-font: '${monoFont}';
      font-weight: 400;
      --border-thickness: ${toString border-style.width}px;
    }

    :root {
      --colors: on;

      --text-0: #${c.bg0};
      --text-1: #${c.fg0};
      --text-2: #${c.fg0};
      --text-3: #${c.fg1};
      --text-4: #${c.fg3};
      --text-5: #${c.bg3};

      --bg-1: #${c.bg2};
      --bg-2: #${c.bg1};
      --bg-3: #${c.bgSunken};
      --bg-4: #${c.bg0};
      --hover: #${c.bg1};
      --active: #${c.bg2};
      --active-2: #${c.bg3};
      --message-hover: var(--hover);

      /* Spotify's accent token, so links and accent buttons match it. */
      --accent-1: #${c.accent};
      --accent-2: #${c.accent};
      --accent-3: #${c.accent};
      --accent-4: color-mix(in oklch, #${c.accent}, #${c.fg0} 20%);
      --accent-5: color-mix(in oklch, #${c.accent}, #${c.bg0} 25%);
      --accent-new: #${c.urgent};
      --mention: linear-gradient(to right, color-mix(in hsl, var(--accent-2), transparent 90%) 40%, transparent);
      --mention-hover: linear-gradient(to right, color-mix(in hsl, var(--accent-2), transparent 95%) 40%, transparent);
      --reply: linear-gradient(to right, color-mix(in hsl, var(--text-3), transparent 90%) 40%, transparent);
      --reply-hover: linear-gradient(to right, color-mix(in hsl, var(--text-3), transparent 95%) 40%, transparent);

      --online: #${c.success};
      --dnd: #${c.urgent};
      --idle: #${c.warning};
      --streaming: #${c.pink};
      --offline: var(--text-4);

      /* Panel borders as Spotify draws them (modules/apps/spicetify.nix):
         the neutral bg2 grey at rest, borderActive on the panel under the
         pointer, which is how system24 marks the active panel. */
      --border-light: #${c.bg1};
      --border: #${c.bg2};
      --border-hover: #${c.borderActive};
      --button-border: #${c.bg2};

      --red-1: #${c.red};
      --red-2: #${c.red};
      --red-3: #${c.red};
      --red-4: color-mix(in oklch, #${c.red}, #${c.bg0} 25%);
      --red-5: color-mix(in oklch, #${c.red}, #${c.bg0} 60%);

      --green-1: #${c.green};
      --green-2: #${c.green};
      --green-3: #${c.green};
      --green-4: color-mix(in oklch, #${c.green}, #${c.bg0} 25%);
      --green-5: color-mix(in oklch, #${c.green}, #${c.bg0} 60%);

      --blue-1: #${c.blue};
      --blue-2: #${c.blue};
      --blue-3: #${c.blue};
      --blue-4: color-mix(in oklch, #${c.blue}, #${c.bg0} 25%);
      --blue-5: color-mix(in oklch, #${c.blue}, #${c.bg0} 60%);

      --yellow-1: #${c.yellow};
      --yellow-2: #${c.yellow};
      --yellow-3: #${c.yellow};
      --yellow-4: color-mix(in oklch, #${c.yellow}, #${c.bg0} 25%);
      --yellow-5: color-mix(in oklch, #${c.yellow}, #${c.bg0} 60%);

      --purple-1: #${c.pink};
      --purple-2: #${c.pink};
      --purple-3: #${c.pink};
      --purple-4: color-mix(in oklch, #${c.pink}, #${c.bg0} 25%);
      --purple-5: color-mix(in oklch, #${c.pink}, #${c.bg0} 60%);
    }
  '';

  # One file: midnight's build, then system24's build, then the flavour.
  # Every upstream @import is removed. An @import must come before every
  # other rule, so the inlined bases cannot keep theirs. The two left are
  # Google Fonts loads for Figtree and DM Mono, which the mono font above
  # replaces. The build fails if an unexpected @import survives.
  theme = pkgs.runCommand "system24-dotfiles.css" { } ''
    {
      echo "/* system24 (refact0r, MIT) on midnight-discord (refact0r, MIT), built by modules/apps/nixcord.nix */"
      grep -v '^@import' ${midnight}/build/midnight.css
      grep -v '^@import' ${system24}/build/system24.css
      awk '/^body \{/,/^\}/' ${system24}/theme/system24.theme.css
      cat ${pkgs.writeText "system24-overrides.css" overrides}
    } > $out
    if grep -q '@import' $out; then
      echo "system24-dotfiles.css: an @import survived. Upstream changed its build files." >&2
      exit 1
    fi
    grep -q -- '--ascii-titles' $out || {
      echo "system24-dotfiles.css: the upstream body option block is missing." >&2
      exit 1
    }
  '';
in
{
  options.dotfiles.apps.nixcord.enable = lib.mkEnableOption "discord (via nixcord)" // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
    programs.nixcord = {
      enable = true;

      # Use Vesktop instead of the official Discord binary: nixpkgs' discord
      # package is broken (its installPhase brotli-decodes the main app, but
      # Discord now ships it as a gzip tarball → "corrupt input"/tar failure).
      # Vesktop is a standalone Electron client that dodges that path entirely,
      # and Vencord config + stylix theming below apply to it unchanged.
      discord.enable = false;
      vesktop.enable = true;

      # nixcord installs this as themes/system24-dotfiles.css.
      config = {
        themes.system24-dotfiles = theme;
        enabledThemes = [ "system24-dotfiles.css" ];
      };
    };
  };
}
