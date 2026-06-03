{ pkgs, ... }:

{
  home.packages = with pkgs; [
    lazygit  
  ];

  programs.neovim = {
    enable = true;

    plugins = with pkgs.vimPlugins; [
      oil-nvim
      noice-nvim
      nui-nvim
      nvim-notify

      telescope-nvim
      plenary-nvim
      telescope-fzf-native-nvim
      gitsigns-nvim
      toggleterm-nvim
      lazygit-nvim
    ];

    extraLuaConfig = ''
require("toggleterm").setup({
  direction = "float",
  float_opts = {
    border = "rounded",
  },
})

vim.keymap.set("n", "<leader>gg", "<cmd>LazyGit<cr>", { desc = "LazyGit" })

require("noice").setup({
  lsp = {
    override = {
      ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
      ["vim.lsp.util.stylize_markdown"] = true,
      ["cmp.entry.get_documentation"] = false,
    },
  },

  messages = {
    enabled = true,
    view = "notify",
  },

  popupmenu = {
    enabled = true,
    backend = "nui",
  },

  notify = {
    enabled = true,
  },

  presets = {
    bottom_search = true,
    command_palette = true,
    long_message_to_split = true,
    lsp_doc_border = true,
  },
})

require("gitsigns").setup({
  signs = {
    add = { text = "+" },
    change = { text = "~" },
    delete = { text = "_" },
    topdelete = { text = "‾" },
    changedelete = { text = "~" },
  },

  current_line_blame = true,
  current_line_blame_opts = {
    delay = 300,
  },

  signcolumn = true,
})

local gs = require("gitsigns")

vim.keymap.set("n", "]c", gs.next_hunk, { desc = "Next git hunk" })
vim.keymap.set("n", "[c", gs.prev_hunk, { desc = "Prev git hunk" })

vim.keymap.set("n", "<leader>hs", gs.stage_hunk, { desc = "Stage hunk" })
vim.keymap.set("n", "<leader>hr", gs.reset_hunk, { desc = "Reset hunk" })

vim.keymap.set("n", "<leader>hS", gs.stage_buffer, { desc = "Stage buffer" })
vim.keymap.set("n", "<leader>hR", gs.reset_buffer, { desc = "Reset buffer" })

vim.keymap.set("n", "<leader>hp", gs.preview_hunk, { desc = "Preview hunk" })
vim.keymap.set("n", "<leader>hb", gs.blame_line, { desc = "Blame line" })

vim.keymap.set("n", "<leader>hd", gs.diffthis, { desc = "Diff this file" })

require("oil").setup({
  default_file_explorer = true,
  view_options = {
    show_hidden = true,
  },
})

vim.keymap.set("n", "-", "<cmd>Oil<cr>", {
  desc = "Open parent directory",
})

local telescope = require("telescope")

telescope.setup({
  defaults = {
    layout_strategy = "horizontal",
    sorting_strategy = "ascending",
    winblend = 0,
  },
})

telescope.load_extension("fzf")

local builtin = require("telescope.builtin")

vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Live grep" })
vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Buffers" })
vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Help" })

vim.keymap.set("n", "<leader>fr", builtin.lsp_references, { desc = "LSP references" })
vim.keymap.set("n", "<leader>fd", builtin.diagnostics, { desc = "Diagnostics" })
vim.keymap.set("n", "<leader>fs", builtin.lsp_document_symbols, { desc = "Symbols" })
vim.keymap.set("n", "<leader>fw", builtin.lsp_workspace_symbols, { desc = "Workspace symbols" })

vim.keymap.set("n", "<leader>tt", "<cmd>ToggleTerm<cr>", { desc = "Toggle terminal" })
'';
  };
}

