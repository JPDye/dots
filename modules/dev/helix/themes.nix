{
  base16Scheme,
  colors,
  config,
  lib,
  syntax,
  ...
}:

let
  # Self-contained theme built from the active scheme's palette, with our
  # accent overrides layered on top. Defined standalone rather than inherited
  # from `stylix` so the scheme's own base16 mapping is what lands here.
  #
  # Most code scopes read a named role out of `syntax` rather than a base16
  # slot. The slots are a 16-colour ramp with its own conventions, and the
  # roles this theme wants do not line up with them: a scheme that paints
  # operators warm and variables plain cannot say so in base16 terms, because
  # base05 has to be both. The slots still carry what is genuinely ramp-like
  # (diffs, markup, UI chrome).
  theme = {
    attribute = "#${syntax.annotation}";
    comment = {
      fg = "#${syntax.comment}";
      modifiers = syntax.commentModifiers;
    };
    # Tags inside comments (TODO:, FIXME:, …). The scope exists only in our
    # runtime query override (comment-highlights.scm), not in upstream helix.
    "comment.todo".fg = "#${syntax.commentTodo}";
    constant = "#${syntax.number}";
    "constant.character.escape" = "#${syntax.escape}";
    "constant.numeric" = "#${syntax.number}";
    constructor = "#${syntax.constructor}";
    debug = "base03";
    diagnostic.modifiers = [ "underlined" ];
    "diff.delta" = "base09";
    "diff.minus" = "base08";
    "diff.plus" = "base0B";
    error = "#${colors.urgent}";
    function = "#${syntax.function}";
    "function.method" = "#${syntax.method}";
    "function.macro" = "#${syntax.macro}";
    hint = "#${colors.fg3}";
    info = "#${colors.info}";
    keyword = {
      fg = "base0E";
      modifiers = syntax.keywordModifiers;
    };
    label = "base0E";
    # `std`, `time` follow the call colour, not the type colour: in
    # `std::time::Duration` the path and the type it reaches then read as
    # two things rather than one run of blue.
    namespace = "#${syntax.function}";
    operator = "#${syntax.operator}";
    special = "#${syntax.storage}";
    string = "#${syntax.string}";
    tag = "base08";
    punctuation = "#${syntax.punctuation}";
    type = {
      fg = "#${syntax.type}";
      modifiers = syntax.typeModifiers;
    };
    "type.builtin" = "#${syntax.storage}";
    "type.parameter" = "#${syntax.generic}";
    "type.enum.variant" = "#${syntax.constructor}";
    variable = "#${syntax.variable}";
    "variable.other.member" = "#${syntax.variable}";
    warning = "#${colors.warning}";

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
      color = "#${colors.warning}";
      style = "curl";
    };
    "diagnostic.error".underline = {
      color = "#${colors.urgent}";
      style = "curl";
    };
    "diagnostic.info".underline = {
      color = "#${colors.info}";
      style = "curl";
    };
    "diagnostic.hint".underline = {
      color = "#${colors.fg3}";
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
    # The bar sits well under the editor surface rather than on a tint of
    # it: base01 was one step off base00 and indistinguishable, and the dim
    # gold rule read as an orange band.
    "ui.statusline" = {
      fg = "base04";
      bg = "#${colors.bgSunken}";
    };
    "ui.statusline.inactive" = {
      bg = "#${colors.bgSunken}";
      fg = "base03";
    };
    "ui.statusline.normal" = {
      fg = "#${colors.bg0}";
      bg = "#${colors.info}";
    };
    "ui.statusline.insert" = {
      fg = "#${colors.bg0}";
      bg = "#${colors.success}";
    };
    "ui.statusline.select" = {
      fg = "#${colors.bg0}";
      bg = "#${colors.secondary}";
    };
    "ui.text" = "base05";
    "ui.text.directory" = "base0D";
    "ui.text.focus" = "base05";
    "ui.virtual.indent-guide".fg = "base03";
    "ui.virtual.inlay-hint".fg = "base03";
    "ui.virtual.ruler".bg = "base01";
    "ui.virtual.jump-label" = {
      fg = "#${colors.tertiary}";
      modifiers = [ "bold" ];
    };
    "ui.virtual.whitespace".fg = "base03";
    # The rule between splits. base01 sits one step off base00, which is far
    # too close to see, so it takes the muted gold outline instead — the same
    # `borderMid` eww's pills use for their rule.
    "ui.window".bg = "#${colors.borderMid}";

    # Taken straight from the active scheme's base16 mapping (colors.nix
    # `mkScheme`) rather than rebuilt from raw accents. A scheme that ports
    # an existing editor theme overrides base03/base05 and base08-0F there
    # with upstream's real scope colours, and this block has to honour that
    # or every `base0X` reference above silently falls back to this flake's
    # own accents.
    palette = lib.mapAttrs (_: v: "#${v}") (
      lib.filterAttrs (n: _: lib.hasPrefix "base" n) base16Scheme
    );
  };
in
{
  config = lib.mkIf config.dotfiles.dev.helix.enable {
    # Named `dotfiles`, not `stylix`: stylix's own helix target is switched
    # off in theming/stylix.nix (see the comment there), so nothing else
    # writes a theme. `editor.nix` selects it by this name.
    programs.helix.themes.dotfiles = theme;

    # ~/.config/helix/runtime is helix's highest-priority runtime dir, so this
    # shadows the upstream comment query. See the header of the .scm file.
    xdg.configFile."helix/runtime/queries/comment/highlights.scm".source = ./comment-highlights.scm;
  };
}
