{lib, ...}: {
  boot = {
    supportedFilesystems = lib.mkForce ["zfs"];
    kernelParams = ["zfs.zfs_arc_max=${toString (8 * 1024 * 1024 * 1024)}"];
  };

  networking.hostId = "5b86421b";

  services.zfs = {
    zed = {
      enableMail = true;
      settings = {
        ZED_EMAIL_ADDR = ["root"];
        ZED_NOTIFY_VERBOSE = true;
      };
    };

    autoScrub = {
      enable = true;
      interval = "monthly";
    };

    autoSnapshot = {
      enable = true;
      frequent = 4;
      hourly = 24;
      daily = 7;
      weekly = 4;
      monthly = 6;
    };
  };
}
