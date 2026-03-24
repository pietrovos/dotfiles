-- Lua LSP configuration
return {
  cmd = { 'lua-language-server' },
  root_markers = {
    '.luarc.json',
    '.luacheckrc',
    '.stylua.toml',
    'stylua.toml',
    '.git'
  },
  filetypes = { 'lua' },
  settings = {
    Lua = {
      runtime = {
        -- Tell the language server which version of Lua you're using
        version = 'LuaJIT',
      },
      diagnostics = {
        -- Get the language server to recognize the `vim` global
        globals = {'vim'},
      },
      workspace = {
        -- Make the server aware of Neovim runtime files
        library = vim.api.nvim_get_runtime_file("", true),
        checkThirdParty = false
      },
      telemetry = {
        enable = false,
      },
      completion = {
        callSnippet = "Replace"
      },
      format = {
        enable = true,
        defaultConfig = {
          indent_style = "space",
          indent_size = "2",
        }
      }
    }
  }
}
