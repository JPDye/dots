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

      # mold reaches cargo through the `linker` config key (env var below)
      # rather than rustflags: cargo replaces rustflags instead of merging
      # them, and it's the key workspaces most often own (--cfg flags,
      # target-cpu), so we leave it untouched.
      mold-clang = pkgs.writeShellScriptBin "mold-clang" ''
        exec ${pkgs.clang}/bin/clang --ld-path=${pkgs.mold}/bin/mold "$@"
      '';
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

        # Dev-profile speedups as cargo config env vars rather than a
        # .cargo/config.toml dropped into the project: scoped to this shell,
        # nothing on disk to conflict with a workspace's own cargo config.
        # Drop full DWARF for line-tables-only: backtraces still resolve to
        # file:line, but the linker has dramatically less debuginfo to chew
        # through on every relink — the dominant cost of the hot-loop edit
        # cycle.
        CARGO_PROFILE_DEV_DEBUG = "line-tables-only";
        # Pair with line-tables-only on Linux: keeps debuginfo in separate .o
        # files so the linker can skip reprocessing it when only code changed.
        CARGO_PROFILE_DEV_SPLIT_DEBUGINFO = "unpacked";
        CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER = "${mold-clang}/bin/mold-clang";

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
