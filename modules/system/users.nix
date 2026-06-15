{ pkgs, ... }:

{
  users.users.jd = {
    shell = pkgs.nushell;
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "wireshark"
    ];
  };

  environment.systemPackages = [ pkgs.git ];
}
