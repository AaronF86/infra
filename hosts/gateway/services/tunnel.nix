{
  config,
  lib,
  pkgs,
  ...
}: let
  adminPeers = {
    desktop = {
      ip = "10.44.0.4";
      key = "3rC5sE2Z1DrPVcMPowvLROFQfxn9FA3eO4WEcP267xw=";
    };
    framework13 = {
      ip = "10.44.0.5";
      key = "48LImAkzf2OA5ijzZQdwG3uBBB/AdnGu87kRladfywI=";
    };
  };
in {
  sops.age.keyFile = "/var/lib/sops-nix/keys.txt";

  sops.secrets.wireguard-gateway-private = {
    sopsFile = ../../../secrets/wireguard/Gateway.enc;
    format = "dotenv";
    key = "PRIVATE_KEY";
    owner = "root";
    group = "root";
    mode = "0400";
  };

  networking.wireguard.interfaces = {
    wg0 = {
      ips = ["10.44.0.1/24"];
      listenPort = 51820;
      privateKeyFile = "/run/wireguard-gateway-private";
    };
  };

  systemd.services.wireguard-wg0 = {
    preStart = ''
      umask 077
      . ${config.sops.secrets.wireguard-gateway-private.path}
      printf '%s\n' "$PRIVATE_KEY" > /run/wireguard-gateway-private
    '';
    postStart = ''
      ${pkgs.wireguard-tools}/bin/wg set wg0 peer "1QqvXc1TwlYs6wwmnCAIMePRNxiW62x3Tdl2jFsqk10=" allowed-ips 10.44.0.2/32

      ${pkgs.wireguard-tools}/bin/wg set wg0 peer "xu5+uvhx/a66F6+77nE9EE25PYyO5uY/GDTEqp+/4ko=" allowed-ips 10.44.0.3/32

      ${lib.concatMapStrings (p: ''
          ${pkgs.wireguard-tools}/bin/wg set wg0 peer "${p.key}" allowed-ips ${p.ip}/32
        '')
        (lib.attrValues adminPeers)}
    '';
  };

  services.openssh.openFirewall = lib.mkIf (adminPeers != {}) (lib.mkForce false);
  networking.firewall.interfaces.wg0.allowedTCPPorts = [2222 9100];
}
