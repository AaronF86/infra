_: {
  boot.supportedFilesystems = ["cifs"];

  fileSystems."/mnt/storage" = {
    device = "//grimoire/storage";
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
      "noauto"
      "x-systemd.automount"
      "x-systemd.idle-timeout=60"
      "noatime"
    ];
  };
}
