# Scaffold a project from a template in this flake:
#   - copies the template files into cwd
#   - flake-based templates (python, go) are invisible to nix until tracked, so
#     git-init and stage them; shell.nix-based templates (rust) are read off
#     disk by `use nix` and need no git at all — skip the dance for those
#   - allows direnv so the dev shell auto-activates
def scaffold [name: string] {
  let flake = $"($env.HOME)/.config/nix"
  nix flake init -t $"($flake)#($name)"
  if ("flake.nix" | path exists) {
    if not (".git" | path exists) { ^git init -q }
    ^git add flake.nix flake.lock
  }
  ^direnv allow
  print $"($name) dev shell scaffolded. activates on next prompt."
}

export def init-rust   [] { scaffold "rust" }
export def init-python [] { scaffold "python" }
export def init-go     [] { scaffold "go" }
export def init-typst  [] { scaffold "typst" }
