{pkgs, ...}: {
  systemd.services.minecraft-tcp-tunnel = {
    description = "Minecraft TCP Tunnel to staff";
    wantedBy = ["multi-user.target"];
    after = ["network-online.target" "wireguard-wg0.service"];
    wants = ["network-online.target" "wireguard-wg0.service"];

    serviceConfig = {
      Type = "simple";
      Restart = "always";
      RestartSec = "3s";
      ExecStart = "${pkgs.socat}/bin/socat TCP-LISTEN:25565,bind=0.0.0.0,reuseaddr,keepalive,fork TCP:10.44.0.3:25565";
    };
  };

  networking.firewall.allowedTCPPorts = [25565];
  networking.firewall.allowedUDPPorts = [24454];
}
