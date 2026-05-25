# Credit: This module is lifted from https://tangled.org/tangled.org/infra/blob/master/hosts/spindle/services/openbao/proxy.nix
{pkgs, ...}: {
  systemd.services.openbao-proxy = {
    description = "OpenBao Proxy with Auto-Auth";
    after = ["network.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      User = "root";
      ExecStart = "${pkgs.openbao}/bin/bao proxy -config=/etc/openbao/proxy.hcl";
      Restart = "always";
      RestartSec = "5";
      LimitNOFILE = "65536";
    };
  };

  environment.etc."openbao/proxy.hcl".text = ''
    vault {
      address = "http://localhost:8201"

      # Retry configuration
      retry {
        num_retries = 5
      }
    }

    # Auto-Auth using AppRole
    auto_auth {
      method "approle" {
        mount_path = "auth/approle"
        config = {
          role_id_file_path   = "/etc/openbao/role-id"
          secret_id_file_path = "/etc/openbao/secret-id"
          remove_secret_id_file_after_reading = false
        }
      }

      # Write authenticated token to file
      sink "file" {
        config = {
          path = "/var/lib/openbao/token"
          mode = 0640
        }
      }
    }

    # API Proxy listener for Spindle
    listener "tcp" {
      address     = "127.0.0.1:8200"
      tls_disable = true

      # Security headers
      require_request_header = false

      # Enable proxy API for management
      proxy_api {
        enable_quit = true
      }
    }

    # Enable API proxy with auto-auth token
    api_proxy {
      use_auto_auth_token = true
    }

    cache {
    }

    # Logging configuration
    log_level = "info"
    log_format = "standard"
    log_file = "/var/log/openbao/proxy.log"
    log_rotate_duration = "24h"
    log_rotate_max_files = 30

    # Process management
    pid_file = "/var/lib/openbao/proxy.pid"

    # Disable idle connections for reliability
    disable_idle_connections = ["auto-auth", "proxying"]
  '';

  # Create necessary directories and files
  systemd.tmpfiles.rules = [
    # Directories
    "d /var/lib/openbao 0755 root root -"
    "d /var/lib/openbao/cache 0755 root root -"
    "d /var/log/openbao 0755 root root -"
    "d /etc/openbao 0755 root root -"

    # Credential files (content must be populated externally)
    "f /etc/openbao/role-id 0600 root root -"
    "f /etc/openbao/secret-id 0600 root root -"

    # Configuration file
    "f /etc/openbao/proxy.hcl 0644 root root -"
  ];
}
