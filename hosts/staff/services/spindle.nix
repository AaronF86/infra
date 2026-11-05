{config, ...}: {
  sops.secrets.spindle-key = {
    sopsFile = ../../../secrets/spindle-key.pem.enc;
    format = "binary";
    mode = "0400";
  };

  services.tangled.spindle = {
    enable = true;
    keyPath = config.sops.secrets.spindle-key.path;
    contact.email = "aaron@aaronf86.tech";
    server = {
      owner = "did:plc:e2nksyu6bnw6lczckjhqweau";
      hostname = "spindle.aaronf86.tech";

      listenAddr = "0.0.0.0:6555";

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
      ExecStartPre = "/bin/sh -c 'until [ -s /var/lib/openbao/token ]; do sleep 2; done'";
    };
  };

  networking.firewall.interfaces.wg0.allowedTCPPorts = [6555];
}
