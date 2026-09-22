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
        # Each segment and the separator that closes it share one gradient
        # step, and the steps advance left to right: username, directory,
        # git, time. Re-ordering gradient1..gradient6 in the active scheme
        # re-orders the prompt with it, so the sequence lives in one place.
        format = ''
          [┌](#${colors.bg2})[ ](#${colors.gradient1})$username[ 󰅂 ](#${colors.gradient1})$directory[󰅂](#${colors.gradient2})$git_branch$git_status[󰅂](#${colors.gradient3})$time[󰅂](#${colors.gradient4})
          [└ ](#${colors.bg2})$character
        '';

        add_newline = true;

        username = {
          show_always = true;
          style_user = "#${colors.gradient1}";
          # Root stays on `urgent`: a warning outranks the gradient.
          style_root = "#${colors.urgent}";
          format = "[$user]($style)";
          disabled = false;
        };

        directory = {
          style = "#${colors.gradient2}";
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
          style = "#${colors.gradient3}";
          format = "[ $symbol $branch]($style)";
        };

        git_status = {
          style = "#${colors.gradient3}";
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
          style = "#${colors.gradient4}";
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
