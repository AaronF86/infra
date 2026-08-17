{
  config,
  pkgs,
  ...
}: {
  boot = {
    loader = {
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot/efi";
      };
      grub = {
        enable = true;
        efiSupport = true;
        device = "nodev";
        useOSProber = true;
      };
    };
    supportedFilesystems = ["btrfs"];
    kernel.sysctl = {
      "vm.swappiness" = 10;
    };
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = ["amd_pstate=active"];
    blacklistedKernelModules = ["k10temp"];
    extraModulePackages = [config.boot.kernelPackages.zenpower];
    kernelModules = ["zenpower"];
  };

  hardware = {
    enableAllFirmware = true;
    firmware = [pkgs.linux-firmware pkgs.rtl8761b-firmware];
    cpu.amd.updateMicrocode = true;
    bluetooth.enable = true;
    graphics.enable = true;
  };

  services = {
    tlp.enable = true;
    xserver = {
      enable = true;
      videoDrivers = ["amdgpu"];
      libinput.enable = true;
    };
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };
    fprintd.enable = true;
    fstrim = {
      enable = true;
      interval = "weekly";
    };
  };

  networking.networkmanager = {
    enable = true;
    wifi.backend = "iwd";
  };
}
