{
  config,
  pkgs,
  ...
}: let
  minecraftDir = "/var/lib/minecraft-forge";
  backupDir = "/mnt/storage/staff/backups/minecraft-forge";
  stdinPipe = "/run/minecraft-server.stdin";
  simpleVoiceChatPort = 24454;
in {
  users.groups.minecraft = {};
  users.users.minecraft = {
    isSystemUser = true;
    group = "minecraft";
    home = minecraftDir;
    createHome = true;
  };

  systemd.sockets.minecraft-forge = {
    bindsTo = ["minecraft-forge.service"];
    socketConfig = {
      ListenFIFO = stdinPipe;
      SocketMode = "0660";
      SocketUser = "minecraft";
      SocketGroup = "minecraft";
      RemoveOnStop = true;
      FlushPending = true;
    };
  };

  systemd.services.minecraft-forge = {
    description = "Minecraft Forge Server";
    wantedBy = ["multi-user.target"];
    requires = ["minecraft-forge.socket"];
    wants = ["network-online.target"];
    after = ["network-online.target" "minecraft-forge.socket"];

    serviceConfig = {
      Type = "simple";
      User = "minecraft";
      Group = "minecraft";
      WorkingDirectory = minecraftDir;
      PermissionsStartOnly = true;
      Restart = "always";
      RestartSec = "10s";
      Nice = -5;
      LimitNOFILE = 1048576;
      StandardInput = "socket";
      StandardOutput = "journal";
      StandardError = "journal";
    };

    path = [pkgs.jdk17_headless pkgs.coreutils pkgs.gnugrep pkgs.gnused];

    script = ''
      cd ${minecraftDir}

      ensure_property() {
        key="$1"
        value="$2"
        file="$3"

        if ${pkgs.gnugrep}/bin/grep -q "^''${key}=" "$file"; then
          ${pkgs.gnused}/bin/sed -i "s|^''${key}=.*|''${key}=''${value}|" "$file"
        else
          printf '%s\n' "''${key}=''${value}" >> "$file"
        fi
      }

      if [ -f ./server.properties ]; then
        ensure_property "server-port" "25565" ./server.properties
      fi

      if [ ! -f ./run.sh ]; then
        if [ ! -f ./forge-installer.jar ]; then
          echo "Missing ${minecraftDir}/forge-installer.jar"
          echo "Upload your Forge installer jar to that path."
          exit 1
        fi

        ${pkgs.jdk17_headless}/bin/java -jar ./forge-installer.jar --installServer .
      fi

      chmod +x ./run.sh
      if [ ! -f ./eula.txt ]; then
        cat > ./eula.txt <<'EOF'
      eula=true
      EOF
      fi
      exec ${pkgs.bash}/bin/bash ./run.sh nogui
    '';
  };

  systemd.services.minecraft-forge-scheduled-restart = {
    description = "Scheduled restart for Minecraft Forge with warning";
    serviceConfig = {
      Type = "oneshot";
    };
    path = [pkgs.coreutils pkgs.systemd];
    script = ''
      if ! ${pkgs.systemd}/bin/systemctl is-active --quiet minecraft-forge.service; then
        exit 0
      fi

      if [ -p ${stdinPipe} ]; then
        send_console() {
          printf '%s\n' "$1" > ${stdinPipe}
        }

        send_console 'say [Server] Restarting in 5 minutes.'
        sleep 60
        send_console 'say [Server] Restarting in 4 minutes.'
        sleep 60
        send_console 'say [Server] Restarting in 3 minutes.'
        sleep 60
        send_console 'say [Server] Restarting in 2 minutes.'
        sleep 60
        send_console 'say [Server] Restarting in 1 minute.'
        sleep 30
        send_console 'say [Server] Restarting in 30 seconds.'
        sleep 15
        send_console 'say [Server] Restarting in 15 seconds.'
        sleep 5
        send_console 'say [Server] Restarting in 10 seconds.'

        for seconds in 9 8 7 6 5 4 3 2 1; do
          sleep 1
          send_console "say [Server] Restarting in ''${seconds}..."
        done

        send_console 'say [Server] Restarting now.'
        send_console 'save-all'
        sleep 2
        send_console 'stop'
      fi

      sleep 20
      if ${pkgs.systemd}/bin/systemctl is-active --quiet minecraft-forge.service; then
        ${pkgs.systemd}/bin/systemctl restart minecraft-forge.service
      fi
    '';
  };

  systemd.timers.minecraft-forge-scheduled-restart = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
      Unit = "minecraft-forge-scheduled-restart.service";
      RandomizedDelaySec = "10m";
    };
  };

  networking.firewall.allowedTCPPorts = [25565];
  networking.firewall.allowedUDPPorts = [simpleVoiceChatPort];
  networking.firewall.interfaces.wg0.allowedUDPPorts = [simpleVoiceChatPort];
}
