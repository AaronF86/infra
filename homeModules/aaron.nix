{pkgs, inputs, ...}: {
  home = {
    username = "aaron";
    homeDirectory = "/home/aaron";
    stateVersion = "26.05";
    packages = with pkgs; [
      thunar
      mattermost-desktop
      obs-studio
      gradle
      vesktop
      prismlauncher

      haskellPackages.ghc
      haskellPackages.cabal-install
      python3
      ormolu
      clang-tools
      nil
      nixpkgs-fmt
      rust-analyzer
      clippy
      sqlite
      jetbrains.idea
    ];
  };

  xdg.configFile."gtk-3.0/bookmarks" = {
    force = true;
    text = ''
      file:///home/aaron/Documents
      file:///home/aaron/Music
      file:///home/aaron/Pictures
      file:///home/aaron/Videos
      file:///home/aaron/Downloads
      file:///mnt/storage Share
    '';
  };

  imports = [
    ./tmux.nix
    ./fish.nix
    ./hyprland/default.nix
    ./ghostty.nix
    ./git.nix
    ./ssh.nix
    ./neovim/default.nix
    ./zen.nix
    ./hyprland/monitors/desktop.nix
  ];
}
