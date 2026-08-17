{
  pkgs,
  inputs,
  ...
}: let
  rhine = pkgs.callPackage "${inputs.river-next}/window-managers/rhine/package.nix" {};
  channel = pkgs.callPackage "${inputs.river-next}/channel/package.nix" {};
in {
  services.displayManager.sessionPackages = [pkgs.river];

  environment.systemPackages = [
    rhine
    channel
    pkgs.brightnessctl
    pkgs.playerctl
  ];

  services.keyd = {
    enable = true;

    keyboards.default = {
      settings = {
        main = {
          capslock = "overload(control, esc)";
        };
      };
    };
  };
}
