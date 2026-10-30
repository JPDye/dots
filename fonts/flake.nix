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

        # nerd-font-patcher renames the family (e.g. "Drafting*Mono Nerd
        # Font Mono"), but apps reference the plain name ("Drafting Mono").
        # So after patching we copy the *original* name table onto the
        # patched face, de-asterisking the foundry's "Drafting* Mono" name in
        # the process (fixes family, full and PostScript names). The font
        # keeps its own identity but now carries the Nerd Font icons at its
        # own metrics — so prompt/UI glyphs (starship separators, the
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

        # Each face is patched with the full Nerd Font glyph set as
        # single-width (--mono), so every icon occupies exactly one terminal
        # cell. FontForge runs once per face, so the first build is slow
        # (then cached) — trim the glob to the core four faces to speed it up.
        nerdPatchMono =
          {
            name,
            src,
            license,
            description,
          }:
          pkgs.stdenvNoCC.mkDerivation {
            inherit name;
            dontConfigure = true;
            dontUnpack = true;
            nativeBuildInputs = [
              pkgs.nerd-font-patcher
              (pkgs.python3.withPackages (ps: [ ps.fonttools ]))
            ];
            installPhase = ''
              export HOME=$(mktemp -d)   # FontForge needs a writable HOME
              dest=$out/share/fonts/truetype/${name}
              mkdir -p "$dest"
              for f in ${src}/*.ttf; do
                work=$(mktemp -d)
                nerd-font-patcher --mono --complete --careful --quiet --no-progressbars "$f" -out "$work"
                patched=$(find "$work" -name '*.ttf' -print -quit)
                python3 ${fixNames} "$f" "$patched" "$dest/$(basename "$f")"
                rm -rf "$work"
              done
              install -Dm644 ${src}/${license} -t $out/share/doc/${name}
            '';

            meta = { inherit description; };
          };
      in
      {
        defaultPackage = pkgs.symlinkJoin {
          name = "myFonts";
          paths = builtins.attrValues self.packages.${system};
        };

        packages = {
          # IoskeleyMono v2.1.0, the Term + Nerd Font Mono build (Iosevka
          # 34.4.0, Nerd Fonts 3.5.0). Two reasons for that exact variant.
          # "Mono" holds every icon inside one terminal cell, where the plain
          # Nerd Font build is dual-width (fontconfig spacing 90). "Term"
          # redraws the 170 wide-width arrow glyphs (uni2191, uni21D1, ...)
          # so they fit one cell too. The two builds are otherwise the same:
          # 360 ligatures, identical features, advance widths and glyph set.
          ioskeley = pkgs.stdenvNoCC.mkDerivation {
            name = "ioskeley-mono";
            dontConfigure = true;
            dontUnpack = true;
            # OFL-1.1 requires its notice to travel with every copy.
            installPhase = ''
              dest=$out/share/fonts/truetype/ioskeley-mono
              mkdir -p "$dest"
              cp ${./ioskeley-mono}/*.ttf "$dest"/
              install -Dm644 ${./ioskeley-mono}/LICENSE.md -t $out/share/doc/ioskeley-mono
            '';

            meta = {
              description = "IoskeleyMono Term Nerd Font Mono v2.1.0. Local TTF font derivation.";
            };
          };

          drafting-mono = nerdPatchMono {
            name = "drafting-mono";
            src = ./drafting-mono;
            license = "LICENSE.md";
            description = ''Drafting Mono patched with Nerd Font glyphs (name table normalised to "Drafting Mono"). Local TTF font derivation.'';
          };

          # Nordwand Mono v1.3.1 (github.com/tywr/Nordwand-Mono, OFL-1.1),
          # the release TTFs. Upstream ships no Nerd Font icons, so it goes
          # through the same patch as drafting-mono. The OFL declares no
          # Reserved Font Name, so the patched faces keep "Nordwand Mono".
          nordwand-mono = nerdPatchMono {
            name = "nordwand-mono";
            src = ./nordwand-mono;
            license = "LICENSE.txt";
            description = ''Nordwand Mono patched with Nerd Font glyphs (name table kept as "Nordwand Mono"). Local TTF font derivation.'';
          };

          # Luxi Mono ships unpatched, and must stay that way. The Bigelow &
          # Holmes licence grants free redistribution, but it voids itself on
          # any modification: "The Font Software may not be modified, altered,
          # or added to ... nor may additional glyphs or characters be added".
          # So no nerd-font-patcher here, unlike drafting-mono above. Icon
          # glyphs come from the Symbols Nerd Font Mono fallback instead (see
          # the defaultFonts chains in modules/theming/fonts.nix and
          # modules/system/fonts.nix).
          luxi-mono = pkgs.stdenvNoCC.mkDerivation {
            name = "luxi-mono";
            dontConfigure = true;
            dontUnpack = true;
            # The licence requires its notice to travel with every copy, so
            # LICENSE.txt is installed next to the faces, not dropped.
            installPhase = ''
              dest=$out/share/fonts/truetype/luxi-mono
              mkdir -p "$dest"
              cp ${./luxi-mono}/*.ttf "$dest"/
              install -Dm644 ${./luxi-mono}/LICENSE.txt -t $out/share/doc/luxi-mono
            '';

            meta = {
              description = "Luxi Mono by Bigelow & Holmes, unmodified. Local TTF font derivation.";
            };
          };
        };
      }
    );
}
