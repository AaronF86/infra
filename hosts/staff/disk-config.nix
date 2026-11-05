{lib, ...}: let
  # the two 2 TB drives; the old 4 TB moved to grimoire
  drives = {
    disk1 = "/dev/disk/by-id/nvme-KINGSTON_SNV3S2000G_50026B7384626A8D";
    disk2 = "/dev/disk/by-id/nvme-KINGSTON_SNV3S2000G_50026B7384626A67";
  };
in {
  disko.devices = {
    disk =
      lib.mapAttrs (name: device: {
        type = "disk";
        inherit device;

        content = {
          type = "gpt";

          partitions = {
            # bootctl won't install onto an md ESP, so each disk gets its own;
            # configuration.nix copies /boot to /boot-fallback on every rebuild
            ESP = {
              priority = 1;
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint =
                  if name == "disk1"
                  then "/boot"
                  else "/boot-fallback";
                mountOptions = ["fmask=0077" "dmask=0077" "nofail"];
              };
            };

            root = {
              priority = 2;
              size = "100%";
              content = {
                type = "mdraid";
                name = "root";
              };
            };
          };
        };
      })
      drives;

    mdadm = {
      root = {
        type = "mdadm";
        level = 1;
        content = {
          type = "filesystem";
          format = "ext4";
          mountpoint = "/";
        };
      };
    };
  };
}
