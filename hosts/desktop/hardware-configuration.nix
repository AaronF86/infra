{
  pkgs,
  lib,
  ...
}: {
  swapDevices = [
    {
      device = "/swapfile";
      size = 16 * 1024;
    }
  ];

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    loader = {
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
      grub = {
        enable = true;
        efiSupport = true;
        device = "nodev";
        useOSProber = true;
        timeout = 1;
      };
    };
    supportedFilesystems = ["btrfs"];
  };

  networking.networkmanager = {
    enable = true;
  };

  hardware = {
    graphics.enable = true;
    nvidia.open = false;
  };

  virtualisation = {
    libvirtd = {
      enable = true;
      qemu.swtpm.enable = true;
    };
    spiceUSBRedirection.enable = true;
    docker = {
      enable = true;
      enableOnBoot = false;
    };
  };

  systemd.services.docker.wantedBy = lib.mkForce [];

  users = {
    groups = {
      libvirtd.members = ["aaron"];
      kvm.members = ["aaron"];
    };
    users.aaron.extraGroups = ["docker" "audio"];
  };

  environment.systemPackages = with pkgs; [
    gnome-boxes
    dnsmasq
    phodav
    pulseaudio
    alsa-utils
    pavucontrol
    pwvucontrol
    bluez
    bluez-tools
  ];

  security.rtkit.enable = true;

  services = {
    xserver.videoDrivers = ["nvidia"];
    pulseaudio.enable = false;
    pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      pulse.enable = true;
      wireplumber.enable = true;
    };
  };
}
