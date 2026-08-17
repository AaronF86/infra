{pkgs, ...}: {
  swapDevices = [
    {
      device = "/swapfile";
      size = 16 * 1024;
    }
  ];

  boot = {
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
      };
    };
    supportedFilesystems = ["btrfs"];
  };

  networking.networkmanager.enable = true;

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
    docker.enable = true;
  };

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
