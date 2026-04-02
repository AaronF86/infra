{ lib
, pkgs
, ...
} @ args:
{
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;

networking = {
  hostName = "Grimoire";
  useDHCP = true;

  firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
  };
};

services.logrotate.checkConfig = false;

    imports = [
    ./hardware-configuration.nix
  ];

  time.timeZone = "Europe/London";

  services.chrony.enable = true;

  services.openssh.enable = true;

  nix = {
    extraOptions = ''
      experimental-features = nix-command flakes ca-derivations
      warn-dirty = false
      keep-outputs = false
    '';
  };

  environment.systemPackages = map lib.lowPrio [
    pkgs.curl
    pkgs.gitMinimal
    pkgs.openssl
    pkgs.bluesky-pdsadmin
  ];

  users.users.aaron = {
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = args.commonArgs.sshKeys;
    isNormalUser = true;
    hashedPassword = "$6$qJWtwBqAgNGiayJs$CF/fwUOpWMY1FJSa7xnOjmcRlGM4TNYihyMFXdS3huM5TDBjFOxptcDiFn71g10DQcEbvIwaug.NeYltoxIAh1";
  };

  users.users.root.openssh.authorizedKeys.keys = args.commonArgs.sshKeys;

  security.sudo.extraRules = [
    {
      users = [ "aaron" ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  system.stateVersion = "25.05";
}