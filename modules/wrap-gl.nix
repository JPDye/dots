{ lib, pkgs, ... }:

let
  # Wrap a package so its executables run under nixGL — needed on non-NixOS
  # hosts where the OpenGL driver libs aren't where nixpkgs expects. Takes the
  # nixGL wrapper binary to use (e.g. "${pkgs.nixgl.nixGLIntel}/bin/nixGLIntel"
  # — nixGLIntel is the Mesa variant, which also covers AMD GPUs) and returns a
  # `pkg -> pkg` transform. Exposed via _module.args so any non-NixOS host can
  # do `dotfiles.wrapGL = mkNixGLWrap "…";` without copying this logic.
  mkNixGLWrap =
    nixGLBin: pkg:
    let
      wrappedBins =
        pkgs.runCommand "${pkg.name}-bin-nixgl"
          {
            nativeBuildInputs = [ pkgs.makeWrapper ];
          }
          ''
            mkdir -p $out/bin
            for bin in ${pkg}/bin/*; do
              if [ -f "$bin" ] && [ -x "$bin" ]; then
                name=$(basename "$bin")
                makeWrapper ${nixGLBin} "$out/bin/$name" \
                  --add-flags "$bin"
              fi
            done
          '';
      wrapped = pkgs.symlinkJoin {
        name = "${pkg.name}-nixgl";
        paths = [
          wrappedBins
          pkg
        ];
      };
      merged =
        # Re-expose the original package's attributes (meta, passthru, and
        # top-level fields such as buildRustPackage's `cargoBuildFeatures`) on
        # the wrapped result, while keeping the symlinkJoin's own store paths
        # and outputs. Without this, consumers that introspect the package
        # break — e.g. niri-flake reads `cfg.package.cargoBuildNoDefaultFeatures`.
        wrapped
        // builtins.removeAttrs pkg (
          [
            "name"
            "type"
            "out"
            "outPath"
            "drvPath"
            "outputName"
            "outputs"
            "all"
          ]
          ++ (pkg.outputs or [ ])
        );
    in
    # The re-exposed `meta` above is the original package's, whose
    # `outputsToInstall` can name outputs the single-`out` symlinkJoin doesn't
    # have (e.g. vlc's `man`), which makes home-manager's buildenv fail with
    # `attribute '<output>' missing`. The wrapper only contains `out`, so pin
    # outputsToInstall to that.
    merged
    // {
      meta = (merged.meta or { }) // {
        outputsToInstall = [ "out" ];
      };
    };
in
{
  options.dotfiles.wrapGL = lib.mkOption {
    type = lib.types.functionTo lib.types.package;
    default = pkg: pkg;
    description = ''
      Transform applied to GPU/OpenGL-using packages. Identity on hosts where
      the OS supplies driver libs in the right places (NixOS); on Arch and
      similar a host sets this to `mkNixGLWrap "<nixGL binary>"` to wrap each
      binary with nixGL.
    '';
  };

  # Declaring `options` above puts this module in the module system's explicit
  # options/config form, where everything else must sit under `config` — a
  # top-level `_module` is rejected ("unsupported attribute `_module`"). So set
  # the shared helper arg inside `config`.
  config._module.args.mkNixGLWrap = mkNixGLWrap;
}
