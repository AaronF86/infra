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
    vim
  ];
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.permittedInsecurePackages = ["pnpm-10.29.2"];

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = true;

      warn-dirty = false;
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
    flake = "/home/aaron/dotfiles";
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
