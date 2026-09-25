{
  config,
  pkgs,
  ...
}: let
  spindlePolicy = ''
    path "spindle/data/*" {
      capabilities = ["create", "read", "update", "delete"]
    }
    path "spindle/metadata/*" {
      capabilities = ["list", "read", "delete", "update"]
    }
    path "spindle/" {
      capabilities = ["list"]
    }
    path "auth/token/lookup-self" {
      capabilities = ["read"]
    }
  '';

  configureScript = pkgs.writeShellApplication {
    name = "openbao-configure";
    runtimeInputs = [pkgs.openbao pkgs.curl];
    text = ''
      ROOT_TOKEN=$(cat "${config.sops.secrets.openbao-root-token.path}")

      if [ -z "$ROOT_TOKEN" ] || [ "$ROOT_TOKEN" = "PLACEHOLDER" ]; then
        echo "openbao-root-token is not set, skipping configuration"
        exit 0
      fi

      # Wait for OpenBao to be unsealed
      for i in $(seq 1 30); do
        STATUS=$(curl -sf http://127.0.0.1:8201/v1/sys/health | grep -o '"sealed":[a-z]*' | cut -d: -f2 || true)
        if [ "$STATUS" = "false" ]; then
          break
        fi
        echo "Waiting for OpenBao to be unsealed... ($i/30)"
        sleep 2
      done

      if [ "$STATUS" != "false" ]; then
        echo "OpenBao is still sealed, skipping configuration"
        exit 0
      fi

      export BAO_ADDR=http://127.0.0.1:8201
      export BAO_TOKEN=$ROOT_TOKEN

      if ! bao secrets list | grep -q "^spindle/"; then
        echo "Enabling spindle KV mount..."
        bao secrets enable -path=spindle -version=2 kv
      fi

      echo "Writing spindle policy..."
      bao policy write spindle-policy /etc/openbao/spindle-policy.hcl

      if ! bao auth list | grep -q "^approle/"; then
        echo "Enabling AppRole auth..."
        bao auth enable approle
      fi

      bao write auth/approle/role/spindle \
        token_policies="spindle-policy" \
        token_ttl=1h \
        token_max_ttl=4h \
        bind_secret_id=true \
        secret_id_ttl=0 \
        secret_id_num_uses=0

      if [ ! -s /etc/openbao/role-id ]; then
        echo "Generating role-id..."
        bao read -field=role_id auth/approle/role/spindle/role-id > /etc/openbao/role-id
        chmod 600 /etc/openbao/role-id
      fi

      if [ ! -s /etc/openbao/secret-id ]; then
        echo "Generating secret-id..."
        bao write -f -field=secret_id auth/approle/role/spindle/secret-id > /etc/openbao/secret-id
        chmod 600 /etc/openbao/secret-id
      fi

      echo "OpenBao configuration complete"
    '';
  };
in {
  sops.secrets.openbao-root-token = {
    sopsFile = ../../../../secrets/openbao-root-token.txt.enc;
    format = "binary";
    mode = "0400";
  };

  environment.etc."openbao/spindle-policy.hcl".text = spindlePolicy;

  systemd.services.openbao-configure = {
    description = "Configure OpenBao KV and AppRole for Spindle";
    after = ["openbao.service" "openbao-unseal.service"];
    wants = ["openbao.service" "openbao-unseal.service"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${configureScript}/bin/openbao-configure";
    };
  };

  systemd.services.openbao-proxy = {
    after = ["openbao-configure.service"];
    wants = ["openbao-configure.service"];
  };
}
