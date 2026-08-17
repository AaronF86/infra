_: {
  services.kanshi = {
    enable = true;
    settings = [
      {
        profile.name = "desktop";
        profile.outputs = [
          {
            criteria = "HDMI-A-1";
            mode = "1920x1080@60";
            position = "0,0";
            scale = 1.0;
          }
          {
            criteria = "DP-1";
            mode = "3840x2560@119.99";
            position = "1920,0";
            scale = 2.0;
          }
        ];
      }
    ];
  };
}
