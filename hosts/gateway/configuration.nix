{...}: {
  imports = [
    ../../common/base.nix
    ./hardware-configuration.nix
    ./disk-config.nix
    # VPS: no SMART, and staff scrapes node over wg0 (port opened in services/tunnel.nix)
    (import ../../common/metrics.nix {smart = false;})
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
      allowedUDPPorts = [51820];
    };
  };

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
  };
}
