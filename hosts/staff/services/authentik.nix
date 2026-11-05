{config, ...}: {
  sops.age.keyFile = "/var/lib/sops-nix/keys.txt";

  sops.secrets.authentik-env = {
    sopsFile = ../../../secrets/authentik.env.enc;
    format = "dotenv";
  };

  services.authentik = {
    enable = true;
    environmentFile = config.sops.secrets.authentik-env.path;

    settings = {
      listen.http = ["0.0.0.0:9000"];
      disable_startup_analytics = true;
      avatars = "initials";

      email = let
        relay = config.programs.msmtp.accounts.default;
      in {
        inherit (relay) host port from;
        username = relay.user;
        use_tls = true;
      };
    };
  };

  sops.templates.authentik-smtp-env.content = ''
    AUTHENTIK_EMAIL__PASSWORD=${config.sops.placeholder.smtp-password}
  '';
  systemd.services = let
    smtpEnv.serviceConfig.EnvironmentFile = [config.sops.templates.authentik-smtp-env.path];
  in {
    authentik = smtpEnv;
    authentik-worker = smtpEnv;
  };

  services.postgresqlBackup = {
    enable = true;
    databases = ["authentik"];
    location = "/var/lib/backup/postgresql";
    startAt = "03:30";
  };

  networking.firewall.interfaces.wg0.allowedTCPPorts = [9000];
}
