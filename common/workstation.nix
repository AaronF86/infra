{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./../modules/loginManagers/ly.nix
    ./../modules/DesktopEnvironments/sway.nix
    ./../modules/bluetooth.nix
    ./smb-client.nix
  ];
}
