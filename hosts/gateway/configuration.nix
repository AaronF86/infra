{
  lib,
  pkgs,
  ...
} @ args: {
  imports = [
    ../../common/base.nix
    ./hardware-configuration.nix
    ./disk-config.nix
  ];

  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
    devices = ["nodev"];
  };

  networking = {
    hostName = "Gateway";
    useDHCP = true;
    firewall = {
      enable = true;
      allowedTCPPorts = [22 2222 25 80 443 465 993];
      allowedUDPPorts = [51820];
    };
  };

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
  };
}
