{ shellAliases, ... }:
{
  xdg.configFile."nushell/welcome.nu".source = ./nushell/welcome.nu;
  xdg.configFile."nushell/scaffolds.nu".source = ./nushell/scaffolds.nu;

  programs.nushell = {
    enable = true;

    environmentVariables = {
      EDITOR = "hx";
      VISUAL = "hx";
    };

    inherit shellAliases;

    settings = {
      show_banner = false;
      completions = {
        case_sensitive = false;
        quick = true;
        partial = true;
        algorithm = "fuzzy";
        external.enable = true;
        external.max_results = 50;
      };

      keybindings = [
        {
          name = "backspace_word";
          modifier = "control";
          keycode = "char_h";
          mode = [ "emacs" "vi_insert" ];
          event = { edit = "BackspaceWord"; };
        }
      ];
    };

    extraConfig = ''
      source ~/.config/nushell/welcome.nu
      welcome

      use ~/.config/nushell/scaffolds.nu *
    '';
  };
}
