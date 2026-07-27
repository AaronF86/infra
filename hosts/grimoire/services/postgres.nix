{
  config,
  pkgs,
  lib,
  ...
}: {
  sops.age.keyFile = "/var/lib/sops-nix/keys.txt";

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_18;

    enableTCPIP = true;

    settings = {
      listen_addresses = "*";
    };

    ensureDatabases = [
      "stalwart"
    ];

    ensureUsers = [
      {
        name = "stalwart";
        ensureDBOwnership = true;

        ensureClauses = {
          login = true;
        };
      }
    ];


authentication = lib.mkOverride 10 ''
  local   all        all                           peer
  local   all        postgres                      peer

  host    all        all        192.168.1.0/24     scram-sha-256

  host    all        all        127.0.0.1/32       scram-sha-256
  host    all        all        ::1/128            scram-sha-256
'';
  };

  services.prometheus.exporters.postgres = {
    enable = true;
    listenAddress = "127.0.0.1";
    port = 9187;
  };

  networking.firewall.allowedTCPPorts = [
    5432
    9187
  ];
}
