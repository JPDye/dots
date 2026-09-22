# Single source of truth for every theme token in this flake.
#
# This is a plain function, not a module, on purpose. NixOS system modules
# cannot see home-manager's `_module.args`, so the surfaces that need theme
# tokens on *both* sides (the greeter, fontconfig) import this file directly
# instead of hardcoding a copy behind a "keep in sync" comment.
#
# One switch lives below. `scheme` picks which palette under `palettes/`
# supplies the hues. There is no light/dark axis: each scheme is a single
# dark palette.
{ lib }:

let
  plib = import ./palette-lib.nix { inherit lib; };

  # Every scheme takes `plib` and returns `{ colors, syntax }`, plus an
  # optional `base16` override. `colors` is a flat map of hex strings, which
  # consumers such as `modules/desktop/eww.nix` rely on. Add a file here to
  # add a scheme.
  schemes = {
    gruvbox = import ./palettes/gruvbox.nix { inherit plib; };
    kintsugi = import ./palettes/kintsugi.nix { inherit plib; };
  };

  active = schemes.${scheme};

  # The active scheme. This is the only theme switch: every surface follows
  # it, on both the home-manager and the NixOS side.
  scheme = "kintsugi";
in
rec {
  inherit scheme;

  # Names of every scheme available, so a consumer can enumerate them.
  schemeNames = builtins.attrNames schemes;

  inherit (active) colors syntax ansi;

  # The base16 attrset stylix consumes, built straight from the palette.
  # stylix takes an attrset here, so no upstream yaml sits underneath this
  # theme and no `stylix.override` is needed to paint over one.
  #
  # The default base08-0F mapping is a deliberate syntax-highlight choice,
  # not the base16 default. A scheme that ports an existing editor theme
  # publishes its own `base16` attrset, merged over these, so the port keeps
  # upstream's highlighting instead of borrowing a mapping built for a
  # different palette. `palettes/kintsugi.nix` does this.
  base16Scheme =
    let
      c = colors;
    in
    {
      scheme = "dotfiles";
      author = "jd";
      slug = "dotfiles-${scheme}";
      variant = "dark";

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
    }
    // (active.base16 or { });

  # IoskeleyMono everywhere, the Term + Nerd Font Mono build vendored in the
  # fonts flake (see its comment for why that variant). Its TTFs already
  # carry the Nerd Font icon set at one cell per icon, so icons come straight
  # from the primary face. `serif` deliberately holds the same family (a
  # fully monospaced desktop). The fallback chains in theming/fonts.nix +
  # system/fonts.nix add only an icon backup and the math glyph coverage
  # IoskeleyMono lacks. No serif fallback.
  #
  # Fonts, borders, shadows and the wallpaper sit outside the scheme on
  # purpose: they are the same design whichever palette paints it.
  fonts = {
    mono = "IoskeleyMonoTerm Nerd Font Mono";
    serif = "IoskeleyMonoTerm Nerd Font Mono";
  };

  border-style = {
    # Corner radius, one source of truth. niri window-rules take the float
    # (geometry-corner-radius), CSS consumers take the int (greeter, walker).
    # Square: the desktop is all hard edges.
    radius-float = 0.0;
    radius-int = 0;
    # Every border in the desktop reads this: niri window borders, walker,
    # the greeter box and the hyprlock rings.
    width = 1;
  };

  # Shared shadow opacity, applied to every shadow color via
  # `themeLib.alpha`. Single knob for how see-through shadows are.
  shadow-style = {
    opacity = 0.92;
  };

  # Wallpaper — single source of truth, consumed by the home-manager
  # surfaces (awww, stylix, hyprlock) and by the greeter backdrop.
  wallpaper = ../../wallpapers/rockman.png;

  # Color-format helpers for consumer modules.
  themeLib = {
    inherit (plib)
      rgbDec
      rgbCss
      mix
      alpha
      ;
  };
}
