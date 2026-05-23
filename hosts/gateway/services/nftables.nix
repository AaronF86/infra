{config, ...}: {
  networking.nftables.enable = true;

  networking.nftables.tables.nat = {
    family = "ip";
    content = ''
      chain prerouting {
        type nat hook prerouting priority -100;

        # Mail → Stalwart
        tcp dport 25  dnat to 10.44.0.3:25
        tcp dport 465 dnat to 10.44.0.3:465
        tcp dport 587 dnat to 10.44.0.3:587
        tcp dport 993 dnat to 10.44.0.3:993
        tcp dport 143 dnat to 10.44.0.3:143
      }

      chain postrouting {
        type nat hook postrouting priority 100;

        # IMPORTANT: use your WAN interface
        oifname "enp1s0" masquerade
      }
    '';
  };

  networking.firewall = {
    enable = true;

    # allow forwarding traffic through gateway
    allowedTCPPorts = [25 465 587 993 143];
  };
}
