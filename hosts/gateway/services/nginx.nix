{ ... }:

{
  services.nginx = {
    enable = true;
    virtualHosts = {
      "aaronf86.tech" = {
        forceSSL = true;
        useACMEHost = "aaronf86.tech";
        locations."= /.well-known/atproto-did" = {
          extraConfig = ''
            default_type text/plain;
            return 200 "did:plc:thxvma4upsbx6vry4llosyse\n";
          '';
        };
        locations."/" = {
          proxyPass = "http://10.44.0.2:80";
          extraConfig = ''
            proxy_set_header X-Forwarded-For $remote_addr;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-Proto $scheme;
          '';
        };
      };

      "www.aaronf86.tech" = {
        forceSSL = true;
        useACMEHost = "aaronf86.tech";
        locations."/" = {
          proxyPass = "http://10.44.0.2:80";
          extraConfig = ''
            proxy_set_header X-Forwarded-For $remote_addr;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-Proto $scheme;
          '';
        };
      };

      "knot.aaronf86.tech" = {
        forceSSL = true;
        useACMEHost = "aaronf86.tech";
        locations."/" = {
          proxyPass = "http://10.44.0.2:5555";
          extraConfig = ''
            proxy_set_header X-Forwarded-For $remote_addr;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-Proto $scheme;
          '';
        };
        locations."/events" = {
          proxyPass = "http://10.44.0.2:5555";
          extraConfig = ''
            proxy_set_header X-Forwarded-For $remote_addr;
            proxy_set_header Host $host;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
          '';
        };
      };

      "pds.aaronf86.tech" = {
        forceSSL = true;
        useACMEHost = "aaronf86.tech";
        locations."/" = {
          proxyPass = "http://10.44.0.2:3000";
          extraConfig = ''
            proxy_set_header X-Forwarded-For $remote_addr;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-Proto $scheme;
          '';
        };
      };

      "~^(?<subdomain>.+)\\.pds\\.aaronf86\\.tech$" = {
        forceSSL = true;
        useACMEHost = "aaronf86.tech";
        locations."/" = {
          proxyPass = "http://10.44.0.2:3000";
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
    certs."aaronf86.tech" = {
      extraDomainNames = [ "aaron.pds.aaronf86.tech" "pds.aaronf86.tech" "knot.aaronf86.tech" "www.aaronf86.tech" ];
      group = "nginx";
      reloadServices = [ "nginx.service" ];
      webroot = "/var/lib/acme/acme-challenge";
    };
  };
}
