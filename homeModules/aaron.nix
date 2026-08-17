{pkgs, ...}: {
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
    ./river/default.nix
    ./ghostty.nix
    ./git.nix
    ./ssh.nix
    ./neovim/default.nix
    ./zen.nix
    ./river/monitors/desktop.nix
  ];
}
