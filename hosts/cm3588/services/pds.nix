{ ... }:

{
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
      NODE_OPTIONS = "--network-family-autoselection-attempt-timeout=500";
    };

    environmentFiles = [
      "/var/secrets/pds.env"
    ];
  };

  networking.firewall.interfaces.wg0.allowedTCPPorts = [ 3000 ];
}
