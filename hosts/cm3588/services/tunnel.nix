{ lib, ... }:

let
  gatewayPublicKey = "S9sac7M1N0Qml+/5WN8sxu5CeBsDDyO2mdZy2m7qXEs=";
  gatewayKeyIsValid =
    builtins.match "^[A-Za-z0-9+/]{43}=$" gatewayPublicKey != null;
in
{
  networking.wireguard.interfaces = lib.mkIf gatewayKeyIsValid {
    wg0 = {
      ips = [ "10.44.0.2/24" ];
      privateKeyFile = "/var/secrets/wireguard/cm3588-private";

      peers = [
        {
          publicKey = gatewayPublicKey;
          allowedIPs = [ "10.44.0.1/32" ];
          endpoint = "46.224.126.188:51820";
          persistentKeepalive = 25;
        }
      ];
    };
  };

  systemd.services.wireguard-wg0.unitConfig.ConditionPathExists =
    "/var/secrets/wireguard/cm3588-private";
}
