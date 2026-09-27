# The original palette of this flake: gruvbox-dark-ish, warm, low-saturation.
#
# Moved here when the scheme selector landed in palette.nix. Every value is
# unchanged from when it lived inline there.
{ plib }:

let
  inherit (plib) mix;

  colors = rec {
    bg0 = "1c1c1c";
    bg1 = "3c3836";
    bg2 = "504945";
    bg3 = "665c54";

    mid = "463030";

    # A sunken background for bars, the counterpart of the kintsugi scheme's.
    # This palette has no such shade of its own, so it is bg0 taken most of
    # the way to black.
    bgSunken = mix 0.6 bg0 "000000";

    fg3 = "bdae93";
    fg2 = "d5c4a1";
    fg1 = "ebdbb2";
    fg0 = "fbf1c7";

    white = "D0D0BA";
    grey = "c8c2b8";

    red = "af5f5f";
    green = "87875f";
    yellow = "a8a05f";
    orange = "af875f";
    blue = "5f8787";
    pink = "b78f8f";

    # The kintsugi scheme names five warm hues this palette had no word for.
    # They are mapped here onto its nearest existing equivalents so styling
    # may reference them under either scheme. `goldDeep` in particular is
    # consumed by eww/eww.scss.
    gold = orange;
    paleGold = yellow;
    amber = orange;
    coral = red;
    salmon = pink;
    goldDeep = mix 0.25 orange bg0;
    goldDeepHover = mix 0.40 orange bg0;

    # Warm surface ramp, the counterpart of the kintsugi scheme's. This
    # palette has no such ramp upstream, so the eight steps are mixes of its
    # own bg0 toward orange, spaced to match the other scheme's luminance
    # progression. Consumers (eww) can rely on warm1..warm8 either way.
    warm1 = mix 0.03 bg0 orange;
    warm2 = mix 0.08 bg0 orange;
    warm3 = mix 0.10 bg0 orange;
    warm4 = mix 0.14 bg0 orange;
    warm5 = mix 0.20 bg0 orange;
    warm6 = mix 0.30 bg0 orange;
    warm7 = mix 0.45 bg0 orange;
    warm8 = mix 0.58 bg0 orange;

    # The hard seam colour every surface draws its shadow in: a quarter-step
    # up the bg0->bg1 ramp, opaque. niri's float rule, walker's CSS ring and
    # eww's boxes all read this, so the desktop has one shadow, not three
    # near-copies derived in three files.
    shadow = mix 0.25 bg0 bg1;
    # An unfocused window casts its seam a step lighter, so the focused
    # window sits deepest. niri reads this for inactive-color on tiled
    # windows and floats (niri/layout.nix, niri/window-rules.nix).
    shadowInactive = mix 0.30 bg0 bg1;

    # Outline roles. A muted rule and its hover state, sitting well below
    # `border` in prominence. Same two steps of the warm ramp the kintsugi
    # scheme uses, so a consumer gets the same relationship either way.
    borderMid = warm6;
    borderMidHover = warm7;

    # Gradient ramp. Consumers walk gradient1..gradient6 in order for a
    # sweep across the palette, without knowing which scheme is active.
    # The ordering is a deliberate choice per scheme, not a computed one:
    # tune it here and every consumer follows.
    gradient1 = red;
    gradient2 = pink;
    gradient3 = orange;
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
    # Accent ramp. These only name roles this palette already had, so no
    # colour changes: `accent` and `border` keep the values they had before
    # the semantic roles were introduced.
    primary = orange;
    secondary = red;
    tertiary = yellow;

    accent = orange; # prompts, headers, "active" UI

    # The same two roles the kintsugi scheme names, mapped onto the values
    # this palette already used, so nothing changes visually here.
    borderInactive = mid;
    borderActive = red;
    border = borderActive;
    neutral = mid; # at-rest borders and dividers
    urgent = red; # errors, urgent notifications
    failure = red; # failed states, error symbols
    success = green; # ok states, passing checks
    warning = orange; # caution, modified-but-not-broken
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

  # The syntax roles `modules/dev/helix/themes.nix` consumes. These sit
  # beside `colors` rather than inside it on purpose: consumers such as
  # `modules/desktop/eww.nix` stringify every attr of `colors`, so it has to
  # stay a flat map of hex strings.
  #
  # Every value only names a colour this palette already gave that scope, so
  # the helix theme renders exactly as it did before the roles were named.
  syntax = {
    comment = colors.green;
    commentTodo = colors.white;
    escape = colors.yellow;
    # The green base0D used to paint, kept as an explicit hue now that the
    # helix theme reads `function` from here rather than from a base16 slot.
    function = colors.green;
    number = colors.pink;
    string = colors.pink;
    type = colors.blue;
    commentModifiers = [ "italic" ];
    keywordModifiers = [ ];
    typeModifiers = [ ];
    # The roles the helix theme grew when it stopped reading these scopes off
    # base16 slots. Each keeps the value its old slot gave it here: base05 for
    # text and operators, base0F punctuation, base09 storage, base0A markup.
    storage = colors.yellow;
    generic = colors.yellow;
    macro = colors.yellow;
    method = colors.green;
    variable = colors.fg1;
    constructor = colors.fg1;
    operator = colors.fg1;
    punctuation = colors.fg2;
    annotation = colors.pink;
  };
  # The terminal's 16 ANSI slots. These reproduce the mapping that used to
  # live in modules/terminals/default.nix verbatim, including its deliberate
  # remaps (yellow -> orange, cyan -> blue, magenta -> pink), so the terminal
  # renders exactly as it did before the table moved into the schemes.
  ansi = [
    colors.bg0 # 0  black
    colors.red # 1  red
    colors.green # 2  green
    colors.orange # 3  yellow  -> orange
    colors.blue # 4  blue
    colors.pink # 5  magenta -> pink
    colors.blue # 6  cyan    -> blue
    colors.fg2 # 7  white
    colors.bg3 # 8  bright black
    colors.red # 9  bright red
    colors.green # 10 bright green
    colors.orange # 11 bright yellow  -> orange
    colors.blue # 12 bright blue
    colors.pink # 13 bright magenta -> pink
    colors.blue # 14 bright cyan    -> blue
    colors.fg0 # 15 bright white
  ];
in
{
  inherit colors syntax ansi;
}
