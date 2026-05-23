{
  config,
  lib,
  ...
}: let
  rootDomain = "aaronf86.tech";
  mailDomain = "notify.${rootDomain}";
  mxHost = "mail.${mailDomain}";
in {
  sops.age.keyFile = "/var/lib/sops-nix/keys.txt";

  sops.secrets = {
    stalwart-admin-pw = {
      sopsFile = ../../../secrets/stalwart.env.enc;
      format = "dotenv";
      key = "ADMIN_PASSWORD";
      owner = "stalwart";
      group = "stalwart";
      mode = "0400";
    };

    stalwart-mail-pw = {
      sopsFile = ../../../secrets/stalwart.env.enc;
      format = "dotenv";
      key = "MAIL_PASSWORD";
      owner = "stalwart";
      group = "stalwart";
      mode = "0400";
    };

    stalwart-db-password = {
      sopsFile = ../../../secrets/stalwart.env.enc;
      format = "dotenv";
      key = "POSTGRES_PASSWORD";
      owner = "stalwart";
      group = "stalwart";
      mode = "0400";
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
        tls = {
          enable = true;
          implicit = true;
        };

        listener = {
          smtp = {
            protocol = "smtp";
            bind = "[::]:25";
          };

          submissions = {
            bind = "[::]:465";
            protocol = "smtp";
            tls.implicit = true;
          };

          imaps = {
            bind = "[::]:993";
            protocol = "imap";
            tls.implicit = true;
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
        host = "192.168.1.116";
        port = 5432;

        database = "stalwart";
        user = "stalwart";

        passwordFile = config.sops.secrets.stalwart-db-password.path;

        max-connections = 10;
      };

      authentication.fallback-admin = {
        user = "admin";

        secret = "%{file:${config.sops.secrets.stalwart-admin-pw.path}}%";
      };
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
