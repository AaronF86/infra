{pkgs, ...}: {
  imports = [
    ./../modules/loginManagers/ly.nix
    ./../modules/DesktopEnvironments/river.nix
    ./../modules/bluetooth.nix
    ./smb-client.nix
  ];

  programs.direnv.enable = true;

  environment.systemPackages = [pkgs.soft-serve];
}
