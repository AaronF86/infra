{pkgs, ...}: {
  imports = [
    ../../common/base.nix
    ./hardware-configuration.nix
    ../../common/workstation.nix
    ../../modules/kmscon.nix
    ./disk-config.nix
    (import ../../common/wg-admin.nix {ip = "10.44.0.5";})
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
