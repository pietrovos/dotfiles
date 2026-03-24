-- Performance test for git root caching
-- Run this with :luafile lua/utils/git_test.lua

local git_utils = require("utils.git")

print("Testing git root performance...")

-- First call (should hit the filesystem)
local start_time = vim.loop.hrtime()
local root1 = git_utils.get_git_root()
local first_call_time = (vim.loop.hrtime() - start_time) / 1000000 -- Convert to milliseconds

-- Second call (should use cache)
start_time = vim.loop.hrtime()
local root2 = git_utils.get_git_root()
local second_call_time = (vim.loop.hrtime() - start_time) / 1000000

-- Third call (should use cache)
start_time = vim.loop.hrtime()
local root3 = git_utils.get_git_root()
local third_call_time = (vim.loop.hrtime() - start_time) / 1000000

print(string.format("First call (filesystem): %.2f ms", first_call_time))
print(string.format("Second call (cached): %.2f ms", second_call_time))
print(string.format("Third call (cached): %.2f ms", third_call_time))
print(string.format("Cache speedup: %.1fx faster", first_call_time / second_call_time))

print(string.format("Git root: %s", root1))
print(string.format("Results consistent: %s", (root1 == root2 and root2 == root3) and "✓" or "✗"))

-- Clear cache and test again
git_utils.clear_cache()
print("\nCache cleared, testing again...")

start_time = vim.loop.hrtime()
local root4 = git_utils.get_git_root()
local fourth_call_time = (vim.loop.hrtime() - start_time) / 1000000

print(string.format("After cache clear: %.2f ms", fourth_call_time))
print(string.format("Root after clear: %s", root4))