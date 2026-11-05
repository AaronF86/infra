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

  # Port 22 is Knot's public git-over-SSH (gateway haproxy → here): git only.
  # Admin logins stay on 2222, which is reachable from the LAN and WireGuard but never published.
  services.openssh = {
    ports = [22];
    extraConfig = ''
      Match LocalPort 22
        AllowUsers git
    '';
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
