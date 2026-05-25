{config, ...}: {
  wayland.windowManager.hyprland.settings = {
    monitor = [
      "DP-1,preferred,0x0,1" # left  (Dell)
      "HDMI-A-1,preferred,1920x0,1" # center (AOC 2481W)
      "HDMI-A-2,preferred,3840x0,1" # right  (AOC 2381)
    ];

    workspace = [
      "6,monitor:DP-1,default:true,persistent:true"
      "1,monitor:HDMI-A-1,default:true,persistent:true"
      "2,monitor:HDMI-A-1,persistent:true"
      "3,monitor:HDMI-A-1,persistent:true"
      "4,monitor:HDMI-A-1,default:true,persistent:true"
      "5,monitor:HDMI-A-2,persistent:true"
    ];
  };
}
