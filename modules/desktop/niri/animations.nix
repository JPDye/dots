{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.dotfiles.desktop.niri.animations;

  shader = name: builtins.readFile "${inputs.self}/shaders/niri-${name}.glsl";

  spring = damping-ratio: stiffness: epsilon: {
    kind.spring = { inherit damping-ratio stiffness epsilon; };
  };
  easing = duration-ms: curve: {
    kind.easing = { inherit duration-ms curve; };
  };
  bezier = duration-ms: curve-args: {
    kind.easing = {
      inherit duration-ms curve-args;
      curve = "cubic-bezier";
    };
  };

  # The butter/spontaneous and liquid/portal families share every
  # non-shader animation, so each pair builds on one base.
  butter = rec {
    settings = {
      slowdown = 5;
      window-open = bez // {
        custom-shader = shader "butter-window-open";
      };
      window-close = bez // {
        custom-shader = shader "butter-window-close";
      };
      window-resize = bez;
      workspace-switch = bez;
      horizontal-view-movement = bez;
      window-movement = bez;
      config-notification-open-close = bezier 350 curve;
      exit-confirmation-open-close = easing 300 "ease-out-quad";
      screenshot-ui-open = bezier 300 curve;
      overview-open-close = bez;
    };
    recentWindowsClose = "duration-ms 400; curve \"cubic-bezier\" 0.05 0.9 0.1 1.0";
    curve = [
      0.05
      0.9
      0.1
      1.0
    ];
    bez = bezier 400 curve;
  };

  fluid = name: duration: resize: {
    settings = {
      slowdown = 1.5;
      window-open = easing duration "linear" // {
        custom-shader = shader "${name}-window-open";
      };
      window-close = easing duration "linear" // {
        custom-shader = shader "${name}-window-close";
      };
      window-resize = resize // {
        custom-shader = shader "${name}-window-resize";
      };
      workspace-switch = spring 1.0 760 0.0001;
      horizontal-view-movement = spring 1.0 640 0.0001;
      window-movement = spring 1.0 700 0.0001;
      config-notification-open-close = spring 1.0 820 0.001;
      exit-confirmation-open-close = spring 1.0 560 0.01;
      screenshot-ui-open = bezier 220 [
        0.22
        1.0
        0.36
        1.0
      ];
      overview-open-close = spring 1.0 620 0.0001;
    };
    recentWindowsClose = "spring damping-ratio=1.0 stiffness=680 epsilon=0.001";
  };

  bounce = {
    workspace-switch = spring 0.65 500 0.0001;
    window-open = spring 0.55 600 0.0001;
    window-close = easing 150 "ease-out-quad";
    horizontal-view-movement = spring 0.65 500 0.0001;
    window-movement = spring 0.65 500 0.0001;
    window-resize = spring 0.65 500 0.0001 // {
      custom-shader = shader "bounce-window-resize";
    };
    config-notification-open-close = spring 0.65 700 0.001;
    screenshot-ui-open = easing 200 "ease-out-quad";
    overview-open-close = spring 0.75 400 0.0003;
  };

  # Every preset except grid comes from
  # github.com/stephin-develops/linux-ricing ("New niri animations").
  # `recentWindowsClose` is raw KDL, because niri-flake's schema has no
  # recent-windows-close animation yet.
  presets = {
    # grid keeps its own open/close shaders and takes every other
    # animation from bounce, slowed down 1.1x. slowdown is global, so the
    # open/close durations are set to play at about 600 ms after it.
    grid.settings = bounce // {
      slowdown = 1.1;
      window-open = easing 545 "linear" // {
        custom-shader = shader "grid-window-open";
      };
      window-close = easing 545 "linear" // {
        custom-shader = shader "grid-window-close";
      };
    };

    bounce.settings = bounce;

    butter = { inherit (butter) settings recentWindowsClose; };

    spontaneous = {
      settings = butter.settings // {
        slowdown = 1.0;
      };
      inherit (butter) recentWindowsClose;
    };

    jello = {
      settings = {
        window-open = spring 0.5 600 0.0001 // {
          custom-shader = shader "jello-window-open";
        };
        window-close = spring 0.5 600 0.0001 // {
          custom-shader = shader "jello-window-close";
        };
        window-movement = spring 0.4 400 0.0001;
        window-resize = spring 0.4 400 0.0001;
        horizontal-view-movement = spring 0.5 500 0.0001;
        workspace-switch = spring 0.5 500 0.0001;
        overview-open-close = spring 0.5 500 0.0001;
        config-notification-open-close = spring 0.7 600 0.0001;
        exit-confirmation-open-close = spring 0.7 600 0.0001;
        screenshot-ui-open = spring 0.7 600 0.0001;
      };
      recentWindowsClose = "spring damping-ratio=0.7 stiffness=600 epsilon=0.0001";
    };

    liquid = fluid "liquid" 500 (easing 400 "linear");
    portal = fluid "portal" 400 (easing 350 "ease-out-cubic");
  };

  preset = presets.${cfg.preset};
in
{
  options.dotfiles.desktop.niri.animations.preset = lib.mkOption {
    type = lib.types.enum (builtins.attrNames presets);
    default = "grid";
    description = ''
      The niri animation preset. "grid" is the pixel-grid open/close
      shader pair with the bounce springs, slowed 1.1x, for all other
      animations. The other presets set every animation.
    '';
  };

  config = lib.mkIf config.dotfiles.desktop.niri.enable {
    programs.niri.settings.animations = preset.settings;

    # niri rejects a second `animations` node in one file, but it merges
    # an included file's `animations` into the main one.
    dotfiles.desktop.niri.extraConfig = lib.mkIf (preset ? recentWindowsClose) ''
      include "${pkgs.writeText "niri-recent-windows-anim.kdl" ''
        animations {
            recent-windows-close { ${preset.recentWindowsClose}; }
        }
      ''}"
    '';
  };
}
