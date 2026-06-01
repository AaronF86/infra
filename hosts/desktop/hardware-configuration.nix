{
  config,
  pkgs,
  ...
}: {
  swapDevices = [
    {
      device = "/swapfile";
      size = 16 * 1024;
    }
  ];

  boot.loader = {
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
  boot.supportedFilesystems = ["btrfs"];

  networking = {
    networkmanager = {
      enable = true;
    };
  };

  hardware.graphics = {
    enable = true;
  };

  services.xserver.videoDrivers = ["nvidia"];
  hardware.nvidia.open = false; # see the note above

  # Set up virtualisation
  virtualisation.libvirtd = {
    enable = true;

    # Enable TPM emulation (for Windows 11)
    qemu = {
      swtpm.enable = true;
    };
  };

  # Enable USB redirection
  virtualisation.spiceUSBRedirection.enable = true;

  # Allow VM management
  users.groups.libvirtd.members = ["aaron"];
  users.groups.kvm.members = ["aaron"];

  # Enable VM networking and file sharing
  environment.systemPackages = with pkgs; [
    # ... your other packages ...
    gnome-boxes # VM management
    dnsmasq # VM networking
    phodav # (optional) Share files with guest VMs
    pulseaudio
    alsa-utils
    pavucontrol # GUI audio control
    pwvucontrol # PipeWire GUI (optional)
    bluez
    bluez-tools
  ];

  # Realtime scheduling (important for PipeWire)
  security.rtkit.enable = true;

  # Disable PulseAudio (PipeWire replaces it)
  services.pulseaudio.enable = false;

  # PipeWire (audio server)
  services.pipewire = {
    enable = true;

    # ALSA compatibility
    alsa.enable = true;
    alsa.support32Bit = true;

    # PulseAudio compatibility layer
    pulse.enable = true;

    # Optional: JACK support (only if you need pro audio tools)
    # jack.enable = true;
  };

  # Recommended: better Bluetooth handling
  services.pipewire.wireplumber.enable = true;

  # Make sure your user is in audio group

  virtualisation.docker.enable = true;
  users.users.aaron.extraGroups = ["docker" "audio"];
}
