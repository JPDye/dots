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
# The fg3->fg0 ramp comes from the theme's UI colours, picked by luminance
# so it lands on shades upstream actually uses. The bg0->bg3 ramp does not:
# it is gruvbox's, from github.com/morhetz/gruvbox.
{ plib }:

let
  inherit (plib) mix;

  colors = rec {
    # The background ramp is gruvbox's, not Kintsugi's: `dark0_hard`,
    # `dark0`, `dark1` and `dark2` from github.com/morhetz/gruvbox. bg0 is
    # the default background for terminals, helix and every other surface.
    # Kintsugi's own neutrals (editor.foldBackground 1c1b17,
    # activityBar.border 2a2a28, list.dropBackground 3d3830) are no longer
    # read here. The foreground ramp below is still Kintsugi's own.
    bg0 = "1d2021"; # dark0_hard
    bg1 = "282828"; # dark0
    bg2 = "3c3836"; # dark1
    bg3 = "504945"; # dark2

    # A sunken background for bars: helix's and zellij's status lines. The
    # darkest shade in the theme (Clay's editorCursor.background), well
    # under bg0, so a bar reads as a separate surface rather than a tint of
    # the editor.
    bgSunken = "080807";

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

    # Named for the colour each one actually is, not for an ANSI slot. The
    # ANSI table lower down keeps upstream's own terminal values, so nothing
    # here has to compromise between the two: `red` is upstream's `keyword`
    # colour, `pink` its `string` colour, and `orange` its keyword.operator
    # colour, a true orange at hue 25.
    red = "D66848";
    green = "a3be8c";
    yellow = goldDeep;
    orange = "E08542";
    blue = "6c7a8a";
    pink = "cc7f66";

    # The pale gold. Upstream's ANSI yellow, and what it paints
    # editorWarning.foreground and gitDecoration.modified in. Named rather
    # than dropped when `yellow` moved down to goldDeep.
    paleGold = "ebcb8b";
    # The signature kintsugi gold, hue 41.
    gold = "dbad49";
    amber = orange; # alias, for styling that spells it that way

    # Descriptive aliases for the two hues above, kept so styling can spell
    # them either way. The warm ramp runs
    # yellow -> gold -> goldDeep -> orange -> salmon -> coral.
    coral = red;
    salmon = pink;

    # Warm surface ramp, `--w-1` to `--w-8` on the IoskeleyMono site. These
    # are site values, not Kintsugi theme values: the theme file has no such
    # ramp. They are the gold-tinted darks the site's `.os-pill` badge is
    # built from (background `warm2`, border `warm6`, text `goldDeep`).
    warm1 = "0e0c08";
    warm2 = "18150d";
    warm3 = "1a160d";
    warm4 = "201b12";
    warm5 = "2e2518";
    warm6 = "3d2e10";
    warm7 = "5a4418";
    warm8 = "6b5128";

    # A deeper gold than `gold`. This theme's activityBar.activeBorder and
    # focusBorder, and the colour the IoskeleyMono site sets as its
    # `--accent`.
    goldDeep = "b8943a";
    # The site's `--accent-hover`. This is the one value in this file that is
    # not lifted from a Kintsugi theme: it appears in neither upstream file,
    # so it comes from the site's own stylesheet.
    goldDeepHover = "a07d2a";

    # The hard seam colour every surface draws its shadow in: darker than
    # bg0, so a shadow reads as depth below the background rather than a
    # lighter seam above it. This is Clay's own editor.background, which sits
    # well clear of the bg ramp. niri's float rule, walker's CSS ring and
    # eww's boxes all read this, so the desktop has one shadow, not three
    # near-copies derived in three files.
    shadow = "0c0c0c";

    # Outline roles. A muted gold rule and its hover state, sitting well
    # below `border` in prominence. These are the site's
    # `--w-6` and `--w-7`, the shades its own bordered boxes use.
    borderMid = warm6;
    borderMidHover = warm7;

    # Gradient ramp. Consumers walk gradient1..gradient6 in order for a
    # sweep across the palette, without knowing which scheme is active.
    # The ordering is a deliberate choice per scheme, not a computed one:
    # tune it here and every consumer follows.
    gradient1 = red;
    gradient2 = orange;
    gradient3 = pink;
    gradient4 = yellow;
    gradient5 = green;
    gradient6 = blue;

    # ---- Semantic roles ----------------------------------------------
    # Style with these, never with the hue names above. A hue name means a
    # different thing in each scheme (kintsugi's `red` is a rose, its `pink`
    # is a lilac), so styling that asks for "red" cannot carry intent across
    # palettes. The hue tokens stay because the terminal ANSI palette in
    # `modules/terminals/default.nix` genuinely needs 16 named hues.
    #
    # Accent ramp, most to least prominent.
    primary = gold; # dbad49, the signature kintsugi gold
    secondary = orange; # E08542, a true orange
    tertiary = coral; # D66848, the theme's real red

    # `yellow` is goldDeep, which is what upstream itself outlines focus in
    # (its focusBorder and activityBar.activeBorder) and what the
    # IoskeleyMono site sets as its `--accent`.
    accent = yellow; # b8943a

    # Window, popup and login-screen outlines. Both states are cut from the
    # warm ramp, so focused and at-rest read as two steps of one colour
    # rather than two colours.
    #
    # At rest a window takes `warm7`, one rung above the `borderMid` rule
    # eww and helix draw their dividers in. An unfocused window has to stay
    # visible against bg0, and `warm6` sat too close to it. Focused, it
    # takes that same `warm7` lifted 40% of the way to the orange: bright
    # enough to mark focus, still on the ramp.
    #
    # eww's boxes deliberately do not follow `borderActive`. They sit a
    # register quieter, further down the same warm ramp, so a widget never
    # competes with the focused window. `border` stays as an alias for the
    # active one because several consumers still spell it that way.
    borderInactive = warm7; # 5a4418
    borderActive = mix 0.4 warm7 orange; # 905e29
    border = borderActive;
    neutral = mid; # at-rest borders and dividers
    urgent = coral; # errors, urgent notifications
    failure = coral; # failed states, error symbols
    success = green; # a3be8c, upstream's editorGutter.addedBackground
    warning = secondary; # caution, modified-but-not-broken
    info = blue; # informational accents

    # Hover steps. Every interactive role gets one, derived the same way in
    # both schemes so the relationship between a role and its hover is
    # identical whichever palette is active. Same pattern as
    # borderInactive -> borderActive above.
    #
    # The blend target is white, not fg0: this scheme's fg0 is a tan darker
    # than its pale gold accent, so mixing toward fg0 would *darken* a hover
    # rather than lift it.
    borderActiveHover = mix 0.25 borderActive "ffffff";
    accentHover = mix 0.25 accent "ffffff";
    primaryHover = mix 0.25 primary "ffffff";
    secondaryHover = mix 0.25 secondary "ffffff";
    tertiaryHover = mix 0.25 tertiary "ffffff";
    successHover = mix 0.25 success "ffffff";
    warningHover = mix 0.25 warning "ffffff";
    urgentHover = mix 0.25 urgent "ffffff";
    infoHover = mix 0.25 info "ffffff";

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
  # The terminal's 16 ANSI slots, taken from this theme's own terminal.ansi*
  # keys. They sit beside `colors` rather than inside it for the same reason
  # `syntax` does: consumers such as modules/desktop/eww.nix stringify every
  # attr of `colors`, so it has to stay a flat map.
  #
  # Keeping them here is what lets `red` and `pink` above be the theme's real
  # red and salmon. The ANSI red stays upstream's dusty rose, where it
  # belongs, instead of forcing the whole UI to use it.
  ansi = [
    "181714" # 0  black
    "b38f8f" # 1  red
    "a3be8c" # 2  green
    "ebcb8b" # 3  yellow
    "6c7a8a" # 4  blue
    "b3a3d3" # 5  magenta
    "6ac6f2" # 6  cyan
    "bcac8f" # 7  white
    "514e42" # 8  bright black
    "d9a6a6" # 9  bright red
    "c3de9c" # 10 bright green
    "fbe4a8" # 11 bright yellow
    "8fa3b3" # 12 bright blue
    "d3a3d3" # 13 bright magenta
    "8ac6f2" # 14 bright cyan
    "ffffff" # 15 bright white
  ];
in
{
  inherit
    colors
    syntax
    base16
    ansi
    ;
}
