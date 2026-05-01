{
  description = "Rust dev shell";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, rust-overlay, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ (import rust-overlay) ];
      };

      rust = pkgs.rust-bin.stable."1.90.0".default.override {
        extensions = [ "rust-src" "rust-analyzer" "clippy" "rustfmt" ];
      };

      # Uncomment for latest nightly:
      # rust = pkgs.rust-bin.selectLatestNightlyWith (toolchain:
      #   toolchain.default.override {
      #     extensions = [ "rust-src" "rust-analyzer" "clippy" "rustfmt" ];
      #   });
    in
    {
      formatter.${system} = pkgs.nixpkgs-fmt;

      devShells.${system}.default = pkgs.mkShell {
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

        # mold linker via clang driver; scoped to the dev shell so the
        # project workspace stays free of cargo config files.
        CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER = "clang";
        CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_RUSTFLAGS = "-C link-arg=-fuse-ld=mold";

        # sccache: caches compiled crates across projects. Requires
        # CARGO_INCREMENTAL=0 (sccache and incremental compilation are
        # mutually exclusive). Trade-off: faster cold/dep rebuilds, slightly
        # slower hot-loop edits within a single project.
        RUSTC_WRAPPER = "sccache";
        CARGO_INCREMENTAL = "0";

        shellHook = ''
          unset RUSTFLAGS
          command -v mold  >/dev/null || echo "WARNING: mold not found in PATH; mold linker will not be used"
          command -v clang >/dev/null || echo "WARNING: clang not found in PATH; mold linker will not be used"
        '';
      };
    };
}
