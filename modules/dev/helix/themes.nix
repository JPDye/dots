{
  colorsDark,
  colorsLight,
  config,
  lib,
  ...
}:

let
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
      bg = "#${palette.info}";
    };
    "ui.statusline.insert" = {
      fg = "#${palette.bg0}";
      bg = "#${palette.success}";
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
  config = lib.mkIf config.dotfiles.dev.helix.enable {
    programs.helix.themes = {
      stylix-jumps-dark = mkTheme colorsDark;

      # Light bg, all syntax accents pulled down to *Dark shades.
      # High-contrast on cream — gruvbox-light-hard feel.
      stylix-jumps-light = mkAccentTheme {
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

      # Light bg, accents saturated via the `*Vivid` ramp. Brighter and
      # punchier than `-light`; some accents (yellow, green) trade AA
      # contrast on cream for vibrancy.
      stylix-jumps-vivid = mkAccentTheme {
        palette = colorsLight;
        accents = {
          red = colorsLight.redVivid;
          green = colorsLight.greenVivid;
          yellow = colorsLight.yellowVivid;
          orange = colorsLight.orangeVivid;
          blue = colorsLight.blueVivid;
          pink = colorsLight.pinkVivid;
        };
      };
    };
  };
}
