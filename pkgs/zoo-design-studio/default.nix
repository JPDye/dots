{
  appimageTools,
  fetchurl,
}:

let
  pname = "zoo-design-studio";
  # Bump these two lines for a new release, or just run ./update.sh
  version = "1.3.7";
  hash = "sha256-VwHWYrt3YV4yvObMhwb5h5o0JfUl4efvaJ0Bm7j68Yk=";

  src = fetchurl {
    url = "https://github.com/KittyCAD/modeling-app/releases/download/v${version}/Zoo.Design.Studio-${version}-x86_64-linux.AppImage";
    inherit hash;
  };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands =
    let
      contents = appimageTools.extract { inherit pname version src; };
    in
    ''
      install -Dm444 ${contents}/zoo-modeling-app.desktop \
        $out/share/applications/zoo-design-studio.desktop
      install -Dm444 ${contents}/zoo-modeling-app.png \
        $out/share/icons/hicolor/512x512/apps/zoo-modeling-app.png
      substituteInPlace $out/share/applications/zoo-design-studio.desktop \
        --replace-fail 'Exec=AppRun --no-sandbox %U' 'Exec=zoo-design-studio %U'
    '';

  meta = {
    description = "Zoo Design Studio (formerly KittyCAD Modeling App), from the official AppImage";
    homepage = "https://zoo.dev/design-studio";
    platforms = [ "x86_64-linux" ];
    mainProgram = "zoo-design-studio";
  };
}
