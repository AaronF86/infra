{ config, pkgs, ... }:

{
  services.nginx = {
    enable = true;
    virtualHosts = {
      "aaronf86.tech" = {
        root = pkgs.writeTextDir "index.html" "hello world\n";
      };

      "www.aaronf86.tech" = {
        root = pkgs.writeTextDir "index.html" "hello world\n";
      };

      "knot.aaronf86.tech" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:5555";

          extraConfig = ''
            proxy_set_header X-Forwarded-For $remote_addr;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-Proto $scheme;
          '';
        };
      };
    };
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "aaron@aaronf86.tech";
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
