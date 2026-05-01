{ pkgs, ... }:
{
  home.packages = with pkgs; [
    ripgrep
    fd
    dust
    procs
    sd
    jq
    tokei
    glow
  ];

  programs.tealdeer = {
    enable = true;
    settings = {
      updates.auto_update = true;
    };
  };
}
