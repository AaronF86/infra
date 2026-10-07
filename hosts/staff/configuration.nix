{lib, ...}: {
  imports = [
    ../../common/base.nix
    ../../common/smb-client.nix
    ./hardware-configuration.nix
    ./services/tunnel.nix
    ./services/soft-serve.nix
    ./services/stalwart.nix
  ];

  boot = {
    loader = {
      grub = {
        enable = true;
        device = "nodev";
        efiSupport = true;
      };
      efi.canTouchEfiVariables = true;
    };
    kernelModules = ["vhost_vsock"];
  };

  networking = {
    hostName = "staff";
    useDHCP = true;
    hosts = {
      "192.168.1.115" = ["grimoire"];
    };
  };

  services.openssh.settings.AllowTcpForwarding = lib.mkForce "local";

  nixpkgs.config.permittedInsecurePackages = [
    "pnpm-9.15.9"
  ];
}
