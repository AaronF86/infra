{
  config,
  pkgs,
  lib,
  ...
}: {
  sops.secrets.github-runner-token = {
    sopsFile = ../../../secrets/github-runner.txt.enc;
    format = "binary";
    owner = "root";
    group = "root";
    mode = "0400";
  };

  services.github-runners = {
    runner-1 = {
      enable = true;
      url = "https://github.com/RiftEngines";
      tokenFile = config.sops.secrets.github-runner-token.path;
      extraLabels = ["rift"];
      extraPackages = with pkgs; [
        coreutils
        findutils
        diffutils
        gnugrep
        gnused
        gawk
        procps
        util-linux
        which
        sudo
        curl
        iproute2
        git
        gnutar
        gzip
        bzip2
        xz
        unzip
        zip
        jq
        nodejs_22
        docker
      ];
    };
  };

  programs.nix-ld.enable = true;
}
