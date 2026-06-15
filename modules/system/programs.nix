{ pkgs, ... }:

{
  programs = {
    # The command-not-found handler hooks bash/zsh only — disabled because
    # the login shell is nushell. Keeps the ~80MB sqlite index out of every
    # system closure.
    command-not-found.enable = false;

    niri.enable = true;

    nix-ld = {
      enable = true;
      libraries = with pkgs; [
        stdenv.cc.cc.lib
        zlib
        openssl
        fuse3
        icu
        nss
        nspr
        libGL
      ];
    };

    gpu-screen-recorder.enable = true;

    wireshark = {
      enable = true;
      package = pkgs.wireshark-cli;
    };
  };
}
