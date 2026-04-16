{pkgs, ...}: {
  systemd.services.knot-ssh-forward = {
    description = "Forward public SSH on gateway to staff knot host over WireGuard";
    wantedBy = ["multi-user.target"];
    after = ["network-online.target" "wireguard-wg0.service"];
    wants = ["network-online.target" "wireguard-wg0.service"];

    serviceConfig = {
      Type = "simple";
      Restart = "always";
      RestartSec = 3;
      ExecStart = "${pkgs.socat}/bin/socat TCP-LISTEN:22,reuseaddr,fork TCP:10.44.0.3:2222";
    };
  };

  networking.firewall.allowedTCPPorts = [22 2222];
}
