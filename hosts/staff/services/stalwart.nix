{config, lib, ...}: let
  rootDomain = "aaronf86.tech";
  mailDomain = "notify.${rootDomain}";
  mxHost = "mail.${mailDomain}";
in {
  sops.age.keyFile = "/var/lib/sops-nix/keys.txt";

  sops.secrets = {
    stalwart-admin-pw = {
      sopsFile = ../../../secrets/stalwart.json.enc;
      format = "json";
      key = "ADMIN_PASSWORD";
      owner = "stalwart";
      group = "stalwart";
      mode = "0400";
    };

    stalwart-mail-pw = {
      sopsFile = ../../../secrets/stalwart.json.enc;
      format = "json";
      key = "MAIL_PASSWORD";
      owner = "stalwart";
      group = "stalwart";
      mode = "0400";
    };

    stalwart-db-password = {
      sopsFile = ../../../secrets/stalwart.json.enc;
      format = "json";
      key = "POSTGRES_PASSWORD";
      owner = "stalwart";
      group = "stalwart";
      mode = "0400";
    };

    stalwart-dkim-key = {
      sopsFile = ../../../secrets/stalwart-dkim.json.enc;
      format = "json";
      key = "DKIM_PRIVATE_KEY";
      owner = "stalwart";
      group = "stalwart";
      mode = "0400";
    };

    cloudflare-token = {
      sopsFile = ../../../secrets/cloudflare-staff.json.enc;
      format = "json";
      key = "CF_DNS_API_TOKEN";
    };
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "admin@${mailDomain}";
    certs.${mxHost} = {
      dnsProvider = "cloudflare";
      credentialFiles."CF_DNS_API_TOKEN_FILE" = config.sops.secrets.cloudflare-token.path;
      group = "stalwart";
    };
  };

  services.stalwart = {
    enable = true;
    stateVersion = "26.05";
    settings = {
      server = {
        hostname = mxHost;
        security = {
          trusted-networks = [
            "10.44.0.0/16"
          ];

          ip-blocking = false;
        };
        listener = {
          smtp = {
            protocol = "smtp";
            bind = "[::]:25";
            proxy.trusted-networks = ["10.44.0.1/32"];
          };

          submissions = {
            bind = "[::]:465";
            protocol = "smtp";
            tls.implicit = true;
            proxy.trusted-networks = ["10.44.0.1/32"];
          };

          imaps = {
            bind = "[::]:993";
            protocol = "imap";
            tls.implicit = true;
            proxy.trusted-networks = ["10.44.0.1/32"];
          };

          jmap = {
            bind = "[::]:8080";
            url = "https://mail.${mailDomain}";
            protocol = "http";
            allowed-networks = ["10.44.0.0/16"];
          };

          management = {
            bind = "127.0.0.1:8081";
            protocol = "http";
          };
        };
      };

      store.postgresql = {
        type = "postgresql";
        host = "grimoire.local";
        port = 5432;

        database = "stalwart";
        user = "stalwart";

        passwordFile = config.sops.secrets.stalwart-db-password.path;

        max-connections = 10;
      };

      signature.notify = {
        algorithm = "rsa-sha256";
        private-key = "%{file:${config.sops.secrets.stalwart-dkim-key.path}}%";
        domain = mailDomain;
        selector = "mail";
        headers = ["From" "To" "Date" "Subject" "Message-ID"];
        canonicalization = "relaxed/relaxed";
        expire = "7d";
        set-body-length = false;
        report = false;
      };

      certificate.default = {
        cert = "%{file:/var/lib/acme/${mxHost}/cert.pem}%";
        private-key = "%{file:/var/lib/acme/${mxHost}/key.pem}%";
      };

      authentication.fallback-admin = {
        user = "admin";

        secret = "%{file:${config.sops.secrets.stalwart-admin-pw.path}}%";
      };

      gateway.gateway-relay = {
        address = "10.44.0.1";
        port = 2525;
        protocol = "smtp";
        tls.enable = false;
        auth.enable = false;
      };

      queue.strategy.route = "'gateway-relay'";

      session.data.sign = ["'notify'"];
    };
  };

  networking.firewall.interfaces.wg0.allowedTCPPorts = [
    25
    465
    587
    993
    143
    8080
    8081
  ];
}
