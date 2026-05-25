{
  pkgs,
  config,
  ...
}: {
  imports = [
    ./ui.nix
    ./lsp.nix
    ./orgmode.nix
  ];

  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;

    defaultEditor = true;

    plugins = with pkgs.vimPlugins; [
      nvim-autopairs
      neo-tree-nvim
      telescope-nvim
      copilot-vim
    ];

    extraConfig = ''
       lua << EOF
              vim.g.mapleader = ' '
              -- vimtex settings for LaTeX support
              vim.g.vimtex_view_method = 'zathura'
              vim.g.vimtex_compiler_method = 'latexmk'
              vim.g.vimtex_quickfix_open_on_warning = 0

              vim.opt.number = true
              vim.opt.relativenumber = true
              vim.opt.colorcolumn = '100'
              vim.opt.tabstop = 2
              vim.opt.shiftwidth = 2
              vim.opt.expandtab = true

              require('nvim-autopairs').setup{}

              require('neo-tree').setup({
                close_if_last_window = true,
                popup_border_style = "rounded",
                enable_git_status = true,
                enable_diagnostics = true,
                default_component_configs = {
                  indent = {
                    indent_size = 2,
                    padding = 1,
                  },
                  icon = {
                    folder_closed = "",
                    folder_open = "",
                    folder_empty = "",
                    default = "",
                  },
                  git_status = {
                    symbols = {
                      added     = "✚",
                      modified  = "",
                      deleted   = "✖",
                      renamed   = "➜",
                      untracked = "★",
                      ignored   = "◌",
                      unstaged  = "✗",
                      staged    = "✓",
                      conflict  = "",
                    }
                  },
                },
                window = {
                  position = "left",
                  width = 30,
                  mappings = {
                    ["<space>"] = "none",
                  },
                },
                filesystem = {
                  follow_current_file = {
                    enabled = true,
                  },
                  use_libuv_file_watcher = true,
                  filtered_items = {
                    hide_dotfiles = false,
                    hide_gitignored = false,
                  },
                },
              })

              -- Neo-tree keybindings
              vim.keymap.set('n', '<leader>e', '<cmd>Neotree toggle<CR>', { desc = 'Toggle file explorer' })
              vim.keymap.set('n', '<leader>o', '<cmd>Neotree focus<CR>', { desc = 'Focus file explorer' })


              local telescope = require('telescope.builtin')
              vim.keymap.set('n', '<leader>ff', telescope.find_files)
              vim.keymap.set('n', '<leader>fg', telescope.live_grep)
              vim.keymap.set('n', '<leader>fb', telescope.buffers)
              vim.keymap.set('n', '<leader>fh', telescope.help_tags)
              vim.keymap.set('n', '<leader>fn', function()
                telescope.find_files({ cwd = '~/notes' })
              end)
              vim.keymap.set('n', '<leader>fs', function()
                telescope.live_grep({ cwd = '~/notes' })
              end)

              -- GitHub Copilot setup
              vim.g.copilot_no_tab_map = true
              vim.g.copilot_assume_mapped = true
              vim.g.copilot_tab_fallback = ""

              vim.keymap.set('i', '<C-j>', 'copilot#Accept("\\<CR>")', { expr = true, replace_keycodes = false, desc = 'Accept Copilot suggestion' })
              vim.keymap.set('i', '<C-l>', '<Plug>(copilot-accept-word)', { desc = 'Accept Copilot word' })
              vim.keymap.set('i', '<M-]>', '<Plug>(copilot-next)', { desc = 'Next Copilot suggestion' })
              vim.keymap.set('i', '<M-[>', '<Plug>(copilot-previous)', { desc = 'Previous Copilot suggestion' })
              vim.keymap.set('i', '<C-\\>', '<Plug>(copilot-dismiss)', { desc = 'Dismiss Copilot suggestion' })

              vim.api.nvim_set_keymap('n', '<Tab>', ':BufferLineCycleNext<CR>', { noremap = true, silent = true })
              vim.api.nvim_set_keymap('n', '<S-Tab>', ':BufferLineCyclePrev<CR>', { noremap = true, silent = true })
      EOF
    '';
  };

  home.packages = with pkgs; [
    ripgrep
    fd
    gcc
    # Optional tools for snacks.nvim image support
    imagemagick # for 'magick' and 'convert' commands
    ghostscript # for 'gs' command (PDF rendering)
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };
}
