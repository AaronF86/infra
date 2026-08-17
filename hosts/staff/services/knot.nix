_: {
  services.tangled.knot = {
    enable = true;
    stateDir = "/var/lib/knot/git";
    repo = {
      scanPath = "/var/lib/knot/git";
      mainBranch = "main";
    };

    server = {
      listenAddr = "0.0.0.0:5555";
      internalListenAddr = "127.0.0.1:5444";

      owner = "did:plc:e2nksyu6bnw6lczckjhqweau";

      dbPath = "/var/lib/knot/knot.db";

      hostname = "knot.aaronf86.tech";

      logDids = true;
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/knot 0750 git git -"
    "z /var/lib/knot/git 0750 git git -"
  ];

  networking.firewall = {
    allowedTCPPorts = [22];

    interfaces.wg0.allowedTCPPorts = [5555 22];
  };
}
