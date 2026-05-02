_: {
  # wl-clipboard lives in modules/shell/cli-tools.nix.
  services.cliphist = {
    enable = true;
    systemdTargets = [ "graphical-session.target" ];
  };
}
