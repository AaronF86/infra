_: {
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

      frontend smtp_in
        bind *:25
        default_backend smtp_backend

      backend smtp_backend
        server stalwart 10.44.0.3:25 send-proxy-v2

      frontend submissions_in
        bind *:465
        default_backend submissions_backend

      backend submissions_backend
        server stalwart 10.44.0.3:465 send-proxy-v2

      frontend submission_in
        bind *:587
        default_backend submission_backend

      backend submission_backend
        server stalwart 10.44.0.3:587 send-proxy-v2

      frontend imaps_in
        bind *:993
        default_backend imaps_backend

      backend imaps_backend
        server stalwart 10.44.0.3:993 send-proxy-v2

      frontend imap_in
        bind *:143
        default_backend imap_backend

      backend imap_backend
        server stalwart 10.44.0.3:143 send-proxy-v2
    '';
  };

  networking.firewall.allowedTCPPorts = [22 25 465 587 993 143];
}
