{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.dotfiles.dev.git;
in
{
  options.dotfiles.dev.git.enable = lib.mkEnableOption "git + delta" // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
    programs.delta = {
      enable = true;
      enableGitIntegration = true;
      options = {
        line-numbers = true;
        navigate = true;
        hyperlinks = true;
      };
    };

    programs.git = {
      enable = true;
      # gitFull, not git: the libsecret credential helper below only exists
      # in the full build.
      package = pkgs.gitFull;
      lfs.enable = true;
      signing.format = null;

      ignores = [
        ".direnv/"
        "/target"
        "/plans"
        "result"
        "result-*"
        "*.swp"
        "*.swo"
        "*~"
        ".DS_Store"
      ];

      settings = {
        user.name = "Joe";
        user.email = "jpzh.dye@gmail.com";

        alias = {
          st = "status";
          co = "checkout";
          sw = "switch";
          br = "branch";
          lg = "log --graph --pretty=format:'%C(yellow)%h%C(auto)%d %s %C(blue)(%cr) %C(green)<%an>' --abbrev-commit";
          last = "log -1 HEAD --stat";
          unstage = "reset HEAD --";
          amend = "commit --amend --no-edit";
        };

        # Credentials go to the Secret Service instead of cleartext
        # ~/.git-credentials. Every host runs gnome-keyring. Arch provisions
        # it via `nix run .#arch-pam-setup`.
        credential.helper = "libsecret";
        init.defaultBranch = "main";
        pull.rebase = true;
        push.autoSetupRemote = true;
        rebase.autoStash = true;
        merge.conflictStyle = "zdiff3";
        diff.algorithm = "histogram";
        fetch.prune = true;
        column.ui = "auto";
        branch.sort = "-committerdate";
      };
    };
  };
}
