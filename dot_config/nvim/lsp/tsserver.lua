-- JavaScript/TypeScript LSP configuration
return {
  cmd = { 'typescript-language-server', '--stdio' },
  root_markers = {
    'package.json',
    'tsconfig.json',
    'jsconfig.json',
    '.git'
  },
  filetypes = { 'javascript', 'javascriptreact', 'javascript.jsx', 'typescript', 'typescriptreact', 'typescript.tsx' },
  init_options = {
    hostInfo = 'neovim',
    preferences = {
      includeInlayParameterNameHints = 'all',
      includeInlayParameterNameHintsWhenArgumentMatchesName = true,
      includeInlayFunctionParameterTypeHints = true,
      includeInlayVariableTypeHints = true,
      includeInlayPropertyDeclarationTypeHints = true,
      includeInlayFunctionLikeReturnTypeHints = true,
      includeInlayEnumMemberValueHints = true
    }
  }
}
