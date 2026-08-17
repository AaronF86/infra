{pkgs, ...}: {
  programs.waybar = {
    enable = true;

    settings = {
      mainBar = {
        layer = "top";
        position = "bottom";
        height = 36;
        output = ["*"];

        modules-left = ["custom/logo" "hyprland/workspaces"];
        modules-right = [
          "pulseaudio"
          "bluetooth"
          "network"
          "custom/vpn"
          "custom/grimblast"
          "battery"
          "clock"
        ];

        "custom/logo" = {
          format = "";
          tooltip = false;
          on-click = "bemenu-run --accept-single -n -p 'Launch'";
        };
        "custom/grimblast" = {
          format = "󰹑";
          tooltip = false;
          on-click = "grimblast copy area";
        };
        "hyprland/workspaces" = {
          format = "{id}";
          on-click = "activate";
          sort-by-number = true;
          all-outputs = false;
          persistent-workspaces = {
            "1" = ["DP-1"];
            "2" = ["DP-1"];
            "3" = ["DP-1"];
            "4" = ["DP-1"];
            "5" = ["HDMI-A-1"];
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
          format-icons = ["" "" "" "" ""];
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
        border-top: 2px solid #51afef;
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
      }

      #workspaces button.active {
        background: #51afef;
        color: #282c34;
      }

      #workspaces button.occupied {
        color: #98be65;
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
      #custom-grimblast {
        padding: 0 8px;
        color: #e5c07b;
      }
    '';
  };

  home.file = {
    ".config/waybar/scripts/vpn-status.sh" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        vpn=$(nmcli -t -f TYPE,STATE con show --active 2>/dev/null | grep -E "^(vpn|wireguard):" | head -1)
        if [ -n "$vpn" ]; then
          name=$(nmcli -t -f NAME,TYPE,STATE con show --active 2>/dev/null | grep -E ":(vpn|wireguard):activated" | cut -d: -f1 | head -1)
          echo "{\"text\":\"󰒄 VPN\",\"class\":\"connected\",\"tooltip\":\"Connected: $name\"}"
        else
          echo "{\"text\":\"󰒅 VPN\",\"class\":\"disconnected\",\"tooltip\":\"VPN disconnected\"}"
        fi
      '';
    };
    ".config/waybar/scripts/vpn-toggle.sh" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        vpn=$(nmcli -t -f NAME,TYPE,STATE con show --active 2>/dev/null | grep -E ":(vpn|wireguard):activated" | cut -d: -f1 | head -1)
        if [ -n "$vpn" ]; then
          nmcli con down "$vpn"
        else
          first=$(nmcli -t -f NAME,TYPE con show 2>/dev/null | grep -E ":(vpn|wireguard)$" | cut -d: -f1 | head -1)
          [ -n "$first" ] && nmcli con up "$first"
        fi
      '';
    };
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
