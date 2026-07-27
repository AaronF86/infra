{
  config,
  pkgs,
  ...
}: {
  programs.waybar = {
    enable = true;

    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 36;
        output = ["*"];

        modules-left = ["custom/logo" "hyprland/workspaces"];
        modules-right = [
          "pulseaudio"
          "bluetooth"
          "network"
          "custom/vpn"
          "custom/flameshot"
          "battery"
          "clock"
        ];

        "custom/logo" = {
          format = "";
          tooltip = false;
          on-click = "bemenu-run --accept-single -n -p 'Launch'";
        };
        "custom/flameshot" = {
          format = "󰹑";
          tooltip = false;
          on-click = "flameshot gui";
        };
        "hyprland/workspaces" = {
          disable-scroll = true;
          all-outputs = false;
          format = "{name}";
          format-icons = {
            "1" = "1";
            "2" = "2";
            "3" = "3";
            "4" = "4";
            "5" = "5";
            "6" = "6";
            "7" = "7";
            "default" = "";
          };
        };

        "pulseaudio" = {
          format = "{icon} {volume}%";
          format-muted = "󰝟 Muted";

          format-icons = {
            headphone = "󰋋";
            hands-free = "󰋎";
            headset = "󰋎";
            phone = "󰏲";
            portable = "󰏲";
            car = "󰄋";
            default = ["󰕿" "󰖀" "󰕾"];
          };

          on-click = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
          on-click-right = "pavucontrol";
        };

        "bluetooth" = {
          format = "󰂯 {status}";
          format-disabled = "";
          format-connected = "󰂱 {num_connections}";
          tooltip-format = "{controller_alias}\n{num_connections} connected";
          tooltip-format-connected = ''
            {controller_alias}
            {num_connections} connected

            {device_enumerate}
          '';
          tooltip-format-enumerate-connected = "{device_alias}";
          on-click = "blueman-manager";
        };

        "network" = {
          format-wifi = "󰖩  {essid} ({signalStrength}%)";
          format-ethernet = "󰈀  {ifname}";
          format-disconnected = "󰖪  Disconnected";

          tooltip-format = "{ifname}: {ipaddr}/{cidr}";
          tooltip-format-wifi = ''
            {essid} ({signalStrength}%)
            {ipaddr}/{cidr}
            {frequency} MHz
          '';

          on-click = "nm-connection-editor";
          interval = 5;
        };

        "custom/vpn" = {
          format = "{}";
          exec = "~/.config/waybar/scripts/vpn-status.sh";
          return-type = "json";
          interval = 5;
          on-click = "~/.config/waybar/scripts/vpn-toggle.sh";
          tooltip = true;
        };

        "battery" = {
          format = "{icon} {capacity}%";
          format-charging = "󰂄 {capacity}%";
          format-icons = ["" "" "" "" ""];
          interval = 30;
          tooltip = false;
        };

        "clock" = {
          format = "󰥔 {:%a %d %b  %H:%M}";
          interval = 60;
          tooltip = false;
        };
      };
    };

    style = ''
      * {
        all: unset;
        font-family: "JetBrainsMono Nerd Font Mono",
                     "NotoSans Nerd Font Mono",
                     monospace;
        font-size: 12px;
        color: #bbc2cf;
      }

      window#waybar {
        background: #282c34;
        border-bottom: 2px solid #51afef;
        padding: 0 8px;
      }

      #custom-logo {
        font-size: 24px;
        margin: 0 12px 0 8px;
        color: #51afef;
      }

      #workspaces {
        margin-left: 5px;
      }

      #workspaces button {
        padding: 4px 8px;
        margin: 0 4px;
        border-radius: 6px;
        min-width: 24px;

        color: #bbc2cf;
        background: transparent;

        transition:
          background-color 0.2s ease,
          color 0.2s ease;
      }

      #workspaces button.focused {
        background: #51afef;
        color: #282c34;
      }

      #workspaces button.urgent {
        background: #ff6c6b;
        color: #282c34;
      }

      #workspaces button:hover {
        background: #3e4451;
        color: #51afef;
      }

      #pulseaudio,
      #bluetooth,
      #network,
      #custom-vpn,
      #battery,
      #clock {
        padding: 0 8px;
      }

      #network {
        color: #98be65;
      }

      #network.disconnected {
        color: #ff6c6b;
      }

      #custom-vpn {
        color: #51afef;
      }

      #battery {
        margin-right: 6px;
      }

      #battery.charging {
        color: #98be65;
      }

      #battery.warning:not(.charging) {
        color: #ecbe7b;
      }

      #battery.critical:not(.charging) {
        color: #ff6c6b;
      }

      #clock {
        color: #c678dd;
      }
      #custom-flameshot {
        padding: 0 8px;
        color: #e5c07b;
      }
    '';
  };

  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [
    nerd-fonts.jetbrains-mono

    waybar
    bemenu
    pavucontrol
    blueman

    networkmanagerapplet
    networkmanager-openvpn
    networkmanager-openconnect
  ];
}
