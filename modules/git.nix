_:
{
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
    lfs.enable = true;

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

      credential.helper = "store";
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
}
