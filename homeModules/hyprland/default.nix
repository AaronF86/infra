{
  pkgs,
  lib,
  config,
  meta,
  ...
}: {
  imports = [
    ./binds.nix
    ./hyprpaper.nix
    ./waybar.nix
    ./dunst.nix
    ./wofi.nix
  ];

  wayland.windowManager.hyprland = {
    configType = "hyprlang";
    enable = true;

    settings = {
      input = {
        kb_layout = "us";
        follow_mouse = 1;
        touchpad = {
          natural_scroll = false;
        };
        sensitivity = 0;
      };

      general = {
        gaps_in = 5;
        gaps_out = 20;
        border_size = 2;
        "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
        "col.inactive_border" = "rgba(595959aa)";
        layout = "dwindle";
        allow_tearing = false;
      };

      decoration = {
        rounding = 10;

        blur = {
          enabled = true;
          size = 3;
          passes = 1;
        };
      };

      animations = {
        enabled = false;
      };

      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        force_default_wallpaper = 0;
      };

      exec-once = [
        "hyprpaper"
        "waybar"
        "dunst"
      ];
    };
  };

  home.packages = with pkgs; [
    way-displays
    grimblast
    
  ];
  services.flameshot.enable  = true;
}
