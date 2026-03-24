-- JSON LSP configuration
return {
  cmd = { 'vscode-json-language-server', '--stdio' },
  root_markers = { 
    'package.json', 
    '.git',
    'jsconfig.json',
    'tsconfig.json'
  },
  filetypes = { 'json', 'jsonc' },
  init_options = {
    provideFormatter = true
  },
  settings = {
    json = {
      -- Remove the schemastore dependency since it's causing errors
      schemas = {
        {
          fileMatch = {"package.json"},
          url = "https://json.schemastore.org/package.json"
        },
        {
          fileMatch = {"tsconfig*.json"},
          url = "https://json.schemastore.org/tsconfig.json"
        },
        {
          fileMatch = {".prettierrc", ".prettierrc.json"},
          url = "https://json.schemastore.org/prettierrc.json"
        },
        {
          fileMatch = {".eslintrc", ".eslintrc.json"},
          url = "https://json.schemastore.org/eslintrc.json"
        }
      },
      validate = { enable = true }
    }
  },
  -- If schemastore plugin is not installed, uncomment this section:
  -- settings = {
  --   json = {
  --     schemas = {
  --       {
  --         fileMatch = {"package.json"},
  --         url = "https://json.schemastore.org/package.json"
  --       },
  --       {
  --         fileMatch = {"tsconfig*.json"},
  --         url = "https://json.schemastore.org/tsconfig.json"
  --       },
  --       {
  --         fileMatch = {".prettierrc", ".prettierrc.json"},
  --         url = "https://json.schemastore.org/prettierrc.json"
  --       },
  --       {
  --         fileMatch = {".eslintrc", ".eslintrc.json"},
  --         url = "https://json.schemastore.org/eslintrc.json"
  --       }
  --     }
  --   }
  -- }
}
