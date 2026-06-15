
## Environment addendum — this machine (opencode on a Nix flake + Nushell)

This skill is running inside **opencode** (not Claude Code), in a
Nix-flake-managed dotfiles repo, and the user's interactive shell is
**Nushell**. These notes override the generic defaults above wherever they
conflict.

- **`execute` dispatches the `improve-executor` opencode subagent.** The
  generic workflow above is written for Claude Code's Agent tool (a
  `general-purpose` subagent with `isolation: "worktree"`, on `opus`). opencode
  has neither that tool nor any Anthropic model here — so the `execute <plan>`
  variant instead dispatches the **`improve-executor`** subagent through
  opencode's task tool. That subagent is the default executor and is pinned to
  **gpt-oss-120b via Groq** (`groq/openai/gpt-oss-120b`); do not try to select a
  Claude/Anthropic model and do not override it unless the user names another in
  the command (`execute 003 <model>`). The executor runs in its own isolated
  worktree; you still review its diff as a tech lead and render a verdict — you
  never edit code yourself.
