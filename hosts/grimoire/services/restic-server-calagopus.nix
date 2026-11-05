{
  config,
  pkgs,
  ...
}: let
  dataDir = "/mnt/storage/backups/restic-calagopus";
  port = 8001;

  htpasswd = pkgs.writeText "restic-calagopus-htpasswd" ''
    calagopus:$2y$10$uhp0EGHUHBH2AgFQtIFaIeWn1Y0b90Xj7CaDeCEuFF.nwUh.pG4Le
  '';
in {
  systemd.services.restic-rest-server-calagopus = {
    description = "Restic REST Server (Calagopus)";
    after = ["network.target" "restic-rest-server-calagopus.socket"];
    requires = ["restic-rest-server-calagopus.socket"];
    wantedBy = ["multi-user.target"];
    unitConfig.RequiresMountsFor = [dataDir];
    serviceConfig = {
      ExecStart = "${config.services.restic.server.package}/bin/rest-server --path ${dataDir} --htpasswd-file ${htpasswd} --private-repos";
      Type = "simple";
      User = "restic";
      Group = "restic";

      CapabilityBoundingSet = "";
      LockPersonality = true;
      MemoryDenyWriteExecute = true;
      NoNewPrivileges = true;
      PrivateNetwork = true;
      PrivateTmp = true;
      PrivateUsers = true;
      ProtectClock = true;
      ProtectHome = true;
      ProtectHostname = true;
      ProtectKernelLogs = true;
      ProtectProc = "invisible";
      ProtectSystem = "strict";
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      PrivateDevices = true;
      ReadWritePaths = [dataDir];
      RemoveIPC = true;
      RestrictAddressFamilies = "none";
      RestrictNamespaces = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      SystemCallArchitectures = "native";
      SystemCallFilter = "@system-service";
      UMask = 27;
    };
  };

  systemd.sockets.restic-rest-server-calagopus = {
    listenStreams = [(toString port)];
    wantedBy = ["sockets.target"];
    socketConfig = {
      ReusePort = true;
      FreeBind = true;
    };
  };

  systemd.tmpfiles.rules = [
    "d ${dataDir} 0700 restic restic -"
  ];

  networking.firewall.allowedTCPPorts = [port];
}
