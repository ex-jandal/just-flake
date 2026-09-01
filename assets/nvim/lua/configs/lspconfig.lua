require("nvchad.configs.lspconfig").defaults()

require("mason").setup({
  registries = {
    "github:mason-org/mason-registry",
    "github:Crashdummyy/mason-registry",
  },
})

local servers = { "marksman", "html", "cssls", "ts_ls", "vue-language-server", "tailwindcss-language-server", "svelte",
  "pyright", "texlab", "taplo", "yamlls", "clangd", "intelephense", "laravel-ls", "gopls", "dcm", "bashls", "shellcheck", "fish-lsp",
  "asm-lsp", "tailwindcss", "dockerls", "docker_compose_language_service", "zls", "nim_langserver", "roslyn", "kulala-fmt",
  "vala_ls", "mesonlsp", "qmlls", "ols", "just", "kotlin_language_server", "jdtls", "c3_lsp", "slint_lsp",
}
vim.lsp.enable(servers)

-- read :h vim.lsp.config for changing options of lsp servers

------------------------------------------------------------------------------------
-- all of this is to make vue language server work with typescript language server
------------------------------------------------------------------------------------
local vue_language_server_path = vim.fn.expand("~/.local/share/pnpm/global/5/node_modules/@vue/language-server")
local tsserver_filetypes = { 'typescript', 'javascript', 'javascriptreact', 'typescriptreact', 'vue' }
local vue_plugin = {
  name = '@vue/typescript-plugin',
  location = vue_language_server_path,
  languages = { 'vue' },
  configNamespace = 'typescript',
}
local vtsls_config = {
  settings = {
    vtsls = {
      tsserver = {
        globalPlugins = {
          vue_plugin,
        },
      },
    },
  },
  filetypes = tsserver_filetypes,
}

local ts_ls_config = {
  init_options = {
    vue = { hybridMode = false },
    javascriptreact = { hybridMode = false },
    typescriptreact = { hybridMode = false },

    plugins = {
      vue_plugin,
    },
  },
  filetypes = tsserver_filetypes,
}

-- If you are on most recent `nvim-lspconfig`
-- local vue_ls_config = {}
-- If you are not on most recent `nvim-lspconfig` or you want to override
local vue_ls_config = {
  on_init = function(client)
    client.handlers['tsserver/request'] = function(_, result, context)
      local ts_clients = vim.lsp.get_clients({ bufnr = context.bufnr, name = 'ts_ls' })
      local vtsls_clients = vim.lsp.get_clients({ bufnr = context.bufnr, name = 'vtsls' })
      local clients = {}

      vim.list_extend(clients, ts_clients)
      vim.list_extend(clients, vtsls_clients)

      if #clients == 0 then
        vim.notify('Could not find `vtsls` or `ts_ls` lsp client, `vue_ls` would not work without it.',
          vim.log.levels.ERROR)
        return
      end
      local ts_client = clients[1]

      local param = unpack(result)
      local id, command, payload = unpack(param)
      ts_client:exec_cmd({
        title = 'vue_request_forward', -- You can give title anything as it's used to represent a command in the UI, `:h Client:exec_cmd`
        command = 'typescript.tsserverRequest',
        arguments = {
          command,
          payload,
        },
      }, { bufnr = context.bufnr }, function(_, r)
        local response = r and r.body
        -- TODO: handle error or response nil here, e.g. logging
        -- NOTE: Do NOT return if there's an error or no response, just return nil back to the vue_ls to prevent memory leak
        local response_data = { { id, response } }

        ---@diagnostic disable-next-line: param-type-mismatch
        client:notify('tsserver/response', response_data)
      end)
    end
  end,
}
-- nvim 0.11 or above
vim.lsp.config('vtsls', vtsls_config)
vim.lsp.config('vue_ls', vue_ls_config)
vim.lsp.config('ts_ls', ts_ls_config)
vim.lsp.enable({ 'ts_ls', 'vue_ls' }) -- If using `ts_ls` replace `vtsls` to `ts_ls`

------------------------------------------------------------------------------------
-- the end of vue language server with typescript language server config
------------------------------------------------------------------------------------

vim.lsp.config['laravel-ls'] = {
  cmd = { "laravel-ls" },
  filetypes = { "php", "blade" },
  root_markers = { "artisan" },
}
vim.lsp.enable('laravel-ls')

vim.lsp.config['fish_lsp'] = {
  cmd = { "fish-lsp", "start" },
  filetypes = { "fish" },
}
vim.lsp.enable('fish_lsp')


-- vim.lsp.handlers['textDocument/publishDiagnostics'] = vim.lsp.with(
--   vim.lsp.diagnostic.on_publish_diagnostics,
--   {
--     underline = true,
--     virtual_text = {
--       spacing = 5,
--       severity_limit = 'Warning',
--     },
--     update_in_insert = true,
--   }
-- )

-- vim.lsp.config['clangd'] = {
--   init_options = {
--
--   }
-- }
-- vim.lsp.enable('clangd')
--
vim.lsp.config['asm_lsp'] = {
  cmd = { "asm-lsp" },
  filetypes = { "asm", "s", "S", "vmasm", "nasm" },
  -- settings = {
  --   asm = {
  --     syntax = "nasm",
  --     architecture = "x86_64", -- important: switch from 16-bit to 64-bit
  --   },
  -- },
}
vim.lsp.enable('asm_lsp')

vim.lsp.config["qmlls"] = {
    cmd = { "qmlls6" }, -- Change "qmlls6" to "qmlls" or the correct executable name if necessary
    filetypes = { "qml" },
    -- Optional: additional settings for project management, see Qt documentation for details
}
vim.lsp.enable('qmlls')

vim.lsp.config['pyright'] = {
  settings = {
    python = {
      -- pythonPath = "/home/abu_jandal/.local/share/uv/tools/manim/bin/python",
      -- analysis = {
      --   typeCheckingMode = "off",  -- options: off, basic, strict
      --   autoSearchPaths = true,
      --   useLibraryCodeForTypes = true,
      --   diagnosticMode = "workspace",  -- options: openFilesOnly, workspace
      -- },
    },
  },
}

vim.lsp.config('nixd', {
  cmd = { 'nixd' },
  filetypes = { 'nix' },
  root_markers = { 'flake.nix', '.git', 'default.nix' },
})

vim.lsp.enable('nixd')


-- vim.lsp.config("ccls", {
--   init_options = {
--     compilationDatabaseDirectory = "build";
--     index = {
--       threads = 0;
--     };
--     clang = {
--       excludeArgs = { "-frounding-math"} ;
--     };
--   }
-- })
--
-- vim.lsp.enable('ccls')
