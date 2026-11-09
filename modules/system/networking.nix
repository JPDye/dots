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
    # No inbound WireGuard opening: nothing here declares a WireGuard
    # interface, and a client tunnel needs none, because connection
    # tracking admits the replies. Tailscale's port is opened by
    # services.tailscale.openFirewall below, so it follows
    # services.tailscale.port.
    nftables.enable = true;
  };

  services.tailscale = {
    enable = true;
    openFirewall = true;
    useRoutingFeatures = "client";
  };

  environment.systemPackages = [
    pkgs.tailscale
    pkgs.nftables
    pkgs.conntrack-tools
    pkgs.tcpdump
  ];
}
