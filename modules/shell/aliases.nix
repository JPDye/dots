{ config, lib, ... }:

let
  inherit (config.dotfiles) shell;
in
{
  # Published unconditionally (no enable toggle — this is one of the two
  # exception modules), but each alias is included only when the module that
  # installs its target is enabled, so an alias never points at a missing
  # binary on a host that trims a domain.
  _module.args.shellAliases = {
    vi = "hx";
    vim = "hx";
    nano = "hx";
  }
  # bat + eza come from integrations.nix
  // lib.optionalAttrs shell.integrations.enable {
    cat = "bat";
    ls = "eza -1";
    tree = "eza --tree --git-ignore";
  }
  # rg/fd/dust/procs/sd come from cli-tools.nix
  // lib.optionalAttrs shell.cliTools.enable {
    grep = "rg";
    find = "fd";
    du = "dust";
    ps = "procs";
    sed = "sd";
  };
}
