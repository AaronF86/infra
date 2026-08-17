_: {
  networking = {
    nftables = {
      enable = true;
      tables = {
        mss = {
          family = "ip";
          content = ''
            chain forward {
              type filter hook forward priority mangle;
              tcp flags syn tcp option maxseg size set rt mtu
            }
          '';
        };
        nat = {
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

              # Soft-serve SSH
              tcp dport 23231 dnat to 10.44.0.3:23231

              # Game servers → Wings
              tcp dport 25565-25600 dnat to 10.44.0.3
              udp dport 25565-25600 dnat to 10.44.0.3
              udp dport 67 dnat to 10.44.0.3
            }

            chain postrouting {
              type nat hook postrouting priority 100;

              oifname "ens3" masquerade
              oifname "wg0" masquerade
            }
          '';
        };
      };
    };
    firewall = {
      enable = true;
      allowedTCPPorts = [25 465 587 993 143 23231] ++ (builtins.genList (i: 25565 + i) 36);
      allowedUDPPorts = [67] ++ builtins.genList (i: 25565 + i) 36;
    };
  };
}
