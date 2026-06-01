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
  ];

  programs.neovim = {
    plugins = with pkgs.vimPlugins; [
      nvim-lspconfig
    ];

    extraLuaConfig = ''
            vim.lsp.handlers["textDocument/hover"] = function(err, result, ctx, config)
              config = config or {}
              config.border = "rounded"
              return vim.lsp.handlers.hover(err, result, ctx, config)
            end

            vim.lsp.config("nixd", {
              cmd = { "nixd" },
              filetypes = { "nix" },
              root_markers = { "flake.nix", ".git" },

              settings = {
                nixd = {
                  nixpkgs = {
                    expr = "import <nixpkgs> { }",
                  },

                  formatting = {
                    command = { "alejandra" },
                  },

                  options = {
                    nixos = {
                      expr = '(builtins.getFlake (toString ./.)).nixosConfigurations.<name>.options',
                    },
                    ["home-manager"] = {
                      expr = '(builtins.getFlake (toString ./.)).homeConfigurations."<user>@<host>".options',
                    },
                  },

                  diagnostic = {
                    suppress = {
                      "sema-extra-with",
                    },
                  },
                },
              },
            })

                  vim.lsp.config("rust_analyzer", {
                    cmd = { "rust-analyzer" },
                    filetypes = { "rust" },
                    root_markers = { "Cargo.toml", ".git" },
                  })

                  vim.lsp.config("gopls", {
                    cmd = { "gopls" },
                    filetypes = { "go" },
                    root_markers = { "go.mod", ".git" },
                  })

                  vim.lsp.config("pyright", {
                    cmd = { "pyright-langserver", "--stdio" },
                    filetypes = { "python" },
                    root_markers = { "pyproject.toml", "setup.py", ".git" },
                  })

                  vim.lsp.config("jdtls", {
                    cmd = { "jdtls" },
                    filetypes = { "java" },
                    root_markers = { "pom.xml", "build.gradle", ".git" },
                  })

                  vim.lsp.config("hls", {
                    cmd = { "haskell-language-server-wrapper", "--lsp" },
                    filetypes = { "haskell", "lhaskell" },
                    root_markers = { "stack.yaml", "cabal.project", ".git" },
                  })

                  vim.lsp.config("tinymist", {
                    cmd = { "tinymist" },
                    filetypes = { "typst" },
                    root_markers = { ".git" },
                  })

                  vim.lsp.config("sqls", {
                    cmd = { "sqls" },
                    filetypes = { "sql" },
                    root_markers = { ".git" },
                  })

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
            vim.api.nvim_clear_autocmds({
              event = "BufWritePre",
              buffer = ev.buf,
            })

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
