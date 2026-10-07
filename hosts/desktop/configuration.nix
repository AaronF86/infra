{pkgs, ...}: {
  imports = [
    ../../common/base.nix
    ./hardware-configuration.nix
    ../../common/workstation.nix
    ../../modules/kmscon.nix
    ./disk-config.nix
    ../../common/smb-client.nix
  ];

  networking = {
    hostName = "Desktop";
    hosts = {
      "192.168.1.115" = ["grimoire"];
      "192.168.1.241" = ["staff"];
    };
  };

  users.users.aaron.shell = pkgs.fish;
  programs.fish.enable = true;


  programs.steam = {
    enable = true;
    extraCompatPackages = with pkgs; [
      proton-ge-bin
    ];
    package = pkgs.steam.override {
      extraProfile = ''
        export STEAM_FORCE_DESKTOPSCALING=2
      '';
    };
  };

  boot.supportedFilesystems = ["ntfs"];

  fileSystems = {
    "/mnt/sda" = {
      device = "/dev/disk/by-uuid/CA8212FD8212EDA7";
      fsType = "ntfs3";
      options = ["uid=1000" "gid=1000" "umask=022" "nofail" "noatime" "force" "x-systemd.automount" "x-systemd.idle-timeout=60"];
    };
    "/mnt/sdb" = {
      device = "/dev/disk/by-uuid/C6CC-B0AA";
      fsType = "vfat";
      options = ["uid=1000" "gid=1000" "umask=022" "nofail" "noatime" "x-systemd.automount" "x-systemd.idle-timeout=60"];
    };
    "/mnt/sdc" = {
      device = "/dev/disk/by-uuid/50880CC4880CAB14";
      fsType = "ntfs3";
      options = ["uid=1000" "gid=1000" "umask=022" "nofail" "noatime" "x-systemd.automount" "x-systemd.idle-timeout=60"];
    };
  };
}
