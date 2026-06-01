{
  pkgs,
  inputs,
  ...
}: {
  home.username = "aaron";
  home.homeDirectory = "/home/aaron";

  home.packages = with pkgs; [
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

  imports = [
    ./hyprland/default.nix
    ./ghostty.nix
    ./git.nix
    ./ssh.nix
    ./neovim/default.nix
    ./zen.nix
    ./hyprland/monitors/desktop.nix
  ];

  home.stateVersion = "26.05";
}
