--- Health check module for telescope-buffers-tree.
-- Integrates with :checkhealth telescope
-- @module telescope-buffers-tree.health

local M = {}

--- Run health checks for the extension.
-- Called by :checkhealth telescope
function M.check()
  vim.health.start("telescope-buffers-tree")

  -- Check Neovim version
  if vim.fn.has("nvim-0.9.0") == 1 then
    vim.health.ok("Neovim >= 0.9.0")
  else
    vim.health.error("Neovim >= 0.9.0 is required")
  end

  -- Check telescope.nvim
  local telescope_ok, _ = pcall(require, "telescope")
  if telescope_ok then
    vim.health.ok("telescope.nvim is installed")
  else
    vim.health.error("telescope.nvim is required but not found")
  end

  -- Check mini.icons (optional)
  local icons_ok, _ = pcall(require, "mini.icons")
  if icons_ok then
    vim.health.ok("mini.icons is installed (file icons enabled)")
  else
    vim.health.info("mini.icons not found (file icons disabled, optional)")
  end

  -- Check nvim-web-devicons as alternative (optional)
  if not icons_ok then
    local devicons_ok, _ = pcall(require, "nvim-web-devicons")
    if devicons_ok then
      vim.health.info("nvim-web-devicons found but not used (mini.icons preferred)")
    end
  end

  -- Check if extension is loaded
  local ext_loaded = pcall(function()
    return require("telescope").extensions.buffers_tree
  end)
  if ext_loaded then
    vim.health.ok("Extension loaded successfully")
  else
    vim.health.warn("Extension not loaded. Call: require('telescope').load_extension('buffers_tree')")
  end
end

return M
