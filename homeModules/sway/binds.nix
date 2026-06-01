{config, ...}: let
  modifier = "Mod4";
  left = "j";
  down = "k";
  up = "l";
  right = "semicolon";
in {
  wayland.windowManager.sway.config = {
    inherit modifier;
    keybindings = {
      "${modifier}+Return" = "exec ${config.wayland.windowManager.sway.config.terminal}";
      "${modifier}+d" = "exec ${config.wayland.windowManager.sway.config.menu}";

      "${modifier}+Shift+q" = "kill";

      "${modifier}+Shift+e" = "exec swaynag -t warning -m 'Exit sway?' -b 'Yes' 'swaymsg exit'";

      "${modifier}+Shift+s" = "exec flameshot gui";
      # Focus
      "${modifier}+${left}" = "focus left";
      "${modifier}+${down}" = "focus down";
      "${modifier}+${up}" = "focus up";
      "${modifier}+${right}" = "focus right";

      # Move
      "${modifier}+Shift+${left}" = "move left";
      "${modifier}+Shift+${down}" = "move down";
      "${modifier}+Shift+${up}" = "move up";
      "${modifier}+Shift+${right}" = "move right";

      "${modifier}+h" = "splith";
      "${modifier}+v" = "splitv";
      "${modifier}+f" = "fullscreen";

      "${modifier}+s" = "layout stacking";
      "${modifier}+w" = "layout tabbed";
      "${modifier}+e" = "layout toggle split";

      "${modifier}+space" = "focus mode_toggle";
      "${modifier}+Shift+space" = "floating toggle";

      "${modifier}+p" = "sticky toggle";

      "${modifier}+r" = "mode resize";

      # Workspaces
      "${modifier}+1" = "workspace number 1";
      "${modifier}+2" = "workspace number 2";
      "${modifier}+3" = "workspace number 3";
      "${modifier}+4" = "workspace number 4";
      "${modifier}+5" = "workspace number 5";
      "${modifier}+6" = "workspace number 6";
      "${modifier}+7" = "workspace number 7";
      "${modifier}+8" = "workspace number 8";
      "${modifier}+9" = "workspace number 9";
      "${modifier}+0" = "workspace number 10";

      "${modifier}+Shift+1" = "move container to workspace number 1";
      "${modifier}+Shift+2" = "move container to workspace number 2";
      "${modifier}+Shift+3" = "move container to workspace number 3";
      "${modifier}+Shift+4" = "move container to workspace number 4";
      "${modifier}+Shift+5" = "move container to workspace number 5";
      "${modifier}+Shift+6" = "move container to workspace number 6";
      "${modifier}+Shift+7" = "move container to workspace number 7";
      "${modifier}+Shift+8" = "move container to workspace number 8";
      "${modifier}+Shift+9" = "move container to workspace number 9";
      "${modifier}+Shift+0" = "move container to workspace number 10";
    };

    modes = {
      resize = {
        "${left}" = "resize shrink width 10 px";
        "${down}" = "resize grow height 10 px";
        "${up}" = "resize shrink height 10 px";
        "${right}" = "resize grow width 10 px";

        "Return" = "mode default";
        "Escape" = "mode default";
      };
    };
  };
}
