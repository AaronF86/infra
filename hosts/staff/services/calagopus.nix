# Calagopus game-server panel (https://calagopus.com) at panel.aaronf86.tech, in its
# all-in-one image: the panel plus a bundled Wings, so staff is also the first game node.
# Wings drives the host's Docker through its socket, which is root on staff.
#
# Postgres and Redis are the host's (not upstream's compose sidecars), so the database
# rides the nightly postgresqlBackup → restic → grimoire like the rest. Server files in
# /var/lib/calagopus-wings get snapshotted live by restic too.
#
# Public: gateway traefik → wg0:8000 (panel) and gateway DNAT → wg0:2022 (SFTP).
# APP_ENABLE_WINGS_PROXY makes the panel proxy browser traffic to Wings, so Wings' own
# API stays on localhost; in the setup wizard, point the node at 127.0.0.1.
# Game ports (25565-25600) are published by Docker per server; the gateway DNATs that
# range here (hosts/gateway/services/nftables.nix). Game containers also *egress* via the
# gateway (games-via-gateway below), so Steam and players see 51.68.220.132, never home.
#
# Upgrade: bump image (tag + digest from hub.docker.com/r/calagopus/panel/tags).
{
  config,
  pkgs,
  ...
}: let
  port = 8000;
  sftpPort = 2022;
  redisPort = 6379;

  # Wings' Docker network for game containers (network.interfaces in its config)
  gameSubnet = "172.18.0.0/16";
  gamesTable = "100";

  image = "calagopus/panel:1.2.8-aio@sha256:0bc84ddaa3c9e5ed52c1b91435fd6f826835a754b9efc6ecfd8e6b467224cfcf";

  # Seed for the bundled Wings' base config. The AIO writes back to it, so it's copied out
  # of the store once (tmpfiles C) rather than mounted read-only
  wingsBase = pkgs.writeText "calagopus-wings-base.yml" ''
    app_name: Calagopus
  '';

  # JSON, not dotenv: sops-nix only honours `key` for YAML/JSON, so each password can
  # be its own file (Redis and psql read them raw)
  secret = key: {
    sopsFile = ../../../secrets/calagopus.json.enc;
    format = "json";
    inherit key;
  };
  ph = config.sops.placeholder;
