# Kintsugi, ported from the VS Code theme by ahatem (the author of
# IoskeleyMono, this flake's font). Upstream: github.com/ahatem/vscode-kintsugi
#
# This tracks `Kintsugi-Dark-Clay-Flared`, the warm-neutral cut. It is the
# variant the IoskeleyMono site itself is built in: that site's `--bg`
# (0c0c0c), `--text` (bcac8f), `--border` (2a2a28) and `--accent` (b8943a)
# are this theme's editor.background, editor.foreground, activityBar.border
# and activityBar.activeBorder respectively. Upstream also ships plain Dark,
# non-Flared cuts and a Light set, none of which are ported here.
#
# Clay differs from plain Dark Flared only in its neutrals, which carry a
# warm cast. Its `tokenColors` are identical, so the syntax block below is
# the same either way.
#
# Neutrals come from the theme's UI colours, picked by luminance so the
# bg0->bg3 and fg3->fg0 ramps land on shades upstream actually uses.
{ plib }:

let
  inherit (plib) saturate mix vividPush;

  colors = rec {
    # editor.background (the site's `--bg`), activityBar.background (the
    # workhorse chrome surface, used 23 times), activityBar.border (used 30
    # times, and the site's `--border`), list.dropBackground.
    bg0 = "0c0c0c";
    bg1 = "181714";
    bg2 = "2a2a28";
    bg3 = "3d3830";

    # Muted at-rest tint (niri inactive borders, walker, the lock ring at
    # rest). Built the same way the light variants build theirs: the
    # neutral step tinted toward the accent, rather than a hardcoded shade.
    mid = mix 0.25 bg2 red;

    # breadcrumb.foreground, badge.foreground, activityBar.foreground (also
    # terminal.foreground), editor.foreground (also button.foreground, and
    # the site's `--text`).
    fg3 = "75715e";
    fg2 = "8d8975";
    fg1 = "a9a088";
    fg0 = "bcac8f";

    # Upstream has no single shade sitting where gruvbox puts white/grey (a
    # slightly dimmed fg1), so derive them off the fg ramp instead of
    # inventing hexes. `white` keeps weight, `grey` recedes.
    white = mix 0.2 fg1 fg2;
    grey = mix 0.55 fg1 fg2;

    # Upstream's own ANSI 1-6. `orange` has no ANSI slot, so it holds the
    # signature Kintsugi gold (activityBar.activeBorder, editorCursor).
    red = "b38f8f";
    green = "a3be8c";
    yellow = "ebcb8b";
    orange = "dbad49";
    blue = "6c7a8a";
    pink = "b3a3d3";
    # Upstream's keyword.operator / support.* orange. It has no ANSI slot,
    # so it lives here as its own hue rather than displacing `orange`, which
    # holds the signature gold.
    amber = "E08542";

    # A deeper gold than `orange`. This theme's activityBar.activeBorder and
    # focusBorder, and the colour the IoskeleyMono site sets as its
    # `--accent`.
    goldDeep = "b8943a";
    # The site's `--accent-hover`. This is the one value in this file that is
    # not lifted from a Kintsugi theme: it appears in neither upstream file,
    # so it comes from the site's own stylesheet.
    goldDeepHover = "a07d2a";

    # Readable on light bg: the Light-Flared theme's ANSI set, which is
    # exactly that set of hues re-cut for cream. `orangeDark` takes the
    # light theme's editorWarning gold.
    redDark = "8a5050";
    greenDark = "5a8a40";
    yellowDark = "9a7820";
    orangeDark = "8a7830";
    blueDark = "5a6870";
    pinkDark = "785898";

    # Readable on dark bg: upstream's bright-ANSI set. Gold has no bright
    # slot, so `orangeLight` is the gold lifted toward fg0.
    redLight = "d9a6a6";
    greenLight = "c3de9c";
    yellowLight = "fbe4a8";
    orangeLight = mix 0.4 orange fg0;
    blueLight = "8fa3b3";
    pinkLight = "d3a3d3";

    # Vivid shades — base hues with each channel pushed ±vividPush from the
    # RGB mean. Same identity as the base accents, just saturated to pop.
    redVivid = saturate vividPush red;
    greenVivid = saturate vividPush green;
    yellowVivid = saturate vividPush yellow;
    orangeVivid = saturate vividPush orange;
    blueVivid = saturate vividPush blue;
    pinkVivid = saturate vividPush pink;

    # ---- Semantic roles ----------------------------------------------
    # Style with these, never with the hue names above. A hue name means a
    # different thing in each scheme (kintsugi's `red` is a rose, its `pink`
    # is a lilac), so styling that asks for "red" cannot carry intent across
    # palettes. The hue tokens stay because the terminal ANSI palette in
    # `modules/terminals/default.nix` genuinely needs 16 named hues.
    #
    # Accent ramp, most to least prominent.
    primary = orange; # dbad49, the signature kintsugi gold
    secondary = amber; # E08542, a true orange
    tertiary = red; # b38f8f, a rose

    # The pale gold sits outside the ramp, as the accent. It is the colour
    # the IoskeleyMono site leans on, and `border` follows it so focused
    # windows, panes and the launcher all read the same.
    accent = yellow; # ebcb8b, pale gold
    border = accent; # focused/active borders, in every surface
    neutral = mid; # at-rest borders and dividers
    # Deliberately not `tertiary`: that is an orange, and an error needs to
    # read as an error. `red` is upstream's ANSI red.
    urgent = red; # errors, urgent notifications
    failure = red; # failed states, error symbols
    success = green; # a3be8c, upstream's editorGutter.addedBackground
    warning = secondary; # caution, modified-but-not-broken
    info = blue; # informational accents
  };

  # Upstream's real syntax colours, lifted from each theme's `tokenColors`
  # and named by the scope each one actually paints. These drive `base16`
  # below and the helix theme, so an editor themed from this palette gets
  # Kintsugi's own highlighting rather than this flake's accents run through
  # a mapping built for gruvbox.
  #
  # They sit beside `dark`/`light` rather than inside them because consumers
  # such as `modules/desktop/eww.nix` stringify every attr of a variant, so a
  # variant has to stay a flat map of hex strings.
  syntax = {
    comment = "636363"; # comment
    variable = "BCAC8F"; # text, source, variable
    punctuation = "85806b"; # punctuation, delimiter, bracket, brace
    type = "798283"; # storage.type, entity.name.function/class
    keyword = "D66848"; # keyword
    storage = "DBAD49"; # storage, entity.name.tag, this/self, new
    string = "cc7f66"; # string
    operator = "E08542"; # keyword.operator, support.type/class/function
    number = "DB9833"; # constant.numeric
    annotation = "678E87"; # annotations, lifetimes, rust attributes
    pointer = "EBA96C"; # meta.ptr, meta.pointer, meta.array
    invalid = "b38f8f"; # invalid

    # Roles helix needs that upstream gives no direct scope. TODO tags
    # take the gold. Escapes take upstream's constant.character.escape.
    commentTodo = "DBAD49";
    escape = "798283";
    # Upstream font styles: comments plain, keywords and storage bold.
    commentModifiers = [ ];
    keywordModifiers = [ "bold" ];
  };

  # Merged over the shared mapping in palette.nix. Comments, strings,
  # keywords, functions, numbers and punctuation land on upstream's exact
  # values. The rest take the nearest upstream role.
  base16 = {
    base03 = syntax.comment;
    base05 = syntax.variable;
    base08 = syntax.operator;
    base09 = syntax.number;
    base0A = syntax.annotation;
    base0B = syntax.string;
    base0C = syntax.pointer;
    base0D = syntax.type;
    base0E = syntax.keyword;
    base0F = syntax.punctuation;
  };
in
{
  inherit
    colors
    syntax
    base16
    ;
}
