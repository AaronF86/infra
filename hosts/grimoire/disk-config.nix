{
  disko.devices = {
    disk = {
      disk1 = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-eui.00000000000000000026b7283b03da75";

        content = {
          type = "gpt";

          partitions = {
            primary = {
              size = "100%";

              content = {
                type = "btrfs";

                subvolumes = {
                  storage = {
                    mountpoint = "/mnt/storage";
                    mountOptions = ["noatime" "ssd" "compress=zstd" "discard=async" "space_cache=v2" "autodefrag" "nofail"];
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
