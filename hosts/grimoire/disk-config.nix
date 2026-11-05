{lib, ...}: let
  drives = {
    nvme1 = "/dev/disk/by-id/nvme-eui.00000000000000000026b7283c87beb5";
    nvme2 = "/dev/disk/by-id/nvme-eui.00000000000000000026b7283c87c0e5";
    nvme3 = "/dev/disk/by-id/nvme-eui.00000000000000000026b7283b03dbb5";
    nvme4 = "/dev/disk/by-id/nvme-eui.00000000000000000026b7283b03da75";
  };

  dataset = mountpoint: options: {
    type = "zfs_fs";
    inherit mountpoint;
    mountOptions = ["nofail"];
    options = {mountpoint = "legacy";} // options;
  };
in {
  disko.devices = {
    disk =
      lib.mapAttrs (_: device: {
        type = "disk";
        inherit device;

        content = {
          type = "gpt";

          partitions = {
            zfs = {
              size = "100%";

              content = {
                type = "zfs";
                pool = "storage";
              };
            };
          };
        };
      })
      drives;

    zpool = {
      storage = {
        type = "zpool";
        mode = "raidz1";
        mountpoint = "/mnt/storage";
        mountOptions = ["nofail"];

        options = {
          ashift = "12";
          autotrim = "on";
        };

        rootFsOptions = {
          mountpoint = "legacy";
          compression = "zstd";
          atime = "off";
          xattr = "sa";
          acltype = "posixacl";
          "com.sun:auto-snapshot" = "false";
        };

        datasets = {
          share = dataset "/mnt/storage/share" {
            recordsize = "1M";
            "com.sun:auto-snapshot" = "true";
          };

          nextcloud = dataset "/mnt/storage/nextcloud" {
            "com.sun:auto-snapshot" = "true";
          };

          postgresql = dataset "/mnt/storage/postgresql" {
            recordsize = "16K";
          };

          backups = dataset "/mnt/storage/backups" {
            recordsize = "1M";
          };
        };
      };
    };
  };
}