in {
  sops.secrets = {
    # Losing this loses everything the panel encrypted in its database
    calagopus-encryption-key = secret "encryption_key";
    calagopus-db-password =
      secret "db_password"
      // {
        owner = "postgres";
        restartUnits = ["calagopus-db-password.service"];
      };
    calagopus-redis-password =
      secret "redis_password"
      // {
        owner = config.services.redis.servers.calagopus.user;
        restartUnits = ["redis-calagopus.service"];
      };
  };

  sops.templates."calagopus.env".restartUnits = ["docker-calagopus.service"];
  sops.templates."calagopus.env".content = ''
    APP_ENCRYPTION_KEY=${ph.calagopus-encryption-key}
    DATABASE_URL=postgresql://calagopus:${ph.calagopus-db-password}@127.0.0.1:5432/calagopus
    REDIS_URL=redis://:${ph.calagopus-redis-password}@127.0.0.1:${toString redisPort}
  '';

  virtualisation.docker.enable = true;

  services.postgresql = {
    ensureDatabases = ["calagopus"];
    ensureUsers = [
      {
        name = "calagopus";
        ensureDBOwnership = true;
        ensureClauses.login = true;
      }
    ];
  };
  services.postgresqlBackup.databases = ["calagopus"];

  # The container connects over TCP (127.0.0.1, md5 in the default pg_hba), so the role
  # needs a password; ensureUsers can't set one.
  systemd.services.calagopus-db-password = {
    description = "Set the calagopus Postgres role's password";
    after = ["postgresql-setup.service" "sops-nix.service"];
    requires = ["postgresql-setup.service"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "postgres";
    };
    script = ''
      ${config.services.postgresql.package}/bin/psql -v ON_ERROR_STOP=1 <<'EOF'
      \set pw `cat ${config.sops.secrets.calagopus-db-password.path}`
      ALTER ROLE calagopus PASSWORD :'pw';
      EOF
    '';
  };

  services.redis.servers.calagopus = {
    enable = true;
    bind = "127.0.0.1";
    port = redisPort;
    requirePassFile = config.sops.secrets.calagopus-redis-password.path;
  };

  virtualisation.oci-containers = {
    backend = "docker";
    containers.calagopus = {
      inherit image;
      environment = {
        TZ = config.time.timeZone;
        PORT = toString port;
        DATABASE_MIGRATE = "true";
        AIO_BASE_WINGS_CONFIGURATION = "/wings-config.yml";
        APP_DEBUG = "false";
        APP_LOG_DIRECTORY = "/var/log/calagopus";
        APP_PRIMARY = "true";
        APP_ENABLE_WINGS_PROXY = "true";
        APP_USE_DECRYPTION_CACHE = "true";
        APP_USE_INTERNAL_CACHE = "true";
      };
      environmentFiles = [config.sops.templates."calagopus.env".path];
      volumes = [
        "/var/lib/calagopus:/var/lib/calagopus"
        "/var/log/calagopus:/var/log/calagopus"
        "/var/lib/calagopus/wings-config.yml:/wings-config.yml"
        # Wings: game servers are sibling containers on the host's Docker, and their bind
        # mounts are host paths, so these must be the same path inside and out
        "/var/run/docker.sock:/var/run/docker.sock"
        "/var/lib/docker/containers:/var/lib/docker/containers"
        "/etc/calagopus-wings:/etc/calagopus-wings"
        "/var/lib/calagopus-wings:/var/lib/calagopus-wings"
        "/var/log/calagopus-wings:/var/log/calagopus-wings"
      ];
      # Host networking: reaches host Postgres/Redis on loopback, and Wings' SFTP and API
      # bind on staff directly
      extraOptions = ["--network=host"];
    };
  };

  systemd.services.docker-calagopus = {
    after = ["postgresql-setup.service" "calagopus-db-password.service" "redis-calagopus.service"];
    requires = ["calagopus-db-password.service" "redis-calagopus.service"];
  };

  # Game containers' internet traffic leaves through the gateway instead of the home line.
  # Rule 1 keeps every specific route in main (LAN, wg0, Docker bridges) and skips only its
  # default route; rule 2 then sends the rest to a table whose default is wg0. Docker's own
  # MASQUERADE for the subnet makes the source 10.44.0.3 on the way out, which the gateway
  # masquerades again onto ens3. Replies to DNAT'd inbound game traffic take the same path.
  #
  # Fails closed: the table's unreachable fallback outlives wg0, and stopping this unit
  # leaves the rules in place, so a dropped tunnel blocks game egress rather than leaking
  # it out the home line. partOf re-runs it when wg0 restarts (the interface's route goes
  # with it). To really undo it: ip rule del pref 1000; ip rule del pref 1001.
  systemd.services.games-via-gateway = let
    ip = "${pkgs.iproute2}/bin/ip";
  in {
    description = "Route Calagopus game containers' egress via the gateway";
    after = ["wireguard-wg0.service"];
    requires = ["wireguard-wg0.service"];
    partOf = ["wireguard-wg0.service"];
    wantedBy = ["wireguard-wg0.service" "multi-user.target"];
    before = ["docker-calagopus.service"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ${ip} route replace unreachable default metric 4096 table ${gamesTable}
      ${ip} route replace default dev wg0 metric 10 table ${gamesTable}
      ${ip} rule del pref 1000 2>/dev/null || true
      ${ip} rule del pref 1001 2>/dev/null || true
      ${ip} rule add pref 1000 from ${gameSubnet} lookup main suppress_prefixlength 0
      ${ip} rule add pref 1001 from ${gameSubnet} lookup ${gamesTable}
    '';
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/calagopus 0700 root root -"
    "C /var/lib/calagopus/wings-config.yml 0600 root root - ${wingsBase}"
    "d /var/log/calagopus 0700 root root -"
    "d /etc/calagopus-wings 0700 root root -"
    "d /var/lib/calagopus-wings 0755 root root -"
    "d /var/log/calagopus-wings 0700 root root -"
  ];

  networking.firewall = {
    # SFTP for LAN clients (and the gateway, which forwards public 2022 here)
    allowedTCPPorts = [sftpPort];
    interfaces.wg0.allowedTCPPorts = [port];
  };
}
