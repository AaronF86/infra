{
  pkgs,
  config,
  ...
}: {
  programs.neovim = {
    plugins = with pkgs.vimPlugins; [
      nvim-treesitter.withAllGrammars
      nvim-lspconfig
      blink-cmp
      friendly-snippets
      emmet-vim
    ];

    extraConfig = ''
      lua << EOF
      -- Treesitter setup with error handling
      vim.schedule(function()
        local ok, ts_config = pcall(require, "nvim-treesitter.configs")
        if ok then
          ts_config.setup({
            highlight = { enable = true },
            indent = { enable = true }
          })
          vim.o.foldmethod = "expr"
        else
          vim.notify("nvim-treesitter not available yet", vim.log.levels.WARN)
        end
      end)

      -- LSP servers (using new Neovim 0.11 API)
      vim.schedule(function()
        local servers = {
          "clangd",
          "rust_analyzer",
          "hls",
          "pyright",
          "ruff",
          "lua_ls",
          "html",
          "cssls",
          "astro",
          "ts_ls",
        }

        for _, server in ipairs(servers) do
          local ok = pcall(function()
            vim.lsp.config(server, {})
            vim.lsp.enable(server)
          end)
        end
      end)

      -- Completion (Blink CMP)
      vim.schedule(function()
        local ok, cmp = pcall(require, "blink.cmp")
        if ok then
          cmp.setup({
            signature = { enabled = true },
            completion = {
              documentation = { auto_show = true },
              menu = {
                auto_show = true,
                draw = {
                  columns = {
                    { "kind_icon" },
                    { "label" },
                    { "label_description" },
                    { "kind" },
                  },
                },
              },
            },
            keymap = {
              preset = "default",
              ["<CR>"] = { "accept", "fallback" },
              ["<Tab>"] = { "select_next", "fallback" },
              ["<S-Tab>"] = { "select_prev", "fallback" },
              ["<C-Space>"] = { "show", "show_documentation", "fallback" },
              ["<C-e>"] = { "hide", "fallback" },
              ["<C-b>"] = { "scroll_documentation_up", "fallback" },
              ["<C-f>"] = { "scroll_documentation_down", "fallback" },
              ["<C-k>"] = { "show_signature", "hide_signature", "fallback" },
            },
          })
        end
      end)
      EOF
    '';
  };

  home.packages = with pkgs; [
    clang-tools
    clippy
    rust-analyzer
    pyright
    ruff
    haskell-language-server
    lua-language-server
    astro-language-server
    typescript-language-server
    vscode-langservers-extracted
  ];
}
