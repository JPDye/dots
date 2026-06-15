{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dotfiles.system.plymouth;
in
{
  options.dotfiles.system.plymouth.enable = lib.mkEnableOption "boot splash (plymouth)" // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
    boot = {
      # Boot splash (laptop-nix only — NixOS owns the boot path; desktop-arch is
      # Arch's domain). deus_ex is fixed pixel art from adi1090x's theme pack, so
      # it doesn't derive from the home-manager palette — nothing to keep in sync.
      plymouth = {
        enable = true;
        theme = "deus_ex";
        # Build just deus_ex rather than all 80 themes in the pack.
        themePackages = [
          (pkgs.adi1090x-plymouth-themes.override { selected_themes = [ "deus_ex" ]; })
        ];
      };

      # Quiet the boot so the splash isn't buried under kernel/udev logs.
      # systemd-boot still shows its menu; only the post-kernel chatter is hidden.
      kernelParams = [
        "quiet"
        "splash"
        "udev.log_priority=3"
      ];
      consoleLogLevel = 0;
      initrd.verbose = false;
    };
  };
}
