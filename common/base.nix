{
  lib,
  commonArgs,
  pkgs,
  ...
}: {
  services.openssh = {
    enable = true;
    ports = [2222];
    openFirewall = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;

      PubkeyAuthentication = true;

      PermitRootLogin = "no";

      X11Forwarding = false;
      AllowAgentForwarding = false;
      AllowTcpForwarding = "no";

      MaxAuthTries = 3;
      LoginGraceTime = "30s";
    };
  };

  users.users.aaron = {
    isNormalUser = true;
    extraGroups = ["wheel"];

    openssh.authorizedKeys.keys = commonArgs.sshKeys;
  };

  security.sudo = {
    enable = true;

    wheelNeedsPassword = false;
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  time.timeZone = "Europe/London";

  environment.systemPackages = with pkgs; [
    git
    curl
    tree
  ];

  system.stateVersion = "26.05";
}
