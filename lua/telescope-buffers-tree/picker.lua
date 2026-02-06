--- Picker module for telescope-buffers-tree.
-- Handles the main picker logic, view switching, and buffer actions.
-- @module telescope-buffers-tree.picker

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local themes = require("telescope.themes")

local config = require("telescope-buffers-tree.config")
local tree_module = require("telescope-buffers-tree.tree")
local entry_module = require("telescope-buffers-tree.entry")

local M = {}

--- Parse diagnostics configuration.
-- @param diag_config boolean|table Diagnostics config from user
-- @return table Normalized diagnostics config { enable = bool, signs = table }
local function parse_diagnostics_config(diag_config)
  if diag_config == true then
    return { enable = true, signs = {} }
  elseif type(diag_config) == "table" then
    return { enable = true, signs = diag_config.signs or {} }
  else
    return { enable = false, signs = {} }
  end
end

--- Get theme function from theme name or function.
-- @param theme_name string|function Theme identifier
-- @return function Theme function
local function get_theme_function(theme_name)
  if type(theme_name) == "function" then
    return theme_name
  elseif type(theme_name) == "string" then
    return themes["get_" .. theme_name] or themes.get_dropdown
  end
  return themes.get_dropdown
end

--- Open the buffer picker with tree view.
-- @param opts table|nil Configuration options (overrides global config)
function M.open(opts)
  opts = opts or {}

  -- Merge with global config
  local cfg = vim.tbl_deep_extend("force", vim.deepcopy(config.values), opts)

  local user_mappings = cfg.mappings or {}
  local action_close = cfg.action_close
  local switch_on_insert = cfg.switch_on_insert
  local on_folder_select = cfg.on_folder_select
  local diag_opts = parse_diagnostics_config(cfg.diagnostics)

  -- Setup theme
  local theme_get = get_theme_function(cfg.theme)
  local theme_opts = cfg.theme_opts or {}

  -- Build picker options with theme
  local picker_opts = theme_get(vim.tbl_deep_extend("force", {
    previewer = cfg.previewer,
    initial_mode = cfg.initial_mode,
  }, theme_opts))

  -- Collect and process buffers
  local items = tree_module.collect_buffers()
  local tree_entries = tree_module.make_tree_entries(items, entry_module, diag_opts)
  local flat_entries = tree_module.make_flat_entries(items)

  -- Find current buffer's index for default selection
  local current_bufnr = vim.api.nvim_get_current_buf()
  local default_idx
  for i, e in ipairs(tree_entries) do
    if e.kind == "file" and e.bufnr == current_bufnr then
      default_idx = i
      break
    end
  end

  -- Setup displayer
  local displayer = entry_module.create_displayer()

  -- Finder factory
  local function make_finder(style)
    local results = style == "flat" and flat_entries or tree_entries
    return finders.new_table({
      results = results,
      entry_maker = entry_module.make_entry_maker(style, displayer),
    })
  end

  -- Create and open picker
  pickers
    .new(picker_opts, {
      prompt_title = "Buffers",
      finder = make_finder("tree"),
      default_selection_index = default_idx or 1,
      sorter = conf.generic_sorter(picker_opts),
      attach_mappings = function(prompt_bufnr, map)
        local picker = action_state.get_current_picker(prompt_bufnr)
        local style = "tree"

        -- Switch between tree and flat view
        local function switch_to(new_style)
          if new_style == style then
            return
          end

          local selected = action_state.get_selected_entry()
          local keep_bufnr = (selected and selected.kind == "file" and selected.bufnr)
            or vim.api.nvim_get_current_buf()

          style = new_style
          picker:refresh(make_finder(style), { reset_prompt = false })

          vim.schedule(function()
            local results = style == "flat" and flat_entries or tree_entries
            for i, e in ipairs(results) do
              if e.kind == "file" and e.bufnr == keep_bufnr then
                pcall(picker.set_selection, picker, i)
                break
              end
            end
          end)
        end

        -- Auto-switch on insert mode
        if switch_on_insert then
          vim.api.nvim_create_autocmd("InsertEnter", {
            buffer = prompt_bufnr,
            callback = function()
              switch_to("flat")
            end,
          })
          vim.api.nvim_create_autocmd("InsertLeave", {
            buffer = prompt_bufnr,
            callback = function()
              switch_to("tree")
            end,
          })
        end

        -- Apply user-defined mappings
        local function apply_user_mappings(mode)
          local m = user_mappings[mode] or {}
          for lhs, rhs in pairs(m) do
            if type(rhs) == "function" then
              map(mode, lhs, function()
                rhs(prompt_bufnr)
              end)
            end
          end
        end

        -- Select buffer action
        local function select()
          local sel = action_state.get_selected_entry()
          if sel and sel.kind == "file" and sel.bufnr then
            actions.close(prompt_bufnr)
            vim.api.nvim_set_current_buf(sel.bufnr)
          elseif sel and sel.kind == "dir" and type(on_folder_select) == "function" then
            actions.close(prompt_bufnr)
            on_folder_select(sel.path)
          end
        end

        actions.select_default:replace(select)

        -- Delete buffer and clean up empty directories
        local function delete_buffer_and_cleanup()
          local sel = action_state.get_selected_entry()
          if not (sel and sel.kind == "file" and sel.bufnr) then
            return
          end

          -- Don't delete the buffer that was open before Telescope
          if sel.bufnr == current_bufnr then
            vim.notify("Cannot delete current buffer", vim.log.levels.WARN)
            return
          end

          actions.delete_buffer(prompt_bufnr)

          local new_sel = action_state.get_selected_entry()
          local stay_on_bufnr = new_sel and new_sel.kind == "file" and new_sel.bufnr

          -- Rebuild tree to remove empty directories
          items = tree_module.collect_buffers()
          tree_entries = tree_module.make_tree_entries(items, entry_module, diag_opts)
          flat_entries = tree_module.make_flat_entries(items)

          if #items == 0 then
            actions.close(prompt_bufnr)
            return
          end

          picker:refresh(make_finder(style), { reset_prompt = false })

          if stay_on_bufnr then
            vim.schedule(function()
              local results = style == "flat" and flat_entries or tree_entries
              for i, e in ipairs(results) do
                if e.kind == "file" and e.bufnr == stay_on_bufnr then
                  pcall(picker.set_selection, picker, i)
                  return
                end
              end
            end)
          end
        end

        map("n", "dd", delete_buffer_and_cleanup)
        map("i", "<C-d>", delete_buffer_and_cleanup)

        -- Register custom actions
        local actions_map = cfg.actions or {}
        for lhs, rhs in pairs(actions_map) do
          if type(lhs) == "string" and lhs ~= "" and type(rhs) == "function" then
            map("n", lhs, function()
              if action_close then
                actions.close(prompt_bufnr)
              end
              rhs(prompt_bufnr, action_state.get_selected_entry())
            end)
          end
        end

        apply_user_mappings("n")
        apply_user_mappings("i")

        return true
      end,
    })
    :find()
end

return M
