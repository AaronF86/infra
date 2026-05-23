{config, ...}: {
  services.traefik = {
    enable = true;

    staticConfigOptions = {
      entryPoints = {
        web = {
          address = ":80";
          http.redirections.entrypoint = {
            to = "websecure";
            scheme = "https";
          };
        };

        websecure.address = ":443";
      };

      api = {
        dashboard = false;
        insecure = false;
      };

      certificatesResolvers.letsencrypt.acme = {
        email = "aaron@aaronf86.tech";
        storage = "${config.services.traefik.dataDir}/acme.json";
        dnsChallenge = {
          provider = "cloudflare";
        };
      };
    };

    dynamicConfigOptions.http = {
      routers = {
        spindle = {
          entryPoints = ["websecure"];
          rule = "Host(`spindle.aaronf86.tech`)";
          service = "spindle";
          tls.certResolver = "letsencrypt";
        };
        mailadmin = {
          entryPoints = ["websecure"];
          rule = "Host(`webadmin.notify.aaronf86.tech`)";
          service = "mailadmin";
          tls.certResolver = "letsencrypt";
        };

        mail = {
          entryPoints = ["websecure"];
          rule = "Host(`mail.notify.aaronf86.tech`)";
          service = "mail";
          tls.certResolver = "letsencrypt";
        };

        pds = {
          entryPoints = ["websecure"];
          rule = "Host(`pds.aaronf86.tech`)";
          service = "pds";
          tls.certResolver = "letsencrypt";
        };

        knot = {
          entryPoints = ["websecure"];
          rule = "Host(`knot.aaronf86.tech`)";
          service = "knot";
          tls.certResolver = "letsencrypt";
        };

        staff-files = {
          entryPoints = ["websecure"];
          rule = "Host(`fs.aaronf86.tech`)";
          service = "staff-files";
          tls.certResolver = "letsencrypt";
        };
      };

      services = {
        spindle.loadBalancer.servers = [
          {url = "http://10.44.0.3:6555";}
        ];

        mailadmin.loadBalancer.servers = [
          {url = "http://10.44.0.3:8081";}
        ];

        mail.loadBalancer.servers = [
          {url = "http://10.44.0.3:8080";}
        ];

        staff-files.loadBalancer.servers = [
          {url = "http://10.44.0.3:8088";}
        ];

        pds.loadBalancer.servers = [
          {url = "http://10.44.0.3:3000";}
        ];

        knot.loadBalancer.servers = [
          {url = "http://10.44.0.3:5555";}
        ];
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/traefik 0750 traefik traefik -"
    "f /var/lib/traefik/acme.json 600 traefik traefik -"
  ];

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
