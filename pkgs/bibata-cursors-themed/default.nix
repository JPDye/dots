# Bibata cursors rendered in this flake's palette.
#
# nixpkgs' `bibata-cursors` packages upstream's *release* bitmaps, which are
# fixed-colour bitmaps, so no `overrideAttrs` can recolour it. Upstream's own
# customisation path (README, "Customize Colors") re-renders the SVGs with
# `cbmp`, which drives headless Chromium through puppeteer. That is a browser
# to run inside a build sandbox, so this uses `resvg` on the same SVGs instead.
# The shapes are flat paths, and resvg renders them with no browser at all.
#
# Upstream's `render.json` is what documents the three placeholder colours.
# Every SVG paints with them, and each shipped theme substitutes its own:
#
#   #00FF00  base            (Amber substitutes #FF8300)
#   #0000FF  outline         (Amber substitutes #FFFFFF)
#   #FE0000  watch face      (Amber substitutes #001524)
#
# The watch colour appears only in the `wait` and `left_ptr_watch` frames, and
# those reach `svg/<variant>/` through symlinks into `svg/groups/`. Upstream's
# README and render.json both spell that third placeholder `#FF0000`, while the
# files themselves carry `#FE0000`, so the substitution below covers both.
{
  lib,
  stdenvNoCC,
  bibata-cursors,
  clickgen,
  resvg,

  # Hex strings with the leading `#`, as the SVGs spell them.
  baseColor,
  outlineColor,
  watchBackgroundColor,

  themeName ? "Bibata-Dotfiles",
  comment ? "Bibata XCursors in this flake's palette",
  # "original" is the sharp-edged cut, "modern" the rounded one. Both read the
  # same `configs/normal/x.build.toml`, exactly as the nixpkgs package does.
  variant ? "original",
}:

stdenvNoCC.mkDerivation {
  pname = "bibata-cursors-themed";

  # The upstream rev, its hash and the version all stay in nixpkgs. A nixpkgs
  # bump carries this package with it, and there is no second hash to update.
  inherit (bibata-cursors) version src;

  nativeBuildInputs = [
    clickgen
    resvg
  ];

  buildPhase = ''
    runHook preBuild

    # The animated cursors keep their frames in a subdirectory
    # (svg/${variant}/wait/wait-01.svg), but x.build.toml globs them flat as
    # `wait-*.png`. Flatten the tree, dereferencing the symlinks into
    # svg/groups/ on the way so the copies are real, writable files.
    mkdir -p svg-themed
    cp -rL --no-preserve=mode "svg/${variant}/." svg-themed/
    find svg-themed -mindepth 2 -name '*.svg' -exec mv {} svg-themed/ ';'
    find svg-themed -mindepth 1 -type d -exec rm -rf {} +

    sed -i \
      -e 's/#00FF00/${baseColor}/Ig' \
      -e 's/#0000FF/${outlineColor}/Ig' \
      -e 's/#FE0000/${watchBackgroundColor}/Ig' \
      -e 's/#FF0000/${watchBackgroundColor}/Ig' \
      svg-themed/*.svg

    # 256 square is the grid every hotspot in x.build.toml is measured on, and
    # the size upstream's own bitmaps come in. ctgen scales down from here to
    # the `x11_sizes` list that config declares.
    mkdir -p bitmaps
    for f in svg-themed/*.svg; do
      resvg -w 256 -h 256 "$f" "bitmaps/$(basename "$f" .svg).png"
    done

    ctgen configs/normal/x.build.toml \
      -p x11 \
      -d bitmaps \
      -o themes \
      -n ${lib.escapeShellArg themeName} \
      -c ${lib.escapeShellArg comment}

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    install -dm 0755 $out/share/icons
    cp -rf themes/* $out/share/icons/

    runHook postInstall
  '';

  # So a consumer sets `cursor.name` from the package rather than repeating the
  # string and letting the two drift.
  passthru = { inherit themeName; };

  meta = {
    description = "Bibata cursor theme recoloured from this flake's palette";
    homepage = "https://github.com/ful1e5/Bibata_Cursor";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
  };
}
