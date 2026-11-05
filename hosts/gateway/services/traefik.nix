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

        websecure = {
          address = ":443";
          transport.respondingTimeouts.readTimeout = "3600s";
          http = {
            tls.options = "modern";
            middlewares = ["hsts@file"];
          };
        };
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

    dynamicConfigOptions.http.middlewares.hsts.headers = {
      stsSeconds = 31536000;
      stsIncludeSubdomains = true;
      stsPreload = true;
    };

    dynamicConfigOptions.tls.options.modern = {
      minVersion = "VersionTLS12";
      cipherSuites = [
        "TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256"
        "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256"
        "TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384"
        "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384"
        "TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305"
        "TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305"
      ];
      sniStrict = true;
    };

    dynamicConfigOptions.http = {
      routers = {
        spindle = {
          entryPoints = ["websecure"];
          rule = "Host(`spindle.aaronf86.tech`)";
          service = "spindle";
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

        git = {
          entryPoints = ["websecure"];
          rule = "Host(`git.aaronf86.tech`)";
          service = "git";
          tls.certResolver = "letsencrypt";
        };

        auth = {
          entryPoints = ["websecure"];
          rule = "Host(`auth.aaronf86.tech`)";
          service = "auth";
          tls.certResolver = "letsencrypt";
        };

        cloud = {
          entryPoints = ["websecure"];
          rule = "Host(`cloud.aaronf86.tech`)";
          service = "cloud";
          tls.certResolver = "letsencrypt";
        };

        panel = {
          entryPoints = ["websecure"];
          rule = "Host(`panel.aaronf86.tech`)";
          service = "panel";
          tls.certResolver = "letsencrypt";
        };

        smpsales-auth = {
          entryPoints = ["websecure"];
          rule = "Host(`auth.smpsales.team`)";
          service = "auth";
          tls.certResolver = "letsencrypt";
        };

        smpsales-onboard = {
          entryPoints = ["websecure"];
          rule = "Host(`onboard.smpsales.team`) && !PathPrefix(`/api/internal`)";
          service = "smpsales-onboard";
          tls.certResolver = "letsencrypt";
        };

        smpsales-pay = {
          entryPoints = ["websecure"];
          rule = "Host(`pay.smpsales.team`) && (Path(`/ads`) || PathPrefix(`/ads/`) || PathPrefix(`/auth/`) || Path(`/webhooks/whop`) || PathPrefix(`/api/ads/`))";
          service = "smpsales-fin";
          tls.certResolver = "letsencrypt";
        };

        smpsales-pay-applepay = {
          entryPoints = ["websecure"];
          rule = "Host(`pay.smpsales.team`) && Path(`/.well-known/apple-developer-merchantid-domain-association`)";
          service = "staff-apple-pay";
          tls.certResolver = "letsencrypt";
        };
      };

      serversTransports.staff-tls.serverName = "cloud.aaronf86.tech";

      services = {
        spindle.loadBalancer.servers = [
          {url = "http://10.44.0.3:6555";}
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

        git.loadBalancer.servers = [
          {url = "http://10.44.0.3:23232";}
        ];

        auth.loadBalancer.servers = [
          {url = "http://10.44.0.3:9000";}
        ];

        smpsales-onboard.loadBalancer.servers = [
          {url = "http://10.44.0.3:8095";}
        ];

        smpsales-fin.loadBalancer.servers = [
          {url = "http://10.44.0.3:8090";}
        ];

        staff-apple-pay.loadBalancer.servers = [
          {url = "http://10.44.0.3:8091";}
        ];

        panel.loadBalancer.servers = [
          {url = "http://10.44.0.3:8000";}
        ];

        cloud.loadBalancer = {
          servers = [{url = "https://10.44.0.3";}];
          serversTransport = "staff-tls";
        };
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
