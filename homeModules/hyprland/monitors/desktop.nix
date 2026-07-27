{config, ...}: {
  wayland.windowManager.hyprland.settings = {
    monitor = [
      "HDMI-A-1,1920x1080@60,0x0,1"               # left (Dell 1080p)
      "DP-1,3840x2560@119.99,1920x0,2,bitdepth,10" # right (BenQ 4K@120, 2x scale, 10-bit)
    ];

    workspace = [
      "6,monitor:HDMI-A-1,default:true,persistent:true"
      "1,monitor:DP-1,default:true,persistent:true"
      "2,monitor:DP-1,persistent:true"
      "3,monitor:DP-1,persistent:true"
      "4,monitor:DP-1,persistent:true"
      "5,monitor:DP-1,persistent:true"
    ];
  };
}
