{ colors, ... }:
{
  programs.starship = {
    enable = true;
    enableNushellIntegration = true;
    settings = {
      format = ''
        [┌](#504945)[ ](#504945)$username [󰅂 ](#${colors.red})$directory[󰅂](#${colors.orange})$git_branch$git_status[󰅂](#${colors.yellow})$time[󰅂](#${colors.green})
        [└ ](#504945)$character
      '';

      add_newline = true;

      username = {
        show_always = true;
        style_user = "#${colors.red}";
        style_root = "#${colors.red}";
        format = "[$user]($style)";
        disabled = false;
      };

      directory = {
        style = "#${colors.orange}";
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
        style = "#${colors.yellow}";
        format = "[ $symbol $branch]($style)";
      };

      git_status = {
        style = "#${colors.yellow}";
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
        style = "#${colors.green}";
        format = "[  $time ]($style)";
      };

      character = {
        success_symbol = "[󰅂 ](#${colors.green})";
        error_symbol = "[󰅂 ](#${colors.red})";
      };
    };
  };
}
