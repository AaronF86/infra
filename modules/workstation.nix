{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./loginManagers/ly.nix
    ./DesktopEnvironments/hyprland.nix
    ./bluetooth.nix
  ];

  # configuration.nix or a nixos module

  programs.steam = {
    enable = true;
    dedicatedServer.openFirewall = true;
  };
  services.flatpak.enable = true;
}
