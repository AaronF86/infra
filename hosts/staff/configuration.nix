{
  config,
  pkgs,
  lib,
  commonArgs,
  ...
}: {
  imports = [
    ../../common/base.nix
    ../../common/smb-client.nix
    ./hardware-configuration.nix
  ];

  boot.loader.grub = {
    enable = true;
    device = "nodev";
    efiSupport = true;
  };

  boot.loader.efi.canTouchEfiVariables = true;
  networking = {
    hostName = "staff";
    useDHCP = true;
  };
}
