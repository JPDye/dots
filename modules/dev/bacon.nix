{ config, lib, ... }:

let
  cfg = config.dotfiles.dev.bacon;

  # bacon's skin only accepts 8-bit ANSI indexes (0–255), so we map each
  # palette hex to its nearest xterm-256 cube/grayscale index by hand.
  ansi = {
    bg0 = 234;
    bg1 = 237;
    bg2 = 239;
    bg3 = 241;
    mid = 236;
    fg3 = 144;
    fg2 = 187;
    fg1 = 223;
    fg0 = 230;
    red = 131;
    green = 101;
    yellow = 143;
    orange = 137;
    blue = 66;
    pink = 138;
  };
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

      [skin]
      status_fg = ${toString ansi.fg1}
      status_bg = ${toString ansi.bg1}
      key_fg = ${toString ansi.orange}
      status_key_fg = ${toString ansi.orange}
      project_name_badge_fg = ${toString ansi.bg0}
      project_name_badge_bg = ${toString ansi.fg2}
      job_label_badge_fg = ${toString ansi.bg0}
      job_label_badge_bg = ${toString ansi.orange}
      errors_badge_fg = ${toString ansi.bg0}
      errors_badge_bg = ${toString ansi.red}
      test_fails_badge_fg = ${toString ansi.bg0}
      test_fails_badge_bg = ${toString ansi.orange}
      test_pass_badge_fg = ${toString ansi.bg0}
      test_pass_badge_bg = ${toString ansi.green}
      warnings_badge_fg = ${toString ansi.bg0}
      warnings_badge_bg = ${toString ansi.orange}
      command_error_badge_fg = ${toString ansi.bg0}
      command_error_badge_bg = ${toString ansi.red}
      dismissed_badge_fg = ${toString ansi.bg0}
      dismissed_badge_bg = ${toString ansi.blue}
      change_badge_fg = ${toString ansi.bg0}
      change_badge_bg = ${toString ansi.blue}
      computing_fg = ${toString ansi.bg0}
      computing_bg = ${toString ansi.pink}
      found_fg = ${toString ansi.orange}
      found_selected_bg = ${toString ansi.bg2}
      search_input_prefix_fg = ${toString ansi.orange}
      search_summary_fg = ${toString ansi.orange}
      menu_border = ${toString ansi.bg2}
      menu_bg = ${toString ansi.bg1}
      menu_item_bg = ${toString ansi.bg1}
      menu_item_selected_bg = ${toString ansi.bg2}
      menu_item_fg = ${toString ansi.fg2}
      menu_item_selected_fg = ${toString ansi.fg0}
    '';
  };
}
