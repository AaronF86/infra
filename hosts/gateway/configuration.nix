{ lib
, pkgs
, ...
} @ args:
{
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix
  ];

  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
    devices = [ "nodev" ];
  };
  
  networking = {
    hostName = "Gateway";
    useDHCP = true;
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 80 443 ];
      allowedUDPPorts = [ 51820 ];
    };
  };

  time.timeZone = "Europe/London";

  services.openssh.enable = true;

  environment.systemPackages = map lib.lowPrio [
    pkgs.curl
    pkgs.gitMinimal
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
