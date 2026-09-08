_: {
  services.opensmtpd = {
    enable = true;
    serverConfiguration = ''
      listen on 10.44.0.1 port 2525

      action "outbound" relay
      match from src "10.44.0.3" for any action "outbound"
    '';
  };

  networking.firewall.interfaces.wg0.allowedTCPPorts = [2525];
}
