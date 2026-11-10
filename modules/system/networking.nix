{ lib, pkgs, ... }:

{
  networking = {
    # Static resolvers, deliberately not DHCP's. With systemd-resolved
    # below they are the global DNS, and NetworkManager (dns = "none") never
    # pushes a link's DHCP servers over them. mkForce because nixpkgs'
    # resolved module sets dns = "systemd-resolved" at normal priority the
    # moment resolved is on, and the two definitions conflict.
    nameservers = [
      "1.1.1.1"
      "1.0.0.1"
    ];
    networkmanager = {
      enable = true;
      dns = lib.mkForce "none";
      wifi.powersave = true;
    };
    # No inbound WireGuard opening: nothing here declares a WireGuard
    # interface, and a client tunnel needs none, because connection
    # tracking admits the replies. Tailscale's port is opened by
    # services.tailscale.openFirewall below, so it follows
    # services.tailscale.port.
    nftables.enable = true;
  };

  # Without resolved, openresolv writes the static nameservers first in
  # /etc/resolv.conf and Tailscale's 100.100.100.100 after them, and glibc
  # takes Cloudflare's NXDOMAIN for a MagicDNS name as final. With resolved,
  # Tailscale registers its server as per-link DNS for tailscale0 with the
  # tailnet domains routed to it, and everything else still goes to the
  # static resolvers above. The Arch host already resolves MagicDNS names.
  services.resolved.enable = true;

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
