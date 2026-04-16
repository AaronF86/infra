{
  config,
  lib,
  pkgs,
  ...
}: {
  boot.supportedFilesystems = ["cifs"];

  fileSystems."/mnt/storage" = {
    device = "//192.168.1.116/storage";
    fsType = "cifs";
    options = [
      "guest"
      "vers=3.1.1"
      "uid=0"
      "gid=0"
      "file_mode=0777"
      "dir_mode=0777"
      "_netdev"
      "nofail"
      "x-systemd.automount"
      "x-systemd.idle-timeout=10min"
      "noatime"
    ];
  };
}
