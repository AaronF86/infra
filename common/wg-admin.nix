{ip}: _: {
  networking.wireguard.interfaces.wg0 = {
    ips = ["${ip}/24"];
    generatePrivateKeyFile = true;
    privateKeyFile = "/var/lib/wireguard/wg0.key";

    peers = [
      {
        publicKey = "UPMC/vvDY8/kbvHTWOth59ulj0KG3UTbLMbY3kJxUC0=";
        endpoint = "51.68.220.132:51820";
        allowedIPs = ["10.44.0.0/24"];
        persistentKeepalive = 25;
      }
    ];
  };
}
