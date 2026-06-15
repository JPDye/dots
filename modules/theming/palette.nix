# Single source of truth for every theme token in this flake.
#
# This is a plain function, not a module, on purpose. NixOS system modules
# cannot see home-manager's `_module.args`, so the surfaces that need theme
# tokens on *both* sides (the greeter, fontconfig) import this file directly
# instead of hardcoding a copy behind a "keep in sync" comment.
#
# To change the theme, edit `variant` below. Nothing else needs to change.
{ lib }:

let
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

  # "rrggbb" -> "R;G;B" (decimal), for truecolor escape sequences such as
  # fastfetch's `{#38;2;R;G;B}`. Exposed to consumer modules via `themeLib`.
  rgbDec =
    hex:
    let
      h = lib.toLower hex;
    in
    lib.concatMapStringsSep ";" (i: toString (fromPair (builtins.substring (2 * i) 2 h))) [
      0
      1
      2
    ];

  # "rrggbb" -> "R, G, B", for CSS `rgba(R, G, B, a)`. GTK3 CSS (the greeter)
  # has no reliable 8-digit-hex support, so alpha has to go through rgba().
  rgbCss = hex: builtins.replaceStrings [ ";" ] [ ", " ] (rgbDec hex);

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

  # Per-channel linear blend of two "rrggbb" colors; t=0 -> a, t=1 -> b.
  # For in-between shades the palette ramps don't have (e.g. the floating
  # window shadow sits halfway between bg0 and bg1). Exposed via themeLib.
  mix =
    t: a: b:
    let
      la = lib.toLower a;
      lb = lib.toLower b;
      ch =
        i:
        let
          ca = fromPair (builtins.substring (2 * i) 2 la);
          cb = fromPair (builtins.substring (2 * i) 2 lb);
        in
        toPair (ca + builtins.floor (t * (cb - ca) + 0.5));
    in
    ch 0 + ch 1 + ch 2;

  # Append an 8-bit alpha channel to an "rrggbb" color -> "rrggbbaa", for the
  # niri (#rrggbbaa) and hyprlock (rgba(rrggbbaa)) shadow colors. opacity 0..1.
  alpha = opacity: hex: hex + toPair (builtins.floor (opacity * 255 + 0.5));

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

  # Light variant: the dark theme reflected, not a second theme. Every value
  # below is derived from `dark`, so the two variants stay one design.
  #
  # The semantic roles are re-derived here (in a `rec`) because the dark set
  # bound them to dark's accents, so `dark // { red = …; }` alone would not
  # update `border`/`accent`/etc. The `*Light`/`*Vivid` ramps stay inherited
  # from `dark`: they exist to pop against near-black and nothing on the
  # light side consumes them.
  light = dark // rec {
    # Neutrals: dark's own two ramps with the ends swapped. Dark reads dark
    # paper / warm ink, so light reads warm paper / dark ink using the same
    # greys — no new hues enter the theme.
    bg0 = dark.fg0; # fbf1c7
    bg1 = dark.fg1; # ebdbb2
    bg2 = dark.fg2; # d5c4a1
    bg3 = dark.fg3; # bdae93

    fg3 = dark.bg3; # 665c54
    fg2 = dark.bg2; # 504945
    fg1 = dark.bg1; # 3c3836
    fg0 = dark.bg0; # 1c1c1c

    # dark's white/grey sit just under fg1, a slightly dimmed foreground.
    # Mirror that position on the light fg ramp: `white` lands near fg2 so it
    # still carries weight, `grey` rides up toward fg3 so it still recedes.
    white = mix 0.2 fg2 fg3;
    grey = mix 0.55 fg2 fg3;

    # Accents: the `*Dark` ramp, which is the dark accents re-cut for a light
    # background — same hue identity, lightness dropped to clear AA-normal on
    # `bg0`, saturation raised to compensate (a 30%-saturated hue reads as
    # tinted grey once it is this dark).
    red = dark.redDark;
    green = dark.greenDark;
    yellow = dark.yellowDark;
    orange = dark.orangeDark;
    blue = dark.blueDark;
    pink = dark.pinkDark;

    # Muted at-rest tint (niri inactive borders, walker, the lock ring at
    # rest). dark's `463030` is its own bg tinted red, so mirror that
    # construction on cream rather than reusing a dark maroon.
    mid = mix 0.18 bg2 red;

    accent = orange;
    border = red;
    urgent = red;
    success = green;
    warning = orange;
    failure = red;
    info = blue;
  };
in
rec {
  # The active variant. This is the theme switch: every surface follows it,
  # on both the home-manager and the NixOS side.
  variant = "dark";

  inherit dark light;

  colors = if variant == "light" then light else dark;

  # The base16 scheme stylix consumes, built straight from a palette. stylix
  # takes an attrset here, so no upstream yaml sits underneath this theme and
  # no `stylix.override` is needed to paint over one.
  #
  # The base08-0F mapping is a deliberate syntax-highlight choice, not the
  # base16 default: base08 is the theme's orange (self, fields, variables),
  # base0D its green (calls, methods), base0E its red (keywords). Helix
  # repeats this mapping in `modules/dev/helix/themes.nix`.
  mkScheme =
    name:
    let
      c = if name == "light" then light else dark;
    in
    {
      scheme = "dotfiles";
      author = "jd";
      slug = "dotfiles-${name}";
      variant = name;

      base00 = c.bg0;
      base01 = c.bg1;
      base02 = c.bg2;
      base03 = c.bg3;
      base04 = c.fg3;
      base05 = c.fg1; # ::<>, ()
      base06 = c.fg1;
      base07 = c.fg0;

      base08 = c.orange; # self, fields, variables
      base09 = c.yellow; # ints, booleans, constants
      base0A = c.pink; # HashMap<String, String>
      base0B = c.green; # "abcdefg" and fields
      base0C = c.orange; # "\n"
      base0D = c.green; # println!, methods
      base0E = c.red; # pub, impl, &, &mut
      base0F = c.fg2;
    };

  # IoskeleyMono everywhere (temporary — was Drafting Mono). The fonts flake
  # ships it pre-patched as a Nerd Font, so fontconfig sees the family
  # "IoskeleyMono Nerd Font" and icons come straight from the primary face.
  # `serif` deliberately holds the same family (a fully monospaced desktop);
  # the fallback chains in theming/fonts.nix + system/fonts.nix add only the
  # Libertinus Math glyph coverage Ioskeley lacks — no serif fallback.
  fonts = {
    mono = "IoskeleyMono Nerd Font";
    serif = "IoskeleyMono Nerd Font";
  };

  border-style = {
    radius-float = 1.0;
    radius-int = 1;
    width = 2;
  };

  # Shared shadow opacity, applied to every shadow color via
  # `themeLib.alpha`. Single knob for how see-through shadows are.
  shadow-style = {
    opacity = 0.92;
  };

  # Wallpaper — single source of truth, consumed by the home-manager
  # surfaces (awww, stylix, hyprlock) and by the greeter backdrop.
  wallpaper = ../../wallpapers/berries.jpg;

  # Color-format helpers for consumer modules.
  themeLib = {
    inherit
      rgbDec
      rgbCss
      mix
      alpha
      ;
  };
}
