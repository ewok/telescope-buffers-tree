--- Entry display module for telescope-buffers-tree.
-- Handles icons, diagnostics, and telescope entry creation.
-- @module telescope-buffers-tree.entry

local entry_display = require("telescope.pickers.entry_display")
local tree_module = require("telescope-buffers-tree.tree")

local M = {}

-- Optional icon support (lazy loaded)
local icons_ok, mini_icons = pcall(require, "mini.icons")

--- Check if mini.icons is available.
-- @return boolean True if mini.icons is loaded
function M.has_icons()
  return icons_ok
end

-------------------------------------------------------------------------------
-- Icon utilities
-------------------------------------------------------------------------------

--- Get icon and highlight for a file or directory.
-- Returns empty string and nil highlight if mini.icons unavailable.
-- @param kind string "file" or "dir"
-- @param name string File or directory name
-- @return string icon
-- @return string|nil highlight group
function M.get_icon(kind, name)
  if not icons_ok then
    return "", nil
  end
  if kind == "dir" then
    return mini_icons.get("directory", name)
  end
  return mini_icons.get("file", name)
end

-------------------------------------------------------------------------------
-- Diagnostics
-------------------------------------------------------------------------------

-- Default diagnostic signs
local default_diagnostic_signs = {
  error = { "E", "DiagnosticError" },
  warn = { "W", "DiagnosticWarn" },
  info = { "I", "DiagnosticInfo" },
  hint = { "H", "DiagnosticHint" },
}

--- Get diagnostic icon for a buffer (highest severity).
-- @param bufnr number Buffer number
-- @param signs table Custom signs table { error = {"icon", "hl"}, ... }
-- @return string|nil icon
-- @return string|nil highlight group
function M.get_diagnostic_icon(bufnr, signs)
  if not bufnr then
    return nil, nil
  end
  local diagnostics = vim.diagnostic.get(bufnr)
  if #diagnostics == 0 then
    return nil, nil
  end

  -- Find highest severity (1=Error, 2=Warn, 3=Info, 4=Hint)
  local min_severity = 5
  for _, d in ipairs(diagnostics) do
    if d.severity < min_severity then
      min_severity = d.severity
    end
  end

  local severity_map = {
    [1] = "error",
    [2] = "warn",
    [3] = "info",
    [4] = "hint",
  }
  local key = severity_map[min_severity]
  local entry = signs[key] or default_diagnostic_signs[key]
  return entry and entry[1], entry and entry[2]
end

-------------------------------------------------------------------------------
-- Entry maker
-------------------------------------------------------------------------------

--- Create a displayer for telescope entries.
-- @return function Displayer function
function M.create_displayer()
  -- Columns: tree connector, [file icon], text, [diagnostic icon]
  return entry_display.create({
    separator = "",
    items = icons_ok and { {}, { width = 2 }, {}, { remaining = true } } or { {}, {}, { remaining = true } },
  })
end

--- Create entry maker function for telescope finder.
-- @param style string "tree" or "flat"
-- @param displayer function Displayer function from create_displayer()
-- @return function Entry maker function
function M.make_entry_maker(style, displayer)
  return function(e)
    return {
      value = e,
      kind = e.kind,
      ordinal = e.ordinal or tree_module.make_ordinal(e.path, e.name, e.bufnr),
      tree = e.tree,
      text = e.text,
      path = e.path,
      bufnr = e.bufnr,
      icon = e.icon,
      icon_hl = e.icon_hl,
      diag_icon = e.diag_icon,
      diag_hl = e.diag_hl,
      display = function(entry)
        if style == "flat" then
          return entry.path or entry.text or ""
        end
        local text_hl = entry.kind == "dir" and "Directory" or nil
        local diag_part = entry.diag_icon and (" " .. entry.diag_icon) or ""
        if icons_ok then
          return displayer({
            { entry.tree or "", "TelescopeResultsComment" },
            { (entry.icon or "") .. " ", entry.icon_hl },
            { entry.text or "", text_hl },
            { diag_part, entry.diag_hl },
          })
        else
          return displayer({
            { entry.tree or "", "TelescopeResultsComment" },
            { entry.text or "", text_hl },
            { diag_part, entry.diag_hl },
          })
        end
      end,
    }
  end
end

return M
