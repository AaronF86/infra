{
  config,
  pkgs,
  ...
}: let
  staff = "192.168.1.241";
  storage = "/mnt/storage";
  relay = config.programs.msmtp.accounts.default;
in {
  sops.templates.nextcloud-secrets = {
    content = builtins.toJSON {mail_smtppassword = config.sops.placeholder.smtp-password;};
    owner = "nextcloud";
  };

  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud35;
    hostName = "cloud.aaronf86.tech";
    https = true;

    datadir = "${storage}/nextcloud";
    maxUploadSize = "16G";
    phpOptions."opcache.interned_strings_buffer" = "32";
    configureRedis = true;

    database.createLocally = true;
    config = {
      dbtype = "pgsql";
    };

    settings = {
      trusted_proxies = [staff];
      overwriteprotocol = "https";
      "overwrite.cli.url" = "https://${config.services.nextcloud.hostName}";
      default_phone_region = "GB";
      maintenance_window_start = 2;
      allow_local_remote_servers = true;
      log_type = "file";
      serverid = 1;

      mail_smtpmode = "smtp";
      mail_smtphost = relay.host;
      mail_smtpport = relay.port;
      mail_smtpsecure = "";
      mail_smtpauth = true;
      mail_smtpname = relay.user;
      mail_from_address = "no-reply";
      mail_domain = "aaronf86.tech";
    };
    secretFile = config.sops.templates.nextcloud-secrets.path;

    extraApps = {
      inherit (config.services.nextcloud.package.packages.apps) user_oidc;
    };
    extraAppsEnable = true;
  };

  services.postgresql = {
    package = pkgs.postgresql_18;
    dataDir = "${storage}/postgresql/${config.services.postgresql.package.psqlSchema}";
  };
  systemd.tmpfiles.rules = [
    "d ${config.services.postgresql.dataDir} 0750 postgres postgres -"
  ];

  services.postgresqlBackup = {
    enable = true;
    databases = ["nextcloud"];
    location = "${storage}/backups/postgresql";
    startAt = "03:30";
  };

  systemd.services = let
    needs = paths: {unitConfig.RequiresMountsFor = paths;};
    app = needs ["${storage}/nextcloud" "${storage}/postgresql" "${storage}/share"];
  in {
    postgresql = needs ["${storage}/postgresql"];
    nextcloud-setup = app;
    nextcloud-cron = app;
    phpfpm-nextcloud = app;
    postgresqlBackup-nextcloud = needs ["${storage}/postgresql" "${storage}/backups"];
  };

  sops.secrets.cloudflare-token = {
    sopsFile = ../../../secrets/cloudflare-staff.json.enc;
    format = "json";
    key = "CF_DNS_API_TOKEN";
  };
  security.acme = {
    acceptTerms = true;
    defaults.email = "aaron@aaronf86.tech";
    certs.${config.services.nextcloud.hostName} = {
      dnsProvider = "cloudflare";
      dnsResolver = "1.1.1.1:53";
      credentialFiles."CF_DNS_API_TOKEN_FILE" = config.sops.secrets.cloudflare-token.path;
      group = "nginx";
    };
  };

  services.nginx.virtualHosts.${config.services.nextcloud.hostName} = {
    addSSL = true;
    useACMEHost = config.services.nextcloud.hostName;
  };

  networking.firewall.allowedTCPPorts = [443];
  networking.firewall.extraCommands = ''
    iptables -A nixos-fw -p tcp -s ${staff} --dport 80 -j nixos-fw-accept
  '';
}
