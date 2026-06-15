_:

{
  # Stock cached orca build: the login-fixed relink (modules/apps/orca-slicer.nix)
  # is a ~1 h uncached local recompile, only worth it where Bambu cloud login is
  # actually used (the desktop).
  dotfiles.apps.orca-slicer.loginFix = false;

  programs.niri.settings.outputs = {
    "eDP-1" = {
      scale = 1.0;
      focus-at-startup = true;
    };

    "HDMI-A-1" = {
      scale = 1.0;
    };

    "DP-7" = {
      scale = 1.0;
    };

    "DP-1" = {
      scale = 1.0;
    };
  };
}
