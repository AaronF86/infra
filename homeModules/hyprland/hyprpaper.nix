{
  config,
  pkgs,
  ...
}: {
  services.hyprpaper = {
    enable = true;

    settings = {
      ipc = "on";
      splash = false;
      splash_offset = 2;

      wallpaper = [
        {
          monitor = "DP-2";
          path = "~/Pictures/wallpapers/wallpaper1.png";
          fit_mode = "cover";
        }
        {
          monitor = "HDMI-A-1";
          path = "~/Pictures/wallpapers/wallpaper1.png";
          fit_mode = "cover";
        }
        {
          monitor = "HDMI-A-2";
          path = "~/Pictures/wallpapers/wallpaper1.png";
          fit_mode = "cover";
        }
        {
          monitor = "eDP-1";
          path = "~/Pictures/wallpapers/wallpaper1.png";
          fit_mode = "cover";
        }
      ];
    };
  };

  home.file."Pictures/wallpapers/.keep".text = "";

  home.packages = with pkgs; [
    hyprpaper
  ];
}
