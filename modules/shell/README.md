# shell

Everything related to the interactive shell environment: nushell config, CLI
tools, shell-agnostic integrations, and aliases.

## Layout

```
shell/
├── aliases.nix          shared shellAliases (consumed via _module.args)
├── cli-tools.nix        standalone command-line utilities
├── integrations.nix     programs with nushell hooks (zoxide, atuin, ...)
├── nushell.nix          programs.nushell config + script wiring
└── nushell/
    ├── welcome.nu       runs on shell start
    └── scaffolds.nu     project scaffolders (init-rust, ...)
```

`default.nix` imports the four `.nix` files. The two `.nu` files are
symlinked into `~/.config/nushell/` via `xdg.configFile`.

---

## CLI tools (`cli-tools.nix`)

Drop-in modern replacements for classic Unix tools, plus a few utilities.
Most are wired to old names via aliases — see [Aliases](#aliases).

| Tool       | Replaces      | What it does                                          |
| ---------- | ------------- | ----------------------------------------------------- |
| `rg`       | `grep`        | Recursive search; respects `.gitignore` by default.   |
| `fd`       | `find`        | File search with sane defaults and regex.             |
| `dust`     | `du`          | Disk usage, sorted, with bar chart.                   |
| `procs`    | `ps`          | Process list with colours and tree view (`procs --tree`). |
| `sd`       | `sed`         | Find-and-replace with regex (`sd 'foo' 'bar' file`).  |
| `jq`       | —             | JSON query tool. `... \| jq '.field'`.                |
| `tokei`    | —             | Count lines of code by language. `tokei .`.          |
| `glow`     | —             | Render markdown in the terminal. `glow README.md`.    |
| `tldr`     | `man`         | Concise example-driven help. `tldr tar`. (via `tealdeer`) |

`tealdeer` is configured to auto-update its cache.

---

## Shell integrations (`integrations.nix`)

Tools that hook into nushell's prompt, history, or completion.

### `zoxide` — smarter `cd`

Aliased to `cd` (via `--cmd cd`). Tracks directories you visit and lets you
jump by partial match.

```
cd home-manager       # standard
cd hm                 # if "home-manager" is in zoxide's database
cdi                   # interactive picker
```

### `carapace` — multi-shell completions

Provides completions for hundreds of CLIs in nushell. No usage — it just
makes tab completion smarter for things nushell wouldn't otherwise know
about (`gh`, `kubectl`, `cargo`, etc.).

### `atuin` — shell history

Replaces nushell's built-in history with a SQLite-backed one. Configured
with `search_mode = "fuzzy"`.

```
ctrl-r                # fuzzy search history
atuin search foo      # CLI search
atuin stats           # usage stats
```

### `direnv` (+ `nix-direnv`) — per-directory env

Auto-loads environment from a `.envrc` file when you `cd` into a directory.
With `nix-direnv` enabled, `use flake` in `.envrc` lazy-loads a flake's
`devShell`. Configured `silent` so no per-cd noise.

```
cd my-rust-project    # .envrc with `use flake` -> dev shell loads
direnv allow          # required once per .envrc to authorise it
direnv reload         # force re-eval
```

See `init-rust` below for the bootstrap.

### `bat` — `cat` with syntax highlighting

Aliased to `cat`. Pager set to `less -FR` (no pager for short output, raw
ANSI for colour).

### `eza` — `ls` replacement

Aliased to `ls` (compact one-column) and `tree` (recursive, respects
`.gitignore`). Configured to show git status, icons, and group directories
first.

```
ls                    # eza -1
ls -la                # passes through
tree                  # eza --tree --git-ignore
```

---

## Aliases (`aliases.nix`)

Defined once, exposed via `_module.args.shellAliases`. `nushell.nix`
consumes them with `inherit shellAliases;`. If another shell is added
later, it pulls from the same source.

| Alias  | Expands to             |
| ------ | ---------------------- |
| `vi`   | `hx`                   |
| `vim`  | `hx`                   |
| `nano` | `hx`                   |
| `cat`  | `bat`                  |
| `grep` | `rg`                   |
| `du`   | `dust`                 |
| `ps`   | `procs`                |
| `sed`  | `sd`                   |
| `ls`   | `eza -1`               |
| `tree` | `eza --tree --git-ignore` |

To bypass an alias, prefix with `^`: `^cat file` runs the real `cat`.

---

## Nushell scripts

### `welcome.nu`

Runs at shell startup. Prints a centred `fastfetch` system-info banner —
chooses `nixos_small` logo for narrow terminals (<80 cols), full `nixos`
logo otherwise.

Wired in `nushell.nix` via:

```nu
use ~/.config/nushell/welcome.nu
welcome
```

### `scaffolds.nu`

Project scaffolders. Each one drops a flake template (`flake.nix`,
`flake.lock`, `.envrc`) into the cwd, `git init`s if needed, stages the new
files, and `direnv allow`s. The dev shell auto-activates on the next prompt.

| Command       | Template            | Toolchain                                                    |
| ------------- | ------------------- | ------------------------------------------------------------ |
| `init-rust`   | `templates/rust/`   | rust 1.90 stable, `mold`, sccache, bacon, cargo-nextest, etc.  |
| `init-python` | `templates/python/` | python 3.13, uv, ruff, basedpyright                          |
| `init-go`     | `templates/go/`     | go, gopls, delve, golangci-lint, gotools                     |

Usage:

```
mkdir my-project && cd my-project
init-rust                 # or init-python, init-go
```

To add another scaffolder, append a `def` to `scaffolds.nu` — it's already
imported with `use ... *` so any new function is in scope. Add a matching
template under `templates/<name>/` and register it in the top-level
`flake.nix` `templates` block.

---

## Adding a new tool

Pick the right file:

- **Just a binary** (no shell hook, no config): add to `cli-tools.nix`.
- **Has a `programs.<name>` module with a nushell integration**: add to
  `integrations.nix`.
- **An alias mapping**: add to `aliases.nix`.

Then `git add` the change (flakes ignore untracked files) and `nh switch`.
