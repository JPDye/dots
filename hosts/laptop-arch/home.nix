{
  lib,
  pkgs,
  mkNixGLWrap,
  ...
}:

let
  # MSI Prestige 14 AI Evo: Core Ultra 7 255H with an Arc iGPU, driven by Mesa
  # — so nixGLIntel (the Mesa variant) is the right wrapper, same as the
  # desktop. mkNixGLWrap lives in modules/wrap-gl.nix.
  wrapGL = mkNixGLWrap "${pkgs.nixgl.nixGLIntel}/bin/nixGLIntel";
in
{
  dotfiles.wrapGL = wrapGL;

  # Stock cached orca build: the login-fixed relink (modules/apps/orca-slicer.nix)
  # is a ~1 h uncached local recompile, only worth it where Bambu cloud login is
  # actually used (the desktop).
  dotfiles.apps.orca-slicer.loginFix = false;

  # nixGL itself, exposed in PATH for ad-hoc wrapping (`nixGL <cmd>`).
  home.packages = [ pkgs.nixgl.nixGLIntel ];

  # Install niri into the user profile — on Arch there's no system-level
  # `programs.niri.enable` to do it. nixGL-wrapped so its GL/Vulkan calls find
  # the system driver libs. Run `niri-session` from a TTY (no DM session or
  # systemd unit is auto-enabled).
  programs.niri = {
    enable = true;
    # nixpkgs' niri (26.04), matching the other hosts — see the version note in
    # hosts/desktop-arch/home.nix.
    package = wrapGL pkgs.niri;

    settings = {
      outputs = {
        # Single 14" 1920x1200@144 panel, unscaled — the full 1920x1200 is the
        # logical space. The shared 0.333/0.5/0.666 column presets are wide enough
        # at that size, so this host leaves them alone (the desktop widens them
        # for a big monitor).
        "eDP-1" = {
          scale = 1;
          focus-at-startup = true;
        };

        "DP-3" = {
          scale = 1;
          focus-at-startup = true;
        };
      };

      # Tighter than the shared 16 in modules/desktop/niri/layout.nix, which the
      # small panel needs. mkForce because both sit at normal priority.
      layout.gaps = lib.mkForce 8;
    };
  };
}
