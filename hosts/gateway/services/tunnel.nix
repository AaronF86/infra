{ lib, ... }:

let
  cm3588PublicKey = "WyshnKvOloRAVjN5Z+JDoh4TCkRD/OIZZlKtSdlnn34=";
  cm3588KeyIsValid =
    builtins.match "^[A-Za-z0-9+/]{43}=$" cm3588PublicKey != null;
in
{
  networking.wireguard.interfaces = lib.mkIf cm3588KeyIsValid {
    wg0 = {
      ips = [ "10.44.0.1/24" ];
      listenPort = 51820;
      privateKeyFile = "/var/secrets/wireguard/gateway-private";

      peers = [
        {
          publicKey = cm3588PublicKey;
          allowedIPs = [ "10.44.0.2/32" ];
        }
      ];
    };
  };

  systemd.services.wireguard-wg0.unitConfig.ConditionPathExists =
    "/var/secrets/wireguard/gateway-private";
}
