{ pkgs, ... }:

{
  networking = {
    nameservers = [
      "1.1.1.1"
      "1.0.0.1"
    ];
    networkmanager = {
      enable = true;
      dns = "none";
      wifi.powersave = true;
    };
    firewall.allowedUDPPorts = [
      51820 # wireguard
      41641 # tailscale
    ];
    nftables.enable = true;
  };

  services.tailscale = {
    enable = true;
    useRoutingFeatures = "client";
  };

  environment.systemPackages = [
    pkgs.tailscale
    pkgs.nftables
    pkgs.conntrack-tools
    pkgs.tcpdump
  ];
}
