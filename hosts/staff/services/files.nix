{pkgs, ...}: let
  dir = "/mnt/storage/staff/files";
in {
  systemd.services.pdf-server = {
    wantedBy = ["multi-user.target"];

    serviceConfig = {
      WorkingDirectory = dir;
      Restart = "always";
    };

    script = ''
      ${pkgs.nix}/bin/nix shell nixpkgs#python3 --command \
        python3 -m http.server 8088 --bind 0.0.0.0
    '';
  };

  networking.firewall.interfaces.wg0.allowedTCPPorts = [8088];
}
