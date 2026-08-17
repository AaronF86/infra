_: {
  services.tangled.spindle = {
    enable = true;
    server = {
      owner = "did:plc:e2nksyu6bnw6lczckjhqweau";
      hostname = "spindle.aaronf86.tech";

      listenAddr = "0.0.0.0:6555";

      queueSize = 100;
      maxJobCount = 2;
      secrets = {
        provider = "openbao";
      };
    };
    pipelines = {
      workflowTimeout = "15m";
    };
  };

  systemd.services.spindle = {
    after = ["openbao-proxy.service"];
    wants = ["openbao-proxy.service"];
    serviceConfig = {
      RestartSec = "10";
      # Wait for openbao-proxy to authenticate and write its token before starting
      ExecStartPre = "/bin/sh -c 'until [ -s /var/lib/openbao/token ]; do sleep 2; done'";
    };
  };

  networking.firewall.interfaces.wg0.allowedTCPPorts = [6555];
}
