# Credit: This module is lifted from https://tangled.org/tangled.org/infra/blob/master/hosts/spindle/services/openbao/openbao.nix
{
  config,
  pkgs,
  lib,
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
