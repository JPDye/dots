{ config, lib, pkgs, colors, monoFont, ... }:

{
  gtk.gtk4.theme = config.gtk.theme;

  stylix = {
    enable = true;

    image = ../wallpapers/book.jpg;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-hard.yaml";

    fonts = {
      monospace.name = monoFont;
      serif.name = monoFont;
      sansSerif.name = monoFont;

      sizes = {
        applications = 14;
        desktop = 14;
        popups = 14;
        terminal = 14;
      };
    };

    cursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Original-Amber";
      size = 16;
    };

    override = lib.mkForce {
      base00 = "${colors.bg0}";
      base01 = "${colors.bg1}";
      base02 = "${colors.bg2}";
      base03 = "${colors.bg3}";
      base04 = "${colors.fg3}";
      base05 = "${colors.white}"; # ::<>, ()
      base06 = "${colors.fg1}";
      base07 = "${colors.fg0}";

      base08 = "${colors.orange}"; # self, fields, variables
      base09 = "${colors.yellow}"; # ints, booleans, constants
      base0A = "${colors.pink}"; # HashMap<String, String>;
      base0B = "${colors.green}"; # "abcdefg" and fields
      base0C = "${colors.orange}"; # "\n"
      base0D = "${colors.green}"; # println!, methods
      base0E = "${colors.red}"; # pub, impl, &, &mut
      base0F = "ffffff";
    };
  };

  stylix.targets = lib.recursiveUpdate
    (lib.genAttrs [ "firefox" "spicetify" "zellij" "tofi" "mako" ] (_: { enable = false; }))
    {
      firefox.profileNames = [ "jd" ];
      ghostty.enable = true;
    };
}
