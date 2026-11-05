{pkgs, ...}: let
  dataDir = "/mnt/storage/backups/restic";

  htpasswd = pkgs.writeText "restic-htpasswd" ''
    staff:$2y$05$gCzeJPVwTr69F0J0uICE2.JLiKzNq.fuhN2LpUsZaVv8B59NJ0hju
  '';
in {
  services.restic.server = {
    enable = true;
    inherit dataDir;
    listenAddress = "8000";

    appendOnly = true;
    privateRepos = true;
    htpasswd-file = htpasswd;
  };

  systemd = {
    tmpfiles.rules = [
      "d ${dataDir} 0700 restic restic -"
    ];

    services.restic-rest-server.unitConfig.RequiresMountsFor = [dataDir];
  };

  networking.firewall.allowedTCPPorts = [8000];
}
