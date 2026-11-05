{config, ...}: let
  domain = "aaronf86.tech";

  proxy = port: {
    useACMEHost = domain;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString port}";
      proxyWebsockets = true;
    };
  };
in {
  sops.secrets.cloudflare-token = {
    sopsFile = ../../../secrets/cloudflare-staff.json.enc;
    format = "json";
    key = "CF_DNS_API_TOKEN";
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "aaron@${domain}";

    certs.${domain} = {
      extraDomainNames = ["*.${domain}" "*.pds.${domain}"];
      dnsProvider = "cloudflare";
      dnsResolver = "1.1.1.1:53";
      credentialFiles."CF_DNS_API_TOKEN_FILE" = config.sops.secrets.cloudflare-token.path;
      group = "nginx";
    };
  };

  services.nginx = {
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    clientMaxBodySize = "512m";

    virtualHosts = {
      "knot.${domain}" = proxy 5555;
      "git.${domain}" = proxy 23232;
      "spindle.${domain}" = proxy 6555;
      "pds.${domain}" =
        proxy 3000
        // {
          serverAliases = ["*.pds.${domain}"];
        };
      "auth.${domain}" = proxy 9000;
      "grafana.${domain}" = proxy 3030;
      "panel.${domain}" = proxy 8000;

      "cloud.${domain}" = {
        useACMEHost = domain;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://192.168.1.115:80";
          proxyWebsockets = true;
          extraConfig = ''
            client_max_body_size 16G;
            proxy_request_buffering off;
            proxy_buffering off;
            proxy_read_timeout 3600s;
          '';
        };
      };
    };
  };

  networking.firewall.allowedTCPPorts = [80 443];
}
