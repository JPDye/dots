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
            # nerd-font-patcher renames the family (e.g. "Drafting*Mono Nerd
            # Font Mono"), but apps reference plain "Drafting Mono". So after
            # patching we copy the *original* name table onto the patched face,
            # de-asterisking the foundry's "Drafting* Mono" name in the process
            # (fixes family, full and PostScript names). The font keeps its
            # "Drafting Mono" identity but now carries the Nerd Font icons at
            # its own metrics — so prompt/UI glyphs (starship separators, the
            # directory ellipsis, etc.) stop falling back to Symbols Nerd Font
            # Mono and rendering with a mismatched size/baseline.
            fixNames = pkgs.writeText "drafting-fixnames.py" ''
              import sys
              from fontTools.ttLib import TTFont
              orig_path, patched_path, dst = sys.argv[1], sys.argv[2], sys.argv[3]
              orig = TTFont(orig_path)
              for rec in orig["name"].names:
                  s = rec.toUnicode()
                  if "Drafting*" in s:
                      rec.string = s.replace("Drafting*", "Drafting")
              patched = TTFont(patched_path)
              patched["name"] = orig["name"]
              patched.save(dst)
            '';
          in
          pkgs.stdenvNoCC.mkDerivation {
            name = "drafting-mono";
            dontConfigure = true;
            dontUnpack = true;
            # Upstream ships 14 weights (Thin..Bold + italics). Each face is
            # patched with the full Nerd Font glyph set as single-width
            # (--mono), so every icon occupies exactly one terminal cell.
            # FontForge runs once per face, so the first build is slow (then
            # cached) — trim the glob to the core four faces to speed it up.
            nativeBuildInputs = [
              pkgs.nerd-font-patcher
              (pkgs.python3.withPackages (ps: [ ps.fonttools ]))
            ];
            installPhase = ''
              export HOME=$(mktemp -d)   # FontForge needs a writable HOME
              dest=$out/share/fonts/truetype/drafting-mono
              mkdir -p "$dest"
              for f in ${./drafting-mono}/*.ttf; do
                work=$(mktemp -d)
                nerd-font-patcher --mono --complete --careful --quiet --no-progressbars "$f" -out "$work"
                patched=$(find "$work" -name '*.ttf' -print -quit)
                python3 ${fixNames} "$f" "$patched" "$dest/$(basename "$f")"
                rm -rf "$work"
              done
              install -Dm644 ${./drafting-mono}/LICENSE.md -t $out/share/doc/drafting-mono
            '';

            meta = {
              description = ''Drafting Mono patched with Nerd Font glyphs (name table normalised to "Drafting Mono"). Local TTF font derivation.'';
            };
          };
      }
    );
}
