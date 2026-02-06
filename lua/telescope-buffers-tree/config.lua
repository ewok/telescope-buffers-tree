--- Configuration module for telescope-buffers-tree.
-- Handles default values and user configuration merging.
-- @module telescope-buffers-tree.config

local M = {}

--- Default configuration values.
-- @table defaults
M.defaults = {
  -- Theme for the picker ("dropdown", "ivy", "cursor", or custom function)
  theme = "dropdown",

  -- Options passed to the theme function
  theme_opts = {},

  -- Initial mode when picker opens ("normal" or "insert")
  initial_mode = "normal",

  -- Show file previewer (default: false for cleaner tree view)
  previewer = false,

  -- Automatically switch to flat list when entering insert mode
  switch_on_insert = true,

  -- Close picker after executing an action
  action_close = true,

  -- Diagnostics configuration
  -- Can be: false (disabled), true (enabled with defaults), or table with signs
  -- Example: { signs = { error = {"E", "DiagnosticError"}, warn = {"W", "DiagnosticWarn"} } }
  diagnostics = false,

  -- Custom key-action mappings for normal mode
  -- Example: { ["<C-v>"] = function(prompt_bufnr, entry) vim.cmd("vsplit") end }
  actions = {},

  -- Custom telescope mappings { n = { lhs = rhs }, i = { lhs = rhs } }
  mappings = {
    n = {},
    i = {},
  },

  -- Callback when selecting a directory node
  -- function(path) -> called with the directory path
  on_folder_select = nil,
}

--- Current configuration (merged defaults + user config).
-- @table values
M.values = vim.deepcopy(M.defaults)

--- Setup configuration by merging user options with defaults.
-- Called by the extension's setup function.
-- @param opts table|nil User configuration options
function M.setup(opts)
  opts = opts or {}
  M.values = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts)
end

--- Get a configuration value.
-- @param key string Configuration key
-- @return any Configuration value
function M.get(key)
  return M.values[key]
end

return M
