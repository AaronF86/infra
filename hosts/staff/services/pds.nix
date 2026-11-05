{config, ...}: {
  sops.age.keyFile = "/var/lib/sops-nix/keys.txt";

  sops.secrets.pds-env = {
    sopsFile = ../../../secrets/pds.env.enc;
    format = "dotenv";
  };

  services.bluesky-pds = {
    enable = true;

    pdsadmin.enable = true;
    goat.enable = true;

    settings = {
      PDS_ADMIN_EMAIL = "aaron@aaronf86.tech";
      PDS_HOST = "0.0.0.0";
      PDS_HOSTNAME = "pds.aaronf86.tech";
      PDS_PORT = 3000;
      PDS_SERVICE_HANDLE_DOMAINS = ".pds.aaronf86.tech";
      PDS_DATA_DIRECTORY = "/var/lib/bluesky-pds";
      PDS_BLOBSTORE_DISK_LOCATION = "/var/lib/bluesky-pds/blocks";
      PDS_REPORT_SERVICE_DID = "did:plc:e2nksyu6bnw6lczckjhqweau";
      NODE_OPTIONS = "--network-family-autoselection-attempt-timeout=500";
    };

    # Later files win, so the template overrides the old Stalwart SMTP settings still in pds.env.enc
    environmentFiles = [
      config.sops.secrets.pds-env.path
      config.sops.templates.pds-smtp-env.path
    ];
  };

  sops.templates.pds-smtp-env.content = let
    relay = config.programs.msmtp.accounts.default;
    user = builtins.replaceStrings ["@"] ["%40"] relay.user;
  in ''
    PDS_EMAIL_SMTP_URL=smtp://${user}:${config.sops.placeholder.smtp-password}@${relay.host}:${toString relay.port}
    PDS_EMAIL_FROM_ADDRESS=${relay.from}
  '';

  # The module sandboxes with ProtectSystem=strict and only grants /var/lib/pds;
  # PDS_DATA_DIRECTORY (and the blobs under it) need explicit write access
  systemd.services.bluesky-pds.serviceConfig.ReadWritePaths = ["/var/lib/bluesky-pds"];

  networking.firewall.interfaces.wg0.allowedTCPPorts = [3000];
}
