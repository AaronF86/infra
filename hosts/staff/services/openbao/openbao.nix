# Credit: This module is lifted from https://tangled.org/tangled.org/infra/blob/master/hosts/spindle/services/openbao/openbao.nix
{
  config,
  lib,
  pkgs,
  ...
}: {
  # Create openbao user and group
  users.groups.openbao = {};

  users.users.openbao = {
    isSystemUser = true;
    group = "openbao";
    home = "/var/lib/openbao";
    createHome = true;
    description = "OpenBao service user";
  };

  systemd.services.openbao = {
    serviceConfig = {
      DynamicUser = lib.mkForce false;
      User = "openbao";
      Group = "openbao";
    };
  };

  sops.secrets.openbao-unseal-key = {
    sopsFile = ../../../../secrets/openbao-unseal-key.txt.enc;
    format = "binary";
    mode = "0400";
  };

  systemd.services.openbao-unseal = {
    description = "Unseal OpenBao after startup";
    after = ["openbao.service"];
    wants = ["openbao.service"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "openbao-unseal" ''
        KEY=$(cat "${config.sops.secrets.openbao-unseal-key.path}")
        if [ -z "$KEY" ] || [ "$KEY" = "PLACEHOLDER" ]; then
          echo "openbao-unseal-key is not set, skipping auto-unseal"
          exit 0
        fi
        ${pkgs.openbao}/bin/bao operator unseal "$KEY" || true
      '';
    };
  };

  services.openbao = {
    enable = true;
    settings = {
      ui = true;

      listener.default = {
        type = "tcp";
        address = "127.0.0.1:8201";
        tls_disable = true;
      };

      cluster_addr = "http://127.0.0.1:8202";
      api_addr = "http://127.0.0.1:8201";

      storage.raft.path = "/var/lib/openbao";
    };
  };
}
