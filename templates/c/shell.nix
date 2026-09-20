# C23 dev shell — non-flake. Loaded by `.envrc` via direnv's `use nix`, which
# reads this file straight off disk: no flake.lock, and (unlike a flake) no
# requirement that the file be git-tracked. nixpkgs is pinned by revision/hash
# inline so the toolchain stays reproducible.
let
  nixpkgs = builtins.fetchTarball {
    url = "https://github.com/nixos/nixpkgs/archive/1c3fe55ad329cbcb28471bb30f05c9827f724c76.tar.gz";
    sha256 = "sha256-bxrdOn8SCOv8tN4JbTF/TXq7kjo9ag4M+C8yzzIRYbE=";
  };
  pkgs = import nixpkgs { };

  # The shell swaps the default stdenv (GCC) for clangStdenv, so `cc` and `$CC`
  # resolve to Clang. This also keeps pkgs.clang out of `packages`, where it
  # would collide with clang-tools: both install binaries under the same names.
  stdenv = pkgs.clangStdenv;

  # clangd runs as an editor subprocess, outside the compiler wrapper that
  # clangStdenv installs, so it reads its flags from this file. -std=c23 is the
  # line that matters: without it clangd assumes an older standard and reports
  # constexpr, nullptr, and auto as errors.
  #
  # The -isystem paths pin Clang's builtin headers and the C library headers,
  # the same ones the wrapper passes to clang. They keep the editor and the
  # compiler on one set of headers.
  #
  # Once the project has a Makefile, `bear -- make` writes a per-file
  # compile_commands.json, which clangd prefers over this blanket file.
  compileFlags = pkgs.writeText "compile_flags.txt" ''
    -std=c23
    -Wall
    -Wextra
    -Wpedantic
    -isystem${stdenv.cc}/resource-root/include
    -isystem${pkgs.glibc.dev}/include
  '';
in
pkgs.mkShell.override { inherit stdenv; } {
  packages = with pkgs; [
    # clangd, clang-format, and clang-tidy. Version-matched to the compiler.
    clang-tools

    # Records compiler calls from a build and writes compile_commands.json.
    # Unused until this project gains a Makefile. Run `bear -- make` then.
    bear

    gdb

    # ASan cannot see reads of uninitialized memory, one of C's classic bug
    # classes. MSan can, but needs every library instrumented, which is not
    # practical here. Valgrind's memcheck catches it with no recompilation, so
    # it complements the sanitizers rather than repeating them. Run an
    # uninstrumented binary under it: sanitizers and valgrind fight.
    valgrind

    # Turns the sanitizers' raw addresses into file:line. Without it on PATH,
    # UBSAN_OPTIONS=print_stacktrace below produces nothing useful.
    llvm
  ];

  CC = "clang";

  # GNU make's built-in rule for a lone .c file runs `$(CC) $(CFLAGS)
  # $(LDFLAGS)`, so `make hello` compiles hello.c with these flags and no
  # Makefile at all. The rule compiles and links in one step, which is what the
  # sanitizers need: they must be present at link time as well as compile time.
  #
  # -fsanitize=address,undefined reports memory and undefined-behavior faults
  # at runtime, with a line number. The cost: the binary runs slower, and an
  # undefined-behavior demonstration aborts instead of showing you its strange
  # result. Drop the -fsanitize flag to see the raw behavior.
  #
  # -fno-sanitize-recover=all makes UBSan abort at the first fault. Without it
  # UBSan prints a line and carries on, so a later fault hides the first one.
  #
  # -g3 rather than -g keeps macro definitions in the debug info, so gdb can
  # expand a macro. C leans on macros more than most languages.
  #
  # Consider adding -Wconversion (implicit narrowing) and -Wshadow (an inner
  # declaration hiding an outer one). Both catch classic C mistakes. Both are
  # noisy, so they are left off by default.
  CFLAGS = "-std=c23 -Wall -Wextra -Wpedantic -g3 -O1 -fsanitize=address,undefined -fno-sanitize-recover=all -fno-omit-frame-pointer";

  # Sanitizer runtime options. The compile-time flags above decide what is
  # checked. These decide how a report reads. Defaults are terse: UBSan prints
  # one line with no stack trace.
  UBSAN_OPTIONS = "print_stacktrace=1:halt_on_error=1";
  ASAN_OPTIONS = "detect_stack_use_after_return=1:strict_string_checks=1";

  # Write the clangd flags file on first entry only. An edited copy survives.
  shellHook = ''
    if [ ! -e compile_flags.txt ]; then
      cp ${compileFlags} compile_flags.txt
      chmod u+w compile_flags.txt
      echo "shell.nix: wrote compile_flags.txt for clangd"
    fi
    echo "C23 shell: $(clang --version | head -1)"
  '';
}
