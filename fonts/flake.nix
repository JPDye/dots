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

        packages.drafting-mono =
          let
            # The foundry names the family "Drafting* Mono" — asterisk and all,
            # which is awkward to reference in every app config. Rewrite the
            # name table on each face so the family is a clean "Drafting Mono"
            # (also fixes the full name and PostScript name).
            deAsterisk = pkgs.writeText "drafting-deasterisk.py" ''
              import sys
              from fontTools.ttLib import TTFont
              src, dst = sys.argv[1], sys.argv[2]
              font = TTFont(src)
              for rec in font["name"].names:
                  s = rec.toUnicode()
                  if "Drafting*" in s:
                      rec.string = s.replace("Drafting*", "Drafting")
              font.save(dst)
            '';
          in
          pkgs.stdenvNoCC.mkDerivation {
            name = "drafting-mono";
            dontConfigure = true;
            dontUnpack = true;
            # Upstream ships 14 weights (Thin..Bold + italics); rename them all.
            nativeBuildInputs = [ (pkgs.python3.withPackages (ps: [ ps.fonttools ])) ];
            installPhase = ''
              dest=$out/share/fonts/truetype/drafting-mono
              mkdir -p "$dest"
              for f in ${./drafting-mono}/*.ttf; do
                python3 ${deAsterisk} "$f" "$dest/$(basename "$f")"
              done
              install -Dm644 ${./drafting-mono}/LICENSE.md -t $out/share/doc/drafting-mono
            '';

            meta = {
              description = ''Drafting Mono (name table renamed to "Drafting Mono"), local TTF font derivation.'';
            };
          };
      }
    );
}
