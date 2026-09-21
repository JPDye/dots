# The original palette of this flake: gruvbox-dark-ish, warm, low-saturation.
#
# Moved here when the scheme selector landed in palette.nix. Every value is
# unchanged from when it lived inline there.
{ plib }:

let
  inherit (plib) saturate vividPush;

  colors = rec {
    bg0 = "1c1c1c";
    bg1 = "3c3836";
    bg2 = "504945";
    bg3 = "665c54";

    mid = "463030";

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

    # Darker shades — readable on light bg (~AA-normal vs `fbf1c7`).
    # Saturation pushed up to ~60-70% so they read as colors rather than
    # tinted greys; lightness ~30% for AA-normal contrast on cream.
    redDark = "832020";
    greenDark = "5f5f15";
    yellowDark = "806715";
    orangeDark = "8a4513";
    blueDark = "1a6868";
    pinkDark = "8a4040";

    # Lighter shades — readable on dark bg (~AA-normal vs `1c1c1c`).
    # Saturation ~50-65%, lightness ~58-65% for vivid accents on near-black.
    redLight = "de6c6c";
    greenLight = "c4c049";
    yellowLight = "dac142";
    orangeLight = "de9858";
    blueLight = "4eb1b1";
    pinkLight = "de9b9b";

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
    # Accent ramp. These only name roles this palette already had, so no
    # colour changes: `accent` and `border` keep the values they had before
    # the semantic roles were introduced.
    primary = orange;
    secondary = red;
    tertiary = yellow;

    accent = orange; # prompts, headers, "active" UI
    border = red; # focused/active borders, in every surface
    neutral = mid; # at-rest borders and dividers
    urgent = red; # errors, urgent notifications
    failure = red; # failed states, error symbols
    success = green; # ok states, passing checks
    warning = orange; # caution, modified-but-not-broken
    info = blue; # informational accents
  };

  # The syntax roles `modules/dev/helix/themes.nix` consumes. These sit
  # beside `colors` rather than inside it on purpose: consumers such as
  # `modules/desktop/eww.nix` stringify every attr of `colors`, so it has to
  # stay a flat map of hex strings.
  #
  # Every value only names a colour this palette already gave that scope, so
  # the helix theme renders exactly as it did before the roles were named.
  syntax = {
    comment = colors.orangeVivid;
    commentTodo = colors.white;
    escape = colors.yellow;
    number = colors.pink;
    string = colors.pink;
    type = colors.blue;
    commentModifiers = [ "italic" ];
    keywordModifiers = [ ];
  };
in
{
  inherit colors syntax;
}
