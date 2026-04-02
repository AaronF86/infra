{ config, pkgs, ... }:

{
  services.tangled.knot = {
    enable = true;
    stateDir = "/mnt/storage/git";
    server = {
      listenAddr = "0.0.0.0:5555";
      owner = "did:plc:thxvma4upsbx6vry4llosyse";
        hostname = "knot.aaronf86.tech";
    };
  };

  networking.firewall.interfaces.wg0.allowedTCPPorts = [ 5555 ];
}
