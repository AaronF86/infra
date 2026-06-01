{
  disko.devices = {
    disk.main = {
      type = "disk";
      device = "/dev/nvme0n1";
      content = {
        type = "gpt";
        partitions = {
          boot = {
            size = "2G";
            type = "EF00"; # EFI
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };

          root = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4"; # or btrfs if you prefer
              mountpoint = "/";
            };
          };
        };
      };
    };
  };
}
