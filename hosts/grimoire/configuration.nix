{
  config,
  pkgs,
  lib,
  modulesPath,
  commonArgs,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ../../common/base.nix
    ./hardware-configuration.nix
    ./disk-config.nix
    ./raid.nix
  ];

  users.users.nixos = {
    isNormalUser = true;
    extraGroups = ["wheel"];

    openssh.authorizedKeys.keys = commonArgs.sshKeys;
  };

  networking.hostName = "grimoire";

  environment.systemPackages = with pkgs; [
    lm_sensors
    mtdutils
    i2c-tools
    minicom
  ];
}
