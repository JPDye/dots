# Pure colour maths, shared by every scheme under `palettes/`.
#
# Split out of palette.nix so a scheme file stays plain data: it takes these
# helpers as an argument and declares hues, nothing more. Nothing in here
# knows about any particular palette.
{ lib }:

rec {
  # Hex colour math. `mix` and `alpha` build on these.
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
}
