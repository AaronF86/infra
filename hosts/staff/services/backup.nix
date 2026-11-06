{config, ...}: {
  sops.age.keyFile = "/var/lib/sops-nix/keys.txt";

  sops.secrets = {
    restic-repository = {
      sopsFile = ../../../secrets/restic-staff.json.enc;
      format = "json";
      key = "RESTIC_REPOSITORY";
    };

    restic-password = {
      sopsFile = ../../../secrets/restic-staff.json.enc;
      format = "json";
      key = "RESTIC_PASSWORD";
    };
  };

  services.restic.backups.grimoire = {
    initialize = true;
    repositoryFile = config.sops.secrets.restic-repository.path;
    passwordFile = config.sops.secrets.restic-password.path;

    paths = [
      "/var/lib"
      "/etc/ssh"
      "/home"
    ];

    exclude = [
      "/var/lib/docker"
      "/var/lib/systemd/coredump"
      "/var/lib/postgresql"
    ];

    backupPrepareCommand = "systemctl stop bluesky-pds knot-rs";
    backupCleanupCommand = "systemctl start bluesky-pds knot-rs";

    timerConfig = {
      OnCalendar = "04:00";
      Persistent = true;
      RandomizedDelaySec = "30m";
    };
  };
}
