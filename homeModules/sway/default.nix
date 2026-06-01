{
  config,
  pkgs,
  ...
}: let
  terminal = "ghostty";
  menu = "wofi --show drun";

  left = "j";
  down = "k";
  up = "l";
  right = "semicolon";
in {
  imports = [
    ./binds.nix
    ../hyprland/wofi.nix
    ../hyprland/waybar.nix
  ];
  wayland.windowManager.sway = {
    enable = true;
    xwayland = true;

    config = {
      inherit terminal menu;

      bars = [];

      input = {
        "type:keyboard" = {
          xkb_layout = "us";
          xkb_options = "ctrl:nocaps";
        };
      };

      startup = [
        {
          command = "waybar";
          always = true;
        }
      ];
    };
  };
}
