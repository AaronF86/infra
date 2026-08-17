{
  pkgs,
  config,
  ...
}: {
  imports = [
    ./waybar.nix
    ../hyprland/dunst.nix
    ../hyprland/wofi.nix
  ];

  wayland.windowManager.river = {
    enable = true;
    package = pkgs.river;
    extraConfig = ''
      swaybg -i ${config.home.homeDirectory}/Pictures/wallpapers/wallpaper1.png -m fill &
      kanshi &
      channel &
      exec rhine
    '';
  };

  xdg.configFile."river/config.rh".text = ''
    layout {
        * bsp
    }

    layout_config {
        bsp {
            gaps 5
        }
    }

    window_management {
        follow_cursor true
        border {
            width 2
            colours {
                focus rgba8, 81, 175, 239, 255
                inactive rgba8, 40, 44, 52, 128
            }
        }
    }

    workspacerules [
        0, monitor, DP-1
        1, monitor, DP-1
        2, monitor, DP-1
        3, monitor, DP-1
        4, monitor, HDMI-A-1
    ]

    keybinds [
        super,       Return,  launch, ghostty
        super,       d,       launch, wofi -f --show=drun --lines=5 --prompt=
        super+shift, d,       launch, grimblast copy area
        super+shift, q,       close,  Focus
        super+shift, e,       exit
        super,       f,       fullscreen, toggle, Focus
        super,       v,       floating,   toggle, Focus

        super, j, moveFocus, Down
        super, k, moveFocus, Up
        super, h, moveFocus, Left
        super, l, moveFocus, Right

        super+shift, j, moveWindow, Down
        super+shift, k, moveWindow, Up
        super+shift, h, moveWindow, Left
        super+shift, l, moveWindow, Right

        super, 1, focusWorkspace, 0
        super, 2, focusWorkspace, 1
        super, 3, focusWorkspace, 2
        super, 4, focusWorkspace, 3
        super, 5, focusWorkspace, 4

        super+shift, 1, sendToWorkspace, 0
        super+shift, 2, sendToWorkspace, 1
        super+shift, 3, sendToWorkspace, 2
        super+shift, 4, sendToWorkspace, 3
        super+shift, 5, sendToWorkspace, 4

        none, XF86AudioRaiseVolume,  launch, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
        none, XF86AudioLowerVolume,  launch, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
        none, XF86AudioMute,         launch, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
        none, XF86AudioPlay,         launch, playerctl play-pause
        none, XF86AudioNext,         launch, playerctl next
        none, XF86AudioPrev,         launch, playerctl previous
        none, XF86MonBrightnessUp,   launch, brightnessctl set 5%+
        none, XF86MonBrightnessDown, launch, brightnessctl set 5%-
    ]

    startup [
        waybar
        dunst
    ]
  '';

  home.packages = with pkgs; [
    grimblast
    swaybg
  ];

  home.file."Pictures/wallpapers/.keep".text = "";

  xdg.terminal-exec = {
    enable = true;
    settings = {
      default = ["com.mitchellh.ghostty.desktop"];
    };
  };
}
