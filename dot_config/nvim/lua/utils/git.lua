-- Git utilities with caching for instant performance
local M = {}

-- Cache for git roots to avoid repeated calculations
local git_root_cache = {}
local cache_timeout = 30000 -- 30 seconds in milliseconds

-- Get cached git root or calculate and cache it
function M.get_git_root()
  -- Try multiple methods to find the project root
  local path = vim.api.nvim_buf_get_name(0)
  path = path ~= "" and vim.loop.fs_realpath(path) or vim.loop.cwd()

  -- Handle special buffers like oil
  if vim.bo.filetype == "oil" then
    local oil_ok, oil = pcall(require, "oil")
    if oil_ok then
      local oil_dir = oil.get_current_dir()
      if oil_dir then
        path = oil_dir
      end
    end
  end

  -- Ensure path is a directory
  local stat = vim.loop.fs_stat(path)
  if stat and stat.type ~= "directory" then
    path = vim.fn.fnamemodify(path, ":h")
  end

  -- Check cache first
  local cache_key = path
  local now = vim.loop.now()
  local cached = git_root_cache[cache_key]
  
  if cached and (now - cached.timestamp) < cache_timeout then
    return cached.root
  end

  -- Find git root from this path
  local git_root = nil
  
  -- Use vim.system for better performance (non-blocking when available)
  if vim.system then
    local result = vim.system(
      { "git", "-C", path, "rev-parse", "--show-toplevel" },
      { timeout = 1000 } -- 1 second timeout
    ):wait()
    
    if result.code == 0 and result.stdout then
      git_root = vim.trim(result.stdout)
      if git_root ~= "" and vim.fn.isdirectory(git_root) == 1 then
        -- Cache the result
        git_root_cache[cache_key] = {
          root = git_root,
          timestamp = now
        }
        return git_root
      end
    end
  else
    -- Fallback to io.popen for older Neovim versions
    local cmd = "git -C " .. vim.fn.shellescape(path) .. " rev-parse --show-toplevel"
    local handle = io.popen(cmd)
    if handle then
      git_root = handle:read("*a"):gsub("\n$", "")
      handle:close()
      if git_root ~= "" and vim.fn.isdirectory(git_root) == 1 then
        -- Cache the result
        git_root_cache[cache_key] = {
          root = git_root,
          timestamp = now
        }
        return git_root
      end
    end
  end

  -- Fallback 1: Try using LSP root detection
  local active_clients = vim.lsp.get_clients()
  for _, client in ipairs(active_clients) do
    if client.config.root_dir then
      -- Cache the LSP root as well
      git_root_cache[cache_key] = {
        root = client.config.root_dir,
        timestamp = now
      }
      return client.config.root_dir
    end
  end

  -- Fallback 2: Use current directory
  git_root_cache[cache_key] = {
    root = path,
    timestamp = now
  }
  return path
end

-- Clear cache (useful for testing or manual refresh)
function M.clear_cache()
  git_root_cache = {}
end

return M