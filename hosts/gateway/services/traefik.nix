{config, ...}: {
  sops.secrets.cloudflare-dns-token = {
    sopsFile = ../../../secrets/cloudflare.env.enc;
    format = "dotenv";
    owner = "traefik";
    group = "traefik";
    mode = "0400";
  };

  services.traefik = {
    enable = true;
    environmentFiles = [config.sops.secrets.cloudflare-dns-token.path];

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
          resolvers = ["1.1.1.1:53" "8.8.8.8:53"];
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

        pterodactyl-panel = {
          entryPoints = ["websecure"];
          rule = "Host(`panel.aaronf86.tech`)";
          service = "pterodactyl-panel";
          tls.certResolver = "letsencrypt";
        };

        pterodactyl-wings = {
          entryPoints = ["websecure"];
          rule = "Host(`wings.aaronf86.tech`)";
          service = "pterodactyl-wings";
          tls.certResolver = "letsencrypt";
        };

        git = {
          entryPoints = ["websecure"];
          rule = "Host(`git.aaronf86.tech`)";
          service = "git";
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

        pterodactyl-panel.loadBalancer.servers = [
          {url = "http://10.44.0.3:80";}
        ];

        pterodactyl-wings.loadBalancer.servers = [
          {url = "http://10.44.0.3:8090";}
        ];

        git.loadBalancer.servers = [
          {url = "http://10.44.0.3:23232";}
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
