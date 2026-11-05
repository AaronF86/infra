{
  lib,
  pkgs,
  ...
}: {
  imports = [
    ../../common/base.nix
    ../../common/lan-dns.nix
    ../../common/smtp.nix
    ./hardware-configuration.nix
    ./disk-config.nix
    ./raid.nix
    ./services/tunnel.nix
    ./services/soft-serve.nix
  ];

  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        # Keep the second disk's ESP identical so either disk boots.
        # bootctl also installs EFI/BOOT/BOOTX64.EFI, so no NVRAM entry is needed.
        extraInstallCommands = ''
          ${pkgs.rsync}/bin/rsync -rt --delete --modify-window=2 /boot/ /boot-fallback/
        '';
      };
      efi.canTouchEfiVariables = false;
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
