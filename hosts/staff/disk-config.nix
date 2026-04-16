{
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/nvme0n1";
    destroy = false;
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          priority = 1;
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = ["fmask=0077" "dmask=0077"];
          };
        };

        root = {
          priority = 2;
          end = "-8.8G";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };

        swap = {
          priority = 3;
          size = "8.8G";
          content = {
            type = "swap";
          };
        };
      };
    };
  };
}
