# Prometheus + Grafana for staff, grimoire and gateway (exporters: common/metrics.nix).
# Grafana is LAN-only at grafana.aaronf86.tech (lan-proxy.nix); log in as admin with
# `sudo cat /run/secrets/grafana-admin-password` on staff.
{
  config,
  pkgs,
  ...
}: let
  grimoire = "192.168.1.115";
  # Over wg0; gateway only exposes its exporter on the tunnel
  gateway = "10.44.0.1";

  exporters = config.services.prometheus.exporters;
  target = instance: addr: port: {
    targets = ["${addr}:${toString port}"];
    labels = {inherit instance;};
  };

  dashboards = pkgs.linkFarm "grafana-dashboards" [
    {
      # "Node Exporter Full": CPU, memory, disk, network and hwmon temps per instance
      name = "node-exporter-full.json";
      path = pkgs.fetchurl {
        url = "https://grafana.com/api/dashboards/1860/revisions/45/download";
        hash = "sha256-GExrdAnzBtp1Ul13cvcZRbEM6iOtFrXXjEaY6g6lGYY=";
      };
    }
    {
      # grimoire's pool: free space and usage per ZFS dataset. Kept separate because
      # UI edits to the provisioned Node Exporter Full are lost on reload
      name = "storage.json";
      path = ./dashboards/storage.json;
    }
  ];

  grafanaSecret = key: {
    sopsFile = ../../../secrets/grafana.json.enc;
    format = "json";
    inherit key;
    owner = "grafana";
  };
in {
  imports = [(import ../../../common/metrics.nix {})];

  sops.secrets = {
    grafana-admin-password = grafanaSecret "admin_password";
    grafana-secret-key = grafanaSecret "secret_key";
  };

  services.prometheus = {
    enable = true;
    listenAddress = "127.0.0.1";
    port = 9090;
    retentionTime = "180d";
    globalConfig.scrape_interval = "30s";

    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [
          (target "staff" "127.0.0.1" exporters.node.port)
          (target "grimoire" grimoire exporters.node.port)
          (target "gateway" gateway exporters.node.port)
        ];
      }
      {
        job_name = "smartctl";
        static_configs = [
          (target "staff" "127.0.0.1" exporters.smartctl.port)
          (target "grimoire" grimoire exporters.smartctl.port)
        ];
      }
    ];
  };

  services.grafana = {
    enable = true;

    settings = {
      server = {
        http_addr = "127.0.0.1";
        http_port = 3030;
        domain = "grafana.aaronf86.tech";
        root_url = "https://grafana.aaronf86.tech/";
      };
      security = {
        admin_password = "$__file{${config.sops.secrets.grafana-admin-password.path}}";
        secret_key = "$__file{${config.sops.secrets.grafana-secret-key.path}}";
      };
      analytics.reporting_enabled = false;
    };

    provision = {
      enable = true;
      datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          uid = "prometheus";
          url = "http://127.0.0.1:${toString config.services.prometheus.port}";
          isDefault = true;
        }
      ];
      dashboards.settings.providers = [
        {
          name = "infra";
          options.path = dashboards;
        }
      ];
    };
  };
}
