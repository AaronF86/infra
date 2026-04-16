{
  pkgs,
  config,
  ...
}: {
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

  networking.firewall.interfaces.wg0.allowedTCPPorts = [6555];
}
