{
  config,
  pkgs,
  ...
}: {
  sops.age.keyFile = "/var/lib/sops-nix/keys.txt";

  sops.secrets.wireguard-staff-private = {
    sopsFile = ../../../secrets/wireguard/staff.enc;
    format = "dotenv";
    key = "PRIVATE_KEY";
    owner = "root";
    group = "root";
    mode = "0400";
  };

  networking.wireguard.interfaces = {
    wg0 = {
      ips = ["10.44.0.3/24"];
      privateKeyFile = "/run/wireguard-staff-private";
    };
  };

  systemd.services.wireguard-wg0 = {
    preStart = ''
      umask 077
      . ${config.sops.secrets.wireguard-staff-private.path}
      printf '%s\n' "$PRIVATE_KEY" > /run/wireguard-staff-private
    '';
    postStart = ''
      ${pkgs.wireguard-tools}/bin/wg set wg0 peer "UPMC/vvDY8/kbvHTWOth59ulj0KG3UTbLMbY3kJxUC0=" allowed-ips 10.44.0.1/32 endpoint 51.68.220.132:51820 persistent-keepalive 25
    '';
  };
}
