{ config, pkgs, ... }: {
  services.haproxy = {
    enable = true;

    config = ''
      global
        log /dev/log local0
        maxconn 1024

      defaults
        log global
        mode tcp
        option tcplog
        timeout connect 5s
        timeout client  1m
        timeout server  1m

      frontend ssh_in
        bind *:22
        default_backend ssh_backend

      backend ssh_backend
        server knot 10.44.0.3:2222
    '';
  };

  networking.firewall.allowedTCPPorts = [ 22 ];
}