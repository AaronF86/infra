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

              # Soft-serve SSH
              tcp dport 23231 dnat to 10.44.0.3:23231
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
      allowedTCPPorts = [23231];
    };
  };
}
