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

      # Development Tools
      haskellPackages.ghc
      haskellPackages.cabal-install
      ormolu
      clang-tools
      nil # Nix LSP
      nixpkgs-fmt # Nix formatter
      rust-analyzer # Rust LSP
      clippy # Rust linter
      sqlite
      jetbrains.idea
    ];
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
