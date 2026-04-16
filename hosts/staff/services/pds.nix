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
      PDS_BLOBSTORE_DISK_LOCATION = "/mnt/storage/pds/blocks";
      PDS_REPORT_SERVICE_DID = "did:plc:e2nksyu6bnw6lczckjhqweau";
      NODE_OPTIONS = "--network-family-autoselection-attempt-timeout=500";
    };

    environmentFiles = [
      config.sops.secrets.pds-env.path
    ];
  };

  systemd.services.bluesky-pds = {
    after = ["mnt-storage.mount" "systemd-tmpfiles-setup.service" "systemd-tmpfiles-resetup.service"];
    wants = ["mnt-storage.mount"];
    serviceConfig.ReadWritePaths = [
      "/mnt/storage/pds"
      "/var/lib/bluesky-pds"
    ];
  };

  networking.firewall.interfaces.wg0.allowedTCPPorts = [3000];
}
