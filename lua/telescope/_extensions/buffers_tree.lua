--- Telescope extension registration for buffers_tree.
-- This file registers the extension with Telescope.
-- @module telescope._extensions.buffers_tree

local has_telescope, telescope = pcall(require, "telescope")
if not has_telescope then
  error("telescope-buffers-tree requires telescope.nvim (https://github.com/nvim-telescope/telescope.nvim)")
end

return telescope.register_extension({
  setup = function(ext_config, config)
    require("telescope-buffers-tree.config").setup(ext_config)
  end,
  exports = {
    -- Main picker: :Telescope buffers_tree
    buffers_tree = require("telescope-buffers-tree").open,
  },
  health = require("telescope-buffers-tree.health").check,
})
