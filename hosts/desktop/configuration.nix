{
  config,
  pkgs,
  lib,
  commonArgs,
  ...
}: {
  imports = [
    ../../common/base.nix
    ./hardware-configuration.nix
    ../../common/workstation.nix
    ../../modules/kmscon.nix
    ./disk-config.nix
  ];

  networking = {
    hostName = "Desktop";
  };

  users.users.aaron.shell = pkgs.fish;
  programs.fish.enable = true;

  environment.systemPackages = with pkgs; [
    neovim
    tmux
    syncthing
    acpi
  ];

  programs.steam.enable = true;
}
