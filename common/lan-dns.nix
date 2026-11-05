_: let
  staff = "192.168.1.241";
  grimoire = "192.168.1.115";

  hosts = ["knot" "git" "spindle" "pds" "auth" "grafana" "panel"];
in {
  services.unbound = {
    enable = true;

    settings = {
      server = {
        interface = ["0.0.0.0"];
        access-control = [
          "127.0.0.0/8 allow"
          "192.168.1.0/24 allow"
        ];

        local-zone = [
          "\"aaronf86.tech.\" transparent"
          "\"pds.aaronf86.tech.\" redirect"
        ];
        local-data =
          map (h: "\"${h}.aaronf86.tech. 300 IN A ${staff}\"") hosts
          ++ ["\"cloud.aaronf86.tech. 300 IN A ${grimoire}\""];
      };

      forward-zone = [
        {
          name = ".";
          forward-tls-upstream = true;
          forward-addr = [
            "1.1.1.1@853#cloudflare-dns.com"
            "1.0.0.1@853#cloudflare-dns.com"
            "9.9.9.9@853#dns.quad9.net"
          ];
        }
      ];
    };
  };

  networking.firewall = {
    allowedTCPPorts = [53];
    allowedUDPPorts = [53];
  };
}
