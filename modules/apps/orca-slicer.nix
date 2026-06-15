{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.dotfiles.apps.orca-slicer;

  # orca-slicer / bambu-studio pinned to nixos-26.05 (see flake.nix input):
  # 26.11's orca 2.4.1 regressed file dialogs, and only 26.05 has the
  # bambu-studio cloud-login fix (nixpkgs#498307). orca is cached;
  # bambu-studio is unfree (never Hydra-cached) and compiles locally once.
  pkgs2605 = import inputs.nixpkgs-2605 {
    inherit (pkgs.stdenv.hostPlatform) system;
    config.allowUnfree = true;
  };

  # 26.05's cloud-login fix (nixpkgs#498307) only landed in bambu-studio; it
  # has two parts, both replicated for orca-slicer here.
  #
  # Part 1 — relink: gcc-unwrapped in buildInputs makes the link bake a static
  # libstdc++ into the executable, whose locale internals interpose
  # libstdc++.so.6 and corrupt the heap inside the proprietary Bambu network
  # plugin during login (SIGABRT in std::locale::_Impl::~_Impl). Dropping it —
  # as the bambu-studio fix did — is a full local recompile; orca-slicer isn't
  # cached with this change.
  orca-slicer-relinked = pkgs2605.orca-slicer.overrideAttrs (old: {
    buildInputs = builtins.filter (p: (p.pname or "") != "gcc") old.buildInputs;
  });

  # Part 2 — runtime env: the plugin's bundled libcurl needs an explicit CA
  # bundle on NixOS, and the OAuth webview breaks under DMA-BUF compositing.
  orca-slicer-fixed = pkgs.symlinkJoin {
    name = "orca-slicer-fixed";
    paths = [ orca-slicer-relinked ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/orca-slicer \
        --set-default SSL_CERT_FILE "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt" \
        --set-default CURL_CA_BUNDLE "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt" \
        --set WEBKIT_DISABLE_DMABUF_RENDERER 1
    '';
  };
in
{
  options.dotfiles.apps.orca-slicer = {
    enable = lib.mkEnableOption "OrcaSlicer (pinned 26.05 build)" // {
      default = true;
    };

    # Part 1 above is a local ~1 h recompile (the relinked binary is uncached),
    # so it's only worth paying on hosts that actually log into Bambu cloud.
    # Off = the stock Hydra-cached 26.05 binary, identical apart from the fix
    # (laptop-nix flips this off in its host overlay).
    loginFix = lib.mkEnableOption "the locally-recompiled Bambu cloud-login fix" // {
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      (config.dotfiles.wrapGL (if cfg.loginFix then orca-slicer-fixed else pkgs2605.orca-slicer))
      # TEMPORARILY disabled so switches don't block on the one-time local
      # compile (unfree → uncached); re-enable once the build lands in the store.
      # (config.dotfiles.wrapGL pkgs2605.bambu-studio) # 02.05.00.67 — carries the cloud-login fix (nixpkgs#498307)
    ];
  };
}
