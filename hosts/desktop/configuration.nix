{
  config,
  pkgs,
  lib,
  commonArgs,
  ...
}: {
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
      "192.168.1.112" = [ "grimoire" ];
      "192.168.1.242" = [ "staff" ];
    };
  };

  users.users.aaron.shell = pkgs.fish;
  programs.fish.enable = true;

  environment.systemPackages = with pkgs; [
    neovim
    tmux
    syncthing
    acpi
  ];

  programs.steam.enable = true;

  boot.supportedFilesystems = ["ntfs"];

  fileSystems."/mnt/sda" = {
    device = "/dev/disk/by-uuid/CA8212FD8212EDA7";
    fsType = "ntfs3";
    options = ["uid=1000" "gid=1000" "umask=022" "nofail" "noatime"];
  };

  fileSystems."/mnt/sdb" = {
    device = "/dev/disk/by-uuid/C6CC-B0AA";
    fsType = "vfat";
    options = ["uid=1000" "gid=1000" "umask=022" "nofail" "noatime"];
  };

  fileSystems."/mnt/sdc" = {
    device = "/dev/disk/by-uuid/50880CC4880CAB14";
    fsType = "ntfs3";
    options = ["uid=1000" "gid=1000" "umask=022" "nofail" "noatime"];
  };
}
