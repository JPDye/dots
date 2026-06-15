- **Nushell for anything the user runs by hand.** Every command you hand *the
  user* to copy-paste must be valid Nushell, not bash/POSIX. Differences that
  bite: command substitution is `(cmd)` (often `(cmd | str trim)`), never
  `$(cmd)`; variables are `let x = (...)`; sequence steps with `;`;
  environment is `$env.VAR` / `with-env { ... }`, never `export VAR=…`; there
  is no C-style `for … do … done`. External binaries and their flags (`git`,
  `cargo`, `rg`, …) work unchanged.
  *Scope:* this applies to user-facing commands only. Commands an executor or
  reviewer **subagent** runs through its own shell execute in bash — leave
  plan verification gates and done-criteria commands in POSIX/bash so the
  executor can run them. Do **not** rewrite those into Nushell.

- **New dependencies go through the flake, never an imperative installer.** If
  a plan needs a tool, binary, runtime, or language server that isn't already
  available, the plan's step is to add it to the Nix flake — the appropriate
  module under `modules/` or the relevant devshell / `flake.nix` — and bring
  it in via a rebuild (`nix develop`, `home-manager switch`, or
  `nixos-rebuild`, as fits the repo). Plans must **not** instruct the executor
  to run `npm i -g`, `pip install`, `cargo install`, `brew`, `apt`, or any
  other imperative installer. Name the exact file and attribute to edit, and
  give the command that proves the tool now resolves as the verification step.

- **End every completed worktree-backed plan with a copy-paste Nushell cleanup
  command.** When an `execute` review reaches APPROVE (or any worktree-backed
  plan is finished), the final output must include a ready-to-run Nushell
  command that removes the executor's isolated worktree and deletes its
  branch, using the real path and branch from the run:

  ```nu
  git worktree remove <worktree-path>; git branch -d <branch-name>
  ```

  `-d` refuses to drop an unmerged branch — switch to `git branch -D
  <branch-name>` to discard unmerged work, and add `--force` to `git worktree
  remove` if the tree is dirty. Present it as the explicit last step so the
  user tears everything down in a single paste.
