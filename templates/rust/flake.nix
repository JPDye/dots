{
  description = "Rust dev shell";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, rust-overlay, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ (import rust-overlay) ];
      };

      rust = pkgs.rust-bin.selectLatestNightlyWith (
        toolchain:
        toolchain.default.override {
          extensions = [
            "rust-src"
            "rust-analyzer"
            "clippy"
            "rustfmt"
          ];
        }
      );
    in
    {
      formatter.${system} = pkgs.nixfmt;

      devShells.${system}.default = pkgs.mkShell {
        # sccache transparently skips incremental rustc invocations (it cannot
        # cache them safely), so dev builds keep using cargo's per-function
        # incremental as normal. Wins land on release builds, fresh clones,
        # post-`cargo clean` recovery, and shared deps across projects.
        RUSTC_WRAPPER = "${pkgs.sccache}/bin/sccache";
        SCCACHE_CACHE_SIZE = "50G";

        buildInputs = with pkgs; [
          pkg-config

          rust
          mold
          clang
          sccache

          bacon

          cargo-nextest
          cargo-llvm-cov
          cargo-udeps
          cargo-machete
          cargo-flamegraph

          jq
        ];
      };
    };
}
