--- telescope-buffers-tree
-- A Telescope extension that displays open buffers in a hierarchical tree view.
-- @module telescope-buffers-tree

local M = {}

--- Open the buffer picker with tree view.
-- @param opts table|nil Configuration options (overrides global config)
-- @see telescope-buffers-tree.config for available options
function M.open(opts)
  return require("telescope-buffers-tree.picker").open(opts)
end

--- Setup the extension with custom configuration.
-- Note: This is typically called automatically via telescope.setup().
-- @param opts table|nil Configuration options
function M.setup(opts)
  require("telescope-buffers-tree.config").setup(opts)
end

return M
