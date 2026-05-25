{
  config,
  pkgs,
  ...
}: {
  services.dunst = {
    enable = true;
    settings = {
      global = {
        monitor = 1;
        geometry = "300x5-30+20";
        transparency = 10;
        frame_color = "#eceff1";
        frame_width = 3;
        timeout = 10;
      };
      urgency_normal = {
        background = "#37474f";
        foreground = "#eceff1";
        timeout = 10;
      };
    };
  };
}
