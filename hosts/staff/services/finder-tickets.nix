# SMP Finder's Discord ticket bot (~/Documents/SMPFinder-Mono/finder-tickets).
# Runs paid ads only: tickets need finder-montior, which isn't deployed here.
# Talks to fin over loopback; its database rides along in the nightly
# postgresqlBackup → restic → grimoire.
#
# Source is a path: flake input, so after changing the bot:
#   nix flake update finder-tickets && colmena apply --on staff
{
  config,
  pkgs,
  inputs,
  ...
}: let
  package = pkgs.buildGoModule {
    pname = "finder-tickets";
    version = "0.1.0";
    # Only the Go sources: the checkout also holds a built binary and .direnv.
    src = pkgs.lib.cleanSourceWith {
      src = inputs.finder-tickets;
      filter = path: _type: let
        rel = pkgs.lib.removePrefix "${toString inputs.finder-tickets}/" (toString path);
        top = builtins.head (pkgs.lib.splitString "/" rel);
      in
        builtins.elem top ["go.mod" "go.sum" "cmd" "internal"];
    };
    # After changing go.mod/go.sum: set to "" and copy the hash from the build error.
    vendorHash = "sha256-IlgvjAUURzfDvpV5DwKw9XNEbt6SkWwskyCdC/5pMz0=";
    subPackages = ["cmd/finder-tickets"];
    env.CGO_ENABLED = 0;
    ldflags = ["-s" "-w"];
  };
in {
  sops.secrets.finder-tickets-env = {
    sopsFile = ../../../secrets/finder-tickets.env.enc;
    format = "dotenv";
    owner = "tickets";
  };

  users.users.tickets = {
    isSystemUser = true;
    group = "tickets";
  };
  users.groups.tickets = {};

  # Peer auth over the socket: the unix user and the role are both "tickets".
  services.postgresql = {
    ensureDatabases = ["tickets"];
    ensureUsers = [
      {
        name = "tickets";
        ensureDBOwnership = true;
        ensureClauses.login = true;
      }
    ];
  };
  services.postgresqlBackup.databases = ["tickets"];

  systemd.services.finder-tickets = {
    description = "SMP Finder Discord ticket bot (paid ads)";
    wantedBy = ["multi-user.target"];
    after = ["network-online.target" "sops-nix.service" "postgresql-setup.service" "smpsales-fin.service"];
    wants = ["network-online.target"];
    requires = ["postgresql-setup.service"];

    environment = {
      DATABASE_URL = "postgres:///tickets?host=/run/postgresql&user=tickets";
      # SMP Finder
      GUILD_ID = "1186462339743105045";
      STAFF_ROLE_ID = "1186503098550730792"; # Manager: can run /ad-invoice
      # Required by config, unused while tickets are off.
      TICKET_CATEGORY_ID = "1392582382594556005"; # General Tickets
      PARTNER_INVITE_CHANNEL_ID = "1393690008921051146"; # partner-with-us
      ADMIN_USER_IDS = "1186441653251215452";
      TICKETS_ENABLED = "false";
      FIN_URL = "http://127.0.0.1:${toString config.services.smpsales-onboarding.finPort}";
      ADS_CATEGORY_NORMAL = "1392553917245689876"; # ---- SMP Partners ----
      ADS_CATEGORY_IMPORTANT = "1392553964800577556"; # ---- Important ----
      ADS_CATEGORY_EXCLUSIVE = "none"; # top of the server
    };

    serviceConfig = {
      # DISCORD_TOKEN, FIN_ADS_TOKEN
      EnvironmentFile = config.sops.secrets.finder-tickets-env.path;
      ExecStart = "${package}/bin/finder-tickets";
      User = "tickets";
      Group = "tickets";
      Restart = "always";
      RestartSec = 5;

      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      PrivateDevices = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      RestrictAddressFamilies = ["AF_UNIX" "AF_INET" "AF_INET6"];
      RestrictNamespaces = true;
      LockPersonality = true;
      MemoryDenyWriteExecute = true;
      SystemCallArchitectures = "native";
    };
  };
}
