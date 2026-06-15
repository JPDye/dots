{
  config,
  inputs,
  lib,
  ...
}:

{
  config = lib.mkIf config.dotfiles.desktop.niri.enable {
    programs.niri.settings.animations = {
      slowdown = 1.0;

      window-open = {
        kind.easing = {
          duration-ms = 400;
          curve = "linear";
        };
        custom-shader = builtins.readFile "${inputs.self}/shaders/niri-window-open.glsl";
      };

      window-close = {
        kind.easing = {
          duration-ms = 400;
          curve = "linear";
        };
        custom-shader = builtins.readFile "${inputs.self}/shaders/niri-window-close.glsl";
      };
    };
  };
}
