{config, ...}: {
  sops.secrets = {
    smpsales-onboard-env = {
      sopsFile = ../../../secrets/smpsales-onboard.env.enc;
      format = "dotenv";
      owner = "smponboard";
    };
    # authentik units use DynamicUser; systemd reads EnvironmentFile as root first
    smpsales-authentik-env = {
      sopsFile = ../../../secrets/smpsales-authentik.env.enc;
      format = "dotenv";
    };
  };

  services.smpsales-onboarding = {
    enable = true;
    domain = "onboard.smpsales.team";
    authDomain = "auth.smpsales.team";
    listenAddress = "0.0.0.0";
    onboardEnvFile = config.sops.secrets.smpsales-onboard-env.path;
    authentikEnvFile = config.sops.secrets.smpsales-authentik-env.path;
    finSopsFile = ../../../secrets/smpsales-fin.env.enc;
    finPublicDomain = "pay.smpsales.team";
    finAdsProductId = "prod_aodxdEyJLVoAc";
    finRolesProductId = "prod_hE1dfZd23eb1i";
    finAdsShareAccountId = "biz_veMkiUMZuvcEZC";
  };

  networking.firewall.interfaces.wg0.allowedTCPPorts = with config.services.smpsales-onboarding; [httpPort finPort];
}
