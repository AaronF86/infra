_: {
  services.tangled.spindle = {
    enable = true;
    server = {
      owner = "did:plc:e2nksyu6bnw6lczckjhqweau";
      hostname = "spindle.aaronf86.tech";

      listenAddr = "0.0.0.0:6555";

      queueSize = 100;
      maxJobCount = 6;
      secrets = {
        provider = "openbao";
      };
    };
    pipelines = {
      workflowTimeout = "30m";
      nixery = {
        maxJobMemoryMb = 4096;
        maxConcurrentWorkflows = 6;
      };
      microvm.limits = {
        workflow.memoryMiB = 4096;
        total.memoryMiB = 6 * 4096;
      };
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
