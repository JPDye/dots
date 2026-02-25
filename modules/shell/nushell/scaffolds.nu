# Scaffold a project from a template in this flake:
#   - copies template files (flake.nix / flake.lock / .envrc) into cwd
#   - git inits if needed, stages the new files (so nix flake can see them)
#   - allows direnv so the dev shell auto-activates
def scaffold [name: string] {
  let flake = $"($env.HOME)/.config/nix"
  nix flake init -t $"($flake)#($name)"
  if not (".git" | path exists) { ^git init -q }
  ^git add .envrc flake.nix flake.lock
  ^direnv allow
  print $"($name) dev shell scaffolded. activates on next prompt."
}

export def init-rust   [] { scaffold "rust" }
export def init-python [] { scaffold "python" }
export def init-go     [] { scaffold "go" }
