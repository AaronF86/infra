_: {
  services.dunst = {
    enable = true;
    settings = {
      global = {
        monitor = 1;
        width = 300;
        height = 200;
        offset = "30x20";
        origin = "top-right";
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
