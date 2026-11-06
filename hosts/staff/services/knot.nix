{
  config,
  lib,
  pkgs,
  tangled-pkgs,
  ...
}: {
  sops.secrets.knot-env = {
    sopsFile = ../../../secrets/knot.env.enc;
    format = "dotenv";
  };

  services.tangled.knot-rs = {
    enable = true;

    package = tangled-pkgs.knot-rs.overrideAttrs (old: {
      nativeBuildInputs = (old.nativeBuildInputs or []) ++ [pkgs.patchelf];
      postFixup =
        (old.postFixup or "")
        + ''
          patchelf --add-rpath ${lib.getLib pkgs.zstd}/lib $out/bin/knot-server
        '';
    });

    stateDir = "/var/lib/knot-rs";
    environmentFile = config.sops.secrets.knot-env.path;

    openFirewall = false;

    settings = {
      server = {
        hostname = "knot.aaronf86.tech";
        admins = ["did:plc:e2nksyu6bnw6lczckjhqweau"];

        listen_addr = "0.0.0.0:5555";
        ssh_listen_addr = "[::]:22";
      };

      git.object_format = "sha1";

      atproto.plc_directory = "https://plc.directory";
      contact.email = "aaron@aaronf86.tech";

      xrpc = {
        trusted_proxy_header = "x-forwarded-for";
        trusted_proxies = ["10.44.0.1" "127.0.0.1"];
      };
    };
  };

  systemd.services.knot-rs.serviceConfig = {
    BindReadOnlyPaths = [
      "${pkgs.writeText "knot-resolv.conf" ''
        nameserver 1.1.1.1
        nameserver 9.9.9.9
        options edns0
      ''}:/etc/resolv.conf"
    ];
    InaccessiblePaths = ["-/run/nscd"];
  };

  networking.firewall = {
    allowedTCPPorts = [22];

    interfaces.wg0.allowedTCPPorts = [5555 22];
  };
}
