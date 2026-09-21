{
  config,
  lib,
  colors,
  ...
}:

let
  cfg = config.dotfiles.shell.starship;
in
{
  options.dotfiles.shell.starship.enable = lib.mkEnableOption "starship prompt" // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
    programs.starship = {
      enable = true;
      enableNushellIntegration = true;
      settings = {
        format = ''
          [┌](#${colors.bg2})[ ](#${colors.bg2})$username [󰅂 ](#${colors.secondary})$directory[󰅂](#${colors.primary})$git_branch$git_status[󰅂](#${colors.tertiary})$time[󰅂](#${colors.success})
          [└ ](#${colors.bg2})$character
        '';

        add_newline = true;

        username = {
          show_always = true;
          style_user = "#${colors.secondary}";
          style_root = "#${colors.urgent}";
          format = "[$user]($style)";
          disabled = false;
        };

        directory = {
          style = "#${colors.primary}";
          format = "[$path ]($style)";
          truncation_length = 3;
          truncation_symbol = "󰇘/";
          substitutions = {
            "Documents" = "󰈙 ";
            "Downloads" = " ";
            "Music" = " ";
            "Pictures" = " ";
          };
        };

        git_branch = {
          symbol = "";
          style = "#${colors.tertiary}";
          format = "[ $symbol $branch]($style)";
        };

        git_status = {
          style = "#${colors.tertiary}";
          format = "[$all_status$ahead_behind ]($style)";
          modified = "!";
          untracked = "?";
          staged = "✓";
          deleted = "✘";
          renamed = "»";
          conflicted = "≠";
          ahead = "↑";
          behind = "↓";
          diverged = "⇕";
          stashed = "≡";
        };

        time = {
          disabled = false;
          time_format = "%R";
          style = "#${colors.success}";
          format = "[  $time ]($style)";
        };

        character = {
          success_symbol = "[󰅂 ](#${colors.success})";
          error_symbol = "[󰅂 ](#${colors.failure})";
        };
      };
    };
  };
}
