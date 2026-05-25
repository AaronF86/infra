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

  users.defaultUserShell = pkgs.fish;

  networking = {
    hostName = "Framework-13";
  };

  users.users.aaron.shell = pkgs.fish;
  programs.fish.enable = true;

  environment.systemPackages = with pkgs; [
    neovim
    tmux
    syncthing
    acpi
  ];
}
