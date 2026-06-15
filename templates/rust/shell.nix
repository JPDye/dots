# Rust dev shell — non-flake. Loaded by `.envrc` via direnv's `use nix`, which
# reads this file straight off disk: no flake.lock, and (unlike a flake) no
# requirement that the file be git-tracked. nixpkgs + rust-overlay are pinned by
# revision/hash inline so the toolchain stays fully reproducible.
let
  nixpkgs = builtins.fetchTarball {
    url = "https://github.com/nixos/nixpkgs/archive/1c3fe55ad329cbcb28471bb30f05c9827f724c76.tar.gz";
    sha256 = "sha256-bxrdOn8SCOv8tN4JbTF/TXq7kjo9ag4M+C8yzzIRYbE=";
  };
  rust-overlay = builtins.fetchTarball {
    url = "https://github.com/oxalica/rust-overlay/archive/09b556f18dacc39e97a46e0a1cba47af7b3af1d8.tar.gz";
    sha256 = "sha256-TXilQ8MwFFtZs7HSogSI/LJzAS63nicE8iF63iB93WM=";
  };
  pkgs = import nixpkgs { overlays = [ (import rust-overlay) ]; };

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

  # mold reaches cargo through the linker config (env var below) rather than
  # rustflags: cargo replaces rustflags instead of merging, and it's the key
  # workspaces most often own (--cfg flags, target-cpu), so we leave it alone.
  mold-clang = pkgs.writeShellScriptBin "mold-clang" ''
    exec ${pkgs.clang}/bin/clang --ld-path=${pkgs.mold}/bin/mold "$@"
  '';
in
pkgs.mkShell {
  # sccache transparently skips incremental rustc invocations (it cannot cache
  # them safely), so dev builds keep cargo's per-function incremental as normal.
  # Wins land on release builds, fresh clones, post-`cargo clean` recovery, and
  # shared deps across projects.
  RUSTC_WRAPPER = "${pkgs.sccache}/bin/sccache";
  SCCACHE_CACHE_SIZE = "50G";

  # Dev-profile speedups as cargo config env vars rather than a
  # .cargo/config.toml dropped into the project: scoped to this shell, nothing
  # on disk to conflict with a workspace's own cargo config. line-tables-only
  # keeps file:line backtraces while giving the linker far less debuginfo to
  # chew through on every relink.
  CARGO_PROFILE_DEV_DEBUG = "line-tables-only";
  # Pair with line-tables-only on Linux: keeps debuginfo in separate .o files so
  # the linker can skip reprocessing it when only code changed.
  CARGO_PROFILE_DEV_SPLIT_DEBUGINFO = "unpacked";
  CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER = "${mold-clang}/bin/mold-clang";

  # Cap build/test parallelism so a `--workspace` build doesn't exhaust RAM and
  # thrash swap — rustc and the linker peak hard, and one process per core on a
  # RAM-tight host tips it into disk paging that freezes the whole machine.
  # Hardcoded by choice rather than derived from the host: a flat 6 leaves
  # headroom for a browser + the rest of the desktop alongside the build.
  CARGO_BUILD_JOBS = "6";
  NEXTEST_TEST_THREADS = "6";

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
}
