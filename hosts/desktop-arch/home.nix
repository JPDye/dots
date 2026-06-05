{
  lib,
  pkgs,
  mkNixGLWrap,
  ...
}:

let
  # nixGLIntel is the Mesa variant — also covers AMD GPUs. mkNixGLWrap lives in
  # modules/wrap-gl.nix so the wrapping logic is shared across non-NixOS hosts.
  wrapGL = mkNixGLWrap "${pkgs.nixgl.nixGLIntel}/bin/nixGLIntel";
in
{
  dotfiles.wrapGL = wrapGL;

  # nixGL itself, exposed in PATH for ad-hoc wrapping (`nixGL <cmd>`).
  home.packages = [ pkgs.nixgl.nixGLIntel ];

  # Install niri (and its bundled `niri-session` launcher) into the user
  # profile. On NixOS the system-level `programs.niri.enable` handles this;
  # on Arch we need home-manager to do it. The package is wrapped with nixGL
  # so its GL/Vulkan calls find the system's driver libs.
  #
  # No autostart: niri-flake's home module only adds the package — no DM
  # session or systemd unit is auto-enabled. Run `niri-session` from a TTY.
  programs.niri = {
    enable = true;
    package = wrapGL pkgs.niri-stable;

    # Host-specific niri bits: monitors and the ghostty launcher override
    # (ghostty needs nixGL on Arch since its OpenGL libs aren't where nixpkgs expects).
    settings = {
      outputs = {
        "HDMI-A-1" = {
          scale = 1.0;
          transform.rotation = 90;
        };
        "DP-10" = {
          scale = 1.0;
        };
        "DP-9" = {
          scale = 1.0;
          focus-at-startup = true;
        };
      };

      binds."Mod+Return" = lib.mkForce {
        action.spawn = [
          "nixGL"
          "ghostty"
        ];
      };
    };
  };
}
