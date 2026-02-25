{ config, lib, ... }:

let
  cfg = config.dotfiles.theme;

  # Hex color math for deriving `*Vivid` accents from the base hues.
  hexChars = lib.stringToCharacters "0123456789abcdef";
  hexValues = builtins.listToAttrs (lib.imap0 (i: c: lib.nameValuePair c i) hexChars);
  toPair =
    n:
    let
      m =
        if n < 0 then
          0
        else if n > 255 then
          255
        else
          n;
    in
    (builtins.elemAt hexChars (m / 16)) + (builtins.elemAt hexChars (m - (m / 16) * 16));
  fromPair = s: 16 * hexValues.${builtins.substring 0 1 s} + hexValues.${builtins.substring 1 1 s};

  # Push each channel away from the RGB mean by ±k, so muted hues saturate
  # without changing their identity (red stays red, blue stays blue).
  saturate =
    k: hex:
    let
      r = fromPair (builtins.substring 0 2 hex);
      g = fromPair (builtins.substring 2 2 hex);
      b = fromPair (builtins.substring 4 2 hex);
      avg = (r + g + b) / 3;
      shift =
        ch:
        ch
        + (
          if ch > avg then
            k
          else if ch < avg then
            -k
          else
            0
        );
    in
    toPair (shift r) + toPair (shift g) + toPair (shift b);

  dark = rec {
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

    # Vivid shades — base hues with each channel pushed ±60 from the RGB
    # mean. Same identity as the base accents, just saturated to pop.
    redVivid = saturate 60 red;
    greenVivid = saturate 60 green;
    yellowVivid = saturate 60 yellow;
    orangeVivid = saturate 60 orange;
    blueVivid = saturate 60 blue;
    pinkVivid = saturate 60 pink;

    # Semantic aliases — UI roles mapped onto the base hues. Reach for
    # these over raw colors in consumer modules so re-skinning means
    # changing one line here, not every call site.
    accent = orange; # primary brand: prompts, headers, "active" UI
    border = red; # focused/active borders
    urgent = red; # errors, urgent notifications, error symbols
    success = green; # ok states, passing checks
    warning = orange; # caution, modified-but-not-broken
    failure = red; # failed states, error symbols
    info = blue; # informational accents
  };

  # Quick light variant: fg/bg ramps swapped, accents unchanged.
  # Accents will look washed against the cream bg — promote to a real
  # light theme by darkening accents ~30% if you decide to keep this.
  light = dark // {
    bg0 = "fbf1c7";
    bg1 = "ebdbb2";
    bg2 = "d5c4a1";
    bg3 = "bdae93";

    fg3 = "665c54";
    fg2 = "504945";
    fg1 = "3c3836";
    fg0 = "1c1c1c";
  };
in
{
  options.dotfiles.theme.variant = lib.mkOption {
    type = lib.types.enum [
      "dark"
      "light"
    ];
    default = "dark";
    description = ''
      Active color scheme variant. Modules should consume `colors` (which
      points at the active palette) and may also reference `colorsDark` /
      `colorsLight` directly when they need both available simultaneously.
    '';
  };

  config._module.args = {
    monoFont = "IoskeleyMono Nerd Font";

    border-style = {
      radius-float = 1.0;
      radius-int = 1;
      width = 2;
    };

    colors = if cfg.variant == "light" then light else dark;
    colorsDark = dark;
    colorsLight = light;
  };
}
