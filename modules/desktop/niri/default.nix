{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.dotfiles.desktop.niri;
in
{
  imports = [
    ./spawn.nix
    ./layout.nix
    ./window-rules.nix
    ./binds.nix
    ./animations.nix
    ./scratchpad.nix
  ];

  options.dotfiles.desktop.niri = {
    enable = lib.mkEnableOption "niri compositor user config" // {
      default = true;
    };

    extraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = ''
        Raw KDL appended to the generated niri config. niri-flake's settings
        schema lags niri releases (it still targets v25.08), so options the
        schema doesn't know about go here. The combined file is still run
        through `niri validate` against programs.niri.package, so mistakes
        fail the build rather than the session.
      '';
    };
  };

  # Bits that don't fit any of the per-domain children.
  config = lib.mkIf cfg.enable {
    # niri-flake defaults this to its own niri-stable build (v25.08), but the
    # binary that actually runs is nixpkgs' niri (system programs.niri on
    # laptop-nix, wrapGL'd pkgs.niri on desktop-arch). Validate against the
    # same version, or post-25.08 config options get rejected at build time.
    programs.niri.package = lib.mkDefault pkgs.niri;

    programs.niri.settings = {
      hotkey-overlay.skip-at-startup = true;
      environment.DISPLAY = ":0";
      prefer-no-csd = true;
      screenshot-path = "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";
      gestures.hot-corners.enable = false;
    };

    # niri-flake writes xdg.configFile.niri-config from finalConfig (the
    # rendered settings). Re-point it at finalConfig + extraConfig, passed
    # through the same validation derivation niri-flake uses itself.
    xdg.configFile.niri-config.source = lib.mkIf (cfg.extraConfig != "") (
      lib.mkForce (
        inputs.niri.lib.internal.validated-config-for pkgs config.programs.niri.package (
          config.programs.niri.finalConfig + "\n" + cfg.extraConfig
        )
      )
    );
  };
}
