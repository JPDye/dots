{ config, lib, ... }:

let
  cfg = config.dotfiles.theme;

  dark = {
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
