_: {
  boot.supportedFilesystems = ["btrfs"];

  services.btrfs = {
    autoScrub = {
      enable = true;
      interval = "monthly";
      fileSystems = ["/mnt/storage"];
    };
  };
  # I 100% did not just ripe the 2nd drive out making this no longer raid ;3
}
