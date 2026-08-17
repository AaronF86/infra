{pkgs, ...}: {
  home.packages = with pkgs; [
    nixd
    alejandra

    rust-analyzer
    gopls
    pyright
    jdt-language-server
    haskell-language-server
    tinymist
    sqls
    nodejs_22
  ];

  programs.neovim = {
    plugins = with pkgs.vimPlugins; [
      nvim-lspconfig

      blink-cmp
      friendly-snippets
      nvim-treesitter
      nvim-autopairs
      copilot-vim
    ];

    initLua = ''

      require("nvim-autopairs").setup({
         check_ts = true,
       })

      vim.lsp.handlers["textDocument/hover"] = function(err, result, ctx, config)
         config = config or {}
         config.border = "rounded"
         return vim.lsp.handlers.hover(err, result, ctx, config)
       end

       require("blink.cmp").setup({
         keymap = {
           preset = "default",
           ["<CR>"] = { "accept", "fallback" },
         },

         appearance = {
           nerd_font_variant = "mono",
         },

         completion = {
           documentation = {
             auto_show = true,
             auto_show_delay_ms = 200,
           },
         },

         sources = {
           default = { "lsp", "path", "snippets", "buffer" },
         },

         fuzzy = {
           implementation = "prefer_rust_with_warning",
         },
       })

       local capabilities = require("blink.cmp").get_lsp_capabilities()

       local function cfg(opts)
         opts.capabilities = capabilities
         return opts
       end

      vim.lsp.config("nixd", cfg({
         cmd = { "nixd" },
         filetypes = { "nix" },
         root_markers = { "flake.nix", ".git" },
       }))

       vim.lsp.config("rust_analyzer", cfg({
         cmd = { "rust-analyzer" },
         filetypes = { "rust" },
         root_markers = { "Cargo.toml", ".git" },
       }))

       vim.lsp.config("gopls", cfg({
         cmd = { "gopls" },
         filetypes = { "go" },
         root_markers = { "go.mod", ".git" },
       }))

       vim.lsp.config("pyright", cfg({
         cmd = { "pyright-langserver", "--stdio" },
         filetypes = { "python" },
         root_markers = { "pyproject.toml", "setup.py", ".git" },
       }))

       vim.lsp.config("jdtls", cfg({
         cmd = { "jdtls" },
         filetypes = { "java" },
         root_markers = { "pom.xml", "build.gradle", ".git" },
       }))

       vim.lsp.config("hls", cfg({
         cmd = { "haskell-language-server-wrapper", "--lsp" },
         filetypes = { "haskell", "lhaskell" },
         root_markers = { "stack.yaml", "cabal.project", ".git" },
       }))

       vim.lsp.config("tinymist", cfg({
         cmd = { "tinymist" },
         filetypes = { "typst" },
         root_markers = { ".git" },
       }))

       vim.lsp.config("sqls", cfg({
         cmd = { "sqls" },
         filetypes = { "sql" },
         root_markers = { ".git" },
       }))

       vim.lsp.enable({
         "nixd",
         "rust_analyzer",
         "gopls",
         "pyright",
         "jdtls",
         "hls",
         "tinymist",
         "sqls",
       })

      vim.api.nvim_create_autocmd("LspAttach", {
         callback = function(ev)
           local opts = { buffer = ev.buf, silent = true }

           vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
           vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
           vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
           vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)

           vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
           vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)

           vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
           vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
           vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, opts)

           vim.keymap.set("n", "<leader>f", function()
             vim.lsp.buf.format({ async = true })
           end, opts)
         end,
       })

       vim.api.nvim_create_autocmd("LspAttach", {
         callback = function(ev)
           local client = vim.lsp.get_client_by_id(ev.data.client_id)
           if not client then return end

           if client:supports_method("textDocument/formatting") then
             vim.api.nvim_create_autocmd("BufWritePre", {
               buffer = ev.buf,
               callback = function()
                 vim.lsp.buf.format({ bufnr = ev.buf })
               end,
             })
           end
         end,
       })

    '';
  };
}
