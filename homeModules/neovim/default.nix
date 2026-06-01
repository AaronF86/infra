{
  pkgs,
  config,
  ...
}: {
  imports = [
    ./lsp.nix
  ];

  programs.neovim = {
    enable = true;

    viAlias = true;
    vimAlias = true;
    defaultEditor = true;

    plugins = with pkgs.vimPlugins; [
      doom-one-nvim
    ];

    extraConfig = ''
      let mapleader = " "
      let maplocalleader = " "

      set number
      set relativenumber
      set tabstop=2
      set shiftwidth=2
      set expandtab

      colorscheme doom-one
    '';
  };

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  home.packages = with pkgs; [
    ripgrep
  ];
}
