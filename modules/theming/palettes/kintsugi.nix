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
# warm cast. Upstream's own `tokenColors` are not ported: the syntax block
# below follows this flake's shared mapping instead (see its comment).
#
# The fg3->fg0 ramp comes from the theme's UI colours, picked by luminance
# so it lands on shades upstream actually uses. The background ramp does not:
# bg0 to bg3 are gruvbox's, from github.com/morhetz/gruvbox.
{ plib }:

let
  inherit (plib) mix;

  colors = rec {
    # The whole background ramp is gruvbox's, from `dark0_hard` down to
    # `dark2` (github.com/morhetz/gruvbox). bg0 is the default background
    # for terminals, helix and every other surface. It is a cool near-black:
    # bgSunken below is the neutral one, and the pair is what separates a
    # bar from the editor. Kintsugi's own neutrals (editor.foldBackground
    # 1c1b17, activityBar.border 2a2a28, list.dropBackground 3d3830) are no
    # longer read here. The foreground ramp below is still Kintsugi's own.
    bg0 = "1d2021"; # dark0_hard
    bg1 = "282828"; # dark0
    bg2 = "3c3836"; # dark1
    bg3 = "504945"; # dark2

    # The fill for bars: helix's and zellij's status lines. Hand-picked, not
    # an upstream shade. It is a neutral near-black, and it sits close enough
    # to bg0 in lightness that a bar separates from the editor by hue rather
    # than by depth. WCAG relative luminance 0.0116 against bg0's 0.0140, a
    # contrast ratio of 1.04 to 1. The gruvbox scheme still derives a
    # genuinely darker shade for the same token, which is why the name says
    # sunken.
    bgSunken = "1c1c1c";

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
    # ANSI table lower down keeps upstream's own terminal values (red and
    # green excepted, see there), so nothing here has to compromise between the two: `red` is upstream's `keyword`
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
    # An unfocused window casts its seam a step lighter, so the focused
    # window sits deepest. niri reads this for inactive-color on tiled
    # windows and floats (niri/layout.nix, niri/window-rules.nix).
    shadowInactive = "0e0e0e";

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

  # Syntax roles, this scheme's own, built from the hue tokens above. They
  # pair with the `base16` block below: together those two decide what an
  # editor themed from this palette looks like, and neither touches
  # `palettes/gruvbox.nix`.
  #
  # The shape of it: the warm hues carry what you read most, and gold carries
  # the busiest scopes of all. Blue and green are kept to the scopes that
  # repeat least. An earlier cut of this file ported upstream Kintsugi's own
  # `tokenColors` instead, which put a blue-grey on every type, function and
  # member and a teal on every attribute, so most of an editor read blue.
  #
  # It sits beside `colors` rather than inside it because consumers such as
  # `modules/desktop/eww.nix` stringify every attr of `colors`, so that has
  # to stay a flat map of hex strings.
  syntax = {
    # A foreground shade, not a hue: a comment should recede, and fg3 is the
    # most muted rung of the ramp. It is what `hint` already reads.
    comment = colors.fg3;
    commentTodo = colors.gold;
    # Named types: `Vec`, `String`, `Duration`, `Status`.
    type = colors.blue;
    # `\n`, `\t`, `\u{1f}`. The plain foreground, so an escape stands out
    # of the green string it sits inside.
    escape = colors.fg0;
    # A call splits three ways. A free function and the path that reaches it
    # take orange (`process`, `std::time`), a method takes red (`iter`,
    # `from_secs`), and a macro takes pink (`println!`, `format!`).
    function = colors.orange;
    method = colors.red;
    macro = colors.pink;
    # `&`, `->`, `=`, `*`, `>`, `|`.
    operator = colors.orange;
    # Builtins and `special`: `i32`, `str`. Upstream calls this `storage`.
    storage = colors.blue;
    # Generic parameters: the `T` in `fn identity<T>`. The mid yellow, with
    # the keywords. `yellow` is goldDeep (b8943a), a rung under `gold`.
    generic = colors.yellow;
    number = colors.green;
    string = colors.green;
    # Plain text: bindings, parameters, fields.
    variable = colors.fg0;
    # Enum variants and struct expressions: `Status::Active`, `Foo { .. }`.
    # Helix tags the declaration `type.enum.variant` and every use
    # `constructor`, so both read this.
    constructor = colors.orange;
    punctuation = colors.fg2;
    # Rust attributes and lifetimes: `#[derive(Debug)]`.
    annotation = colors.green;
    commentModifiers = [ ];
    keywordModifiers = [ ];
    typeModifiers = [ ];
  };

  # Merged over the shared mapping in palette.nix, which stays as
  # `palettes/gruvbox.nix` wants it. Only the accent slots are overridden:
  # base00-07 keep coming from this scheme's own bg and fg ramps.
  #
  # `gold` is spelled out rather than `yellow` on purpose. This scheme has
  # both, and they differ: `gold` is dbad49, `yellow` is goldDeep at b8943a.
  # gruvbox aliases `gold` to its orange, which is exactly why this block is
  # here rather than in the shared mapping.
  base16 = {
    base03 = colors.fg3; # comments, invisibles, indent guides
    base05 = colors.fg0; # plain text
    base08 = colors.orange; # tags, diff.minus
    base09 = colors.gold; # constants, diff.delta
    base0A = colors.green; # markup.bold
    base0B = colors.green; # diff.plus
    base0C = colors.paleGold; # markup.raw, markup.quote
    base0D = colors.blue; # markup.heading.1
    base0E = colors.pink; # pub, impl, fn, let, enum, match
    base0F = colors.fg2; # punctuation
  };

  # The terminal's 16 ANSI slots, taken from this theme's own terminal.ansi*
  # keys. They sit beside `colors` rather than inside it for the same reason
  # `syntax` does: consumers such as modules/desktop/eww.nix stringify every
  # attr of `colors`, so it has to stay a flat map.
  #
  # Two pairs are not upstream's. Red (1, 9) takes the theme's real red,
  # because upstream's dusty rose (b38f8f, d9a6a6) reads as purple in cargo
  # and rustc errors, which use bright red. Green (2, 10) is darker and less
  # saturated than upstream's a3be8c and c3de9c, which glared in cargo's
  # bright-green "Compiling" lines.
  ansi = [
    "181714" # 0  black
    "d66848" # 1  red
    "879570" # 2  green
    "ebcb8b" # 3  yellow
    "6c7a8a" # 4  blue
    "b3a3d3" # 5  magenta
    "6ac6f2" # 6  cyan
    "bcac8f" # 7  white
    "514e42" # 8  bright black
    "e27d5e" # 9  bright red
    "9dab84" # 10 bright green
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
