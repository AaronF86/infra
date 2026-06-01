{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./../modules/loginManagers/ly.nix
    ./../modules/DesktopEnvironments/hyprland.nix
    ./../modules/bluetooth.nix
    ./smb-client.nix
  ];

  programs.direnv.enable = true;
}
