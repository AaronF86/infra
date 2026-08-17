_: {
  services.samba = {
    enable = true;
    openFirewall = true;
    nmbd.enable = false;
    winbindd.enable = false;

    settings = {
      global = {
        security = "user";
        "map to guest" = "Bad User";
        "server min protocol" = "SMB2";
      };

      storage = {
        path = "/mnt/storage";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "force user" = "root";
        "force group" = "root";
        "create mask" = "0777";
        "directory mask" = "0777";
        comment = "Grimoire NVMe storage";
      };
    };
  };
}
