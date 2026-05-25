{
  pkgs,
  config,
  ...
}: {
  programs.neovim = {
    plugins = with pkgs.vimPlugins; [
      doom-one-nvim # Preferred color scheme
      lualine-nvim # Status line
      bufferline-nvim # Buffer line
      nvim-web-devicons # File icons
      which-key-nvim # Keybinding hints
      noice-nvim # Enhanced UI / LSP popups
      snacks-nvim # Modular UI & notifications
    ];

    extraConfig = ''
      lua << EOF
        -- Colorscheme
        vim.cmd [[colorscheme doom-one]]

        -- Statusline
        require('lualine').setup {
          options = {
            theme = 'auto',
            icons_enabled = true,
          }
        }

        -- Bufferline
        require('bufferline').setup{}

        -- File icons
        require('nvim-web-devicons').setup()

        -- Keybinding hints
        require('which-key').setup()

        -- Snacks full UI setup
        require('snacks').setup({
          bigfile      = { enabled = true },
          dashboard    = { enabled = false },
          explorer     = { enabled = false },
          image        = { enabled = true },
          input        = { enabled = true },
          lazygit      = { enabled = true },
          notifier     = { enabled = false },
          picker       = { enabled = false },
          quickfile    = { enabled = true },
          scope        = { enabled = true },
          scroll       = { enabled = true },
          statuscolumn = { enabled = false },
          terminal     = { enabled = true },
          toggle       = { enabled = true },
          words        = { enabled = true },
        })

        -- Noice: enhanced command-line & LSP UI
        require('noice').setup({
          lsp = {
            override = {
              ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
              ["vim.lsp.util.stylize_markdown"] = true,
            },
          },
        })
      EOF
    '';
  };

  home.packages = with pkgs; [
    sqlite # Snacks.picker history/frecency
    imagemagick # Snacks.image backend
    imagemagick # for 'magick' and 'convert' commands
    ghostscript # for 'gs' command (PDF rendering)
    lazygit # Snacks.lazygit integration
  ];
}
