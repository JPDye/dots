{
  description = "A flake giving access to fonts that I use, outside of nixpkgs.";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        defaultPackage = pkgs.symlinkJoin {
          name = "myFonts";
          paths = builtins.attrValues self.packages.${system};
        };

        packages.ioskeley = pkgs.stdenvNoCC.mkDerivation {
          name = "ioskeley-mono";
          dontConfigure = true;
          dontUnpack = true;
          installPhase = ''
            mkdir -p $out/share/fonts/truetype
            cp ${./ioskeley-mono-regular.ttf}     $out/share/fonts/truetype/ioskeley-mono-regular.ttf
            cp ${./ioskeley-mono-bold.ttf}        $out/share/fonts/truetype/ioskeley-mono-bold.ttf
            cp ${./ioskeley-mono-italic.ttf}      $out/share/fonts/truetype/ioskeley-mono-italic.ttf
            cp ${./ioskeley-mono-bold-italic.ttf} $out/share/fonts/truetype/ioskeley-mono-bold-italic.ttf
          '';

          meta = {
            description = "Local TTF font derivation.";
          };
        };
      }
    );
}
