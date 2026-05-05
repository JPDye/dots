{ config, lib, ... }:

let
  cfg = config.dotfiles.dev.bacon;
in
{
  options.dotfiles.dev.bacon.enable = lib.mkEnableOption "bacon (rust auto-runner) defaults" // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
    # bacon merges this user prefs file with each project's bacon.toml.
    # The jobs and keybindings here are added to every project automatically.
    # Requires `cargo-llvm-cov` + `cargo-nextest` in the project's dev shell
    # (the rust template under `templates/rust/` already includes both).
    xdg.configFile."bacon/prefs.toml".text = ''
      default_job = "clippy"
      summary = true
      wrap = true
      reverse = false

      [jobs.cov]
      command = ["cargo", "llvm-cov", "--all-features", "--workspace", "--color", "always"]
      need_stdout = true
      apply_to = "*.rs"

      [jobs.cov-html]
      command = ["cargo", "llvm-cov", "--all-features", "--workspace", "--html", "--color", "always"]
      need_stdout = true
      on_success = "back"
      apply_to = "*.rs"

      [jobs.nextest]
      command = ["cargo", "nextest", "run", "--color", "always", "--hide-progress-bar", "--failure-output", "final"]
      need_stdout = true
      analyzer = "nextest"

      [keybindings]
      v = "job:cov"
      shift-v = "job:cov-html"
      n = "job:nextest"
    '';
  };
}
