{
  commonArgs,
  pkgs,
  ...
}: {
  services.openssh = {
    enable = true;
    ports = [2222];
    openFirewall = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;

      PubkeyAuthentication = true;

      PermitRootLogin = "no";

      X11Forwarding = false;
      AllowAgentForwarding = false;
      AllowTcpForwarding = "no";

      MaxAuthTries = 3;
      LoginGraceTime = "30s";
    };
  };

  users.users.aaron = {
    isNormalUser = true;
    extraGroups = ["wheel" "video"];

    openssh.authorizedKeys.keys = commonArgs.sshKeys;
  };

  security.sudo = {
    enable = true;

    wheelNeedsPassword = false;
  };

  time.timeZone = "Europe/London";

  environment.systemPackages = with pkgs; [
    git
    curl
    tree
    lsd
    neovim
    tmux
  ];
  nixpkgs.config.allowUnfree = true;

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = true;

      warn-dirty = false;

      extra-substituters = [
        "https://nix-community.cachix.org"
        "https://haskell-language-server.cachix.org"
        "https://cache.iog.io"
        "https://cache.zw3rk.com"
      ];
      extra-trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "haskell-language-server.cachix.org-1:juFfHrwkOxqIOZShtC4YC1uT1bBcq2RSvC7OMKx0Nz8="
        "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
        "loony-tools:pr9m4BkM/5/eSTZlkQyRt57Jz7OMBxNSUiMC4FkcNfk="
      ];
    };

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };

    optimise = {
      automatic = true;
      dates = ["weekly"];
    };
  };

  system.autoUpgrade = {
    enable = true;
    dates = "weekly";
    flake = "/home/aaron/infra";
    flags = [
      "--update-input"
      "nixpkgs"
      "--commit-lock-file"
    ];
    allowReboot = false;
  };
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      hinfo = true;
    };
  };

  programs.nix-ld.enable = true;
  system.stateVersion = "26.05";
}
