{
  lib,
  pkgs,
  mkNixGLWrap,
  ...
}:

let
  # MSI Prestige 14 AI Evo: Core Ultra 7 255H with an Arc iGPU, driven by Mesa,
  # so nixGLIntel (the Mesa variant, which also covers AMD) is the right
  # wrapper. mkNixGLWrap lives in modules/wrap-gl.nix.
  wrapGL = mkNixGLWrap "${pkgs.nixgl.nixGLIntel}/bin/nixGLIntel";
in
{
  dotfiles.wrapGL = wrapGL;

  # No slicer on this laptop: the printer lives with the desktop, which is the
  # only host that needs orca (modules/apps/orca-slicer.nix).
  dotfiles.apps.orca-slicer.enable = false;

  home.packages = [
    # nixGL itself, exposed in PATH for ad-hoc wrapping (`nixGL <cmd>`).
    pkgs.nixgl.nixGLIntel

    # Root-level PAM setup for hyprlock (pam-setup.nix). It is also a flake
    # output, so `nix run .#arch-pam-setup` works before the first rebuild.
    # This entry puts the same command in PATH after a rebuild.
    (pkgs.callPackage ./pam-setup.nix { })
  ];

  # Install niri into the user profile — on Arch there's no system-level
  # `programs.niri.enable` to do it. nixGL-wrapped so its GL/Vulkan calls find
  # the system driver libs. Run `niri-session` from a TTY (no DM session or
  # systemd unit is auto-enabled).
  programs.niri = {
    enable = true;
    # nixpkgs' niri (26.04), not niri-flake's niri-stable build (25.08). The
    # shared config uses post-25.08 features (recent-windows switcher), and
    # laptop-nix runs the nixpkgs build too, so versions stay in step.
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
