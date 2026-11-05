_: let
  port = 8091;
  path = "/.well-known/apple-developer-merchantid-domain-association";
in {
  services.nginx.virtualHosts.apple-pay-verify = {
    listen = [{addr = "0.0.0.0"; inherit port;}];
    locations."= ${path}" = {
      alias = "${./apple-pay/apple-developer-merchantid-domain-association}";
      extraConfig = "default_type text/plain;";
    };
    locations."/".return = "404";
  };

  networking.firewall.interfaces.wg0.allowedTCPPorts = [port];
}
