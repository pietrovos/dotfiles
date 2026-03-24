return {
  cmd = { 'prisma-language-server', '--stdio' },
  root_markers = {
    '.git', 'package.json',
  },
  filetypes = { 'prisma' },
  settings = {
    prisma = {
      prismaFmtBinPath = '',
    }
  }
}
