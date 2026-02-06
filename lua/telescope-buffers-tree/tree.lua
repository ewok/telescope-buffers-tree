--- Tree building module for telescope-buffers-tree.
-- Handles buffer collection, path parsing, and tree structure creation.
-- @module telescope-buffers-tree.tree

local M = {}

-------------------------------------------------------------------------------
-- Path utilities
-------------------------------------------------------------------------------

--- Split a path string into segments by "/".
-- @param p string Path to split
-- @return table Array of path segments
function M.split_path(p)
  local t = {}
  for s in p:gmatch("[^/]+") do
    t[#t + 1] = s
  end
  return t
end

--- Parse a path into segments, handling special prefixes (/, ~).
-- @param p string Path to parse
-- @return table Array of path segments including prefix
function M.segments_for_path(p)
  if not p or p == "" then
    return {}
  end
  if p == "~" then
    return { "~" }
  end

  local prefix, rest
  if p:sub(1, 1) == "/" then
    prefix, rest = "/", p:sub(2)
  elseif p:sub(1, 2) == "~/" then
    prefix, rest = "~", p:sub(3)
  end

  local seg = M.split_path(rest or p)
  if prefix then
    table.insert(seg, 1, prefix)
  end
  return seg
end

--- Join path segments back into a path string.
-- @param segs table Array of path segments
-- @param n number|nil Number of segments to join (default: all)
-- @return string Joined path
function M.join(segs, n)
  n = n or #segs
  if n <= 0 then
    return ""
  end

  local first = segs[1]
  if n == 1 then
    return first
  end

  if first == "/" then
    return "/" .. table.concat(segs, "/", 2, n)
  elseif first == "~" then
    return "~/" .. table.concat(segs, "/", 2, n)
  end
  return table.concat(segs, "/", 1, n)
end

--- Get display path for a buffer (relative to cwd, using ~ for home).
-- @param name string Buffer name (full path)
-- @return string Display path
function M.path_for_buf(name)
  return (name and name ~= "") and vim.fn.fnamemodify(name, ":~:.") or "[No Name]"
end

--- Create ordinal string for telescope filtering.
-- @param path string|nil File path
-- @param name string|nil File name
-- @param bufnr number|nil Buffer number
-- @return string Ordinal string for filtering
function M.make_ordinal(path, name, bufnr)
  return (path or name or "") .. " " .. tostring(bufnr or "")
end

-------------------------------------------------------------------------------
-- Buffer collection
-------------------------------------------------------------------------------

--- Collect all listed buffers with path information.
-- @return table Array of buffer items with kind, name, path, bufnr, seg
function M.collect_buffers()
  local bufs = vim.fn.getbufinfo({ buflisted = 1 })
  local items = {}

  for _, b in ipairs(bufs) do
    local name = vim.api.nvim_buf_get_name(b.bufnr)
    local p = M.path_for_buf(name)
    items[#items + 1] = {
      kind = "file",
      name = vim.fs.basename(p),
      path = p,
      bufnr = b.bufnr,
      seg = M.segments_for_path(p),
    }
  end

  -- Sort by path depth, then alphabetically
  table.sort(items, function(a, b)
    if a.path == "[No Name]" and b.path ~= "[No Name]" then
      return false
    end
    if b.path == "[No Name]" and a.path ~= "[No Name]" then
      return true
    end

    local da = select(2, a.path:gsub("/", ""))
    local db = select(2, b.path:gsub("/", ""))
    if da ~= db then
      return da < db
    end
    return a.path < b.path
  end)

  return items
end

-------------------------------------------------------------------------------
-- Tree building
-------------------------------------------------------------------------------

--- Sort children nodes (directories first, then files, alphabetically).
-- @param children table List of child nodes
-- @param is_root boolean If true, "/" and "~" directories are sorted last
local function sort_children(children, is_root)
  table.sort(children, function(a, b)
    local function rank(x)
      if x.kind == "dir" then
        if is_root and (x.name == "/" or x.name == "~") then
          return 2
        end
        return 0
      end
      return 1
    end

    local ra, rb = rank(a), rank(b)
    if ra ~= rb then
      return ra < rb
    end
    return (a.name or "") < (b.name or "")
  end)
end

--- Compress single-child directory chains into combined names.
-- Example: a/b/c with single children becomes "a/b/c" as one node.
-- @param node table Directory node to compress
-- @return table Compressed node
local function compress_empty_dirs(node)
  if node.kind ~= "dir" or node.name == "/" or node.name == "~" then
    return node
  end

  while node.children and #node.children == 1 and node.children[1].kind == "dir" do
    local child = node.children[1]
    node.name = node.name .. "/" .. child.name
    node.path = child.path
    node.children = child.children
  end

  return node
end

--- Build tree entries from buffer items for tree-style display.
-- @param items table Buffer items from collect_buffers()
-- @param entry_module table Entry module for icon/diagnostic functions
-- @param diag_opts table|nil Diagnostics config { enable = bool, signs = table }
-- @return table Array of tree entry nodes
function M.make_tree_entries(items, entry_module, diag_opts)
  local root = { kind = "root", name = "", children = {} }
  local dir_by_path = { [""] = root }
  local nodes = {}

  local function ensure_dir(dir_path, name, parent)
    if dir_by_path[dir_path] then
      return dir_by_path[dir_path]
    end
    local n = { kind = "dir", name = name, path = dir_path, children = {} }
    dir_by_path[dir_path] = n
    parent.children[#parent.children + 1] = n
    return n
  end

  -- Build tree structure
  for _, it in ipairs(items) do
    local seg = it.seg
    local parent = root

    for i = 1, #seg - 1 do
      local dir_path = M.join(seg, i)
      parent = ensure_dir(dir_path, seg[i], parent)
    end

    local file_name = seg[#seg] or it.path
    local file_node = {
      kind = "file",
      name = file_name,
      path = it.path,
      bufnr = it.bufnr,
    }
    parent.children[#parent.children + 1] = file_node
  end

  -- Flatten tree with indentation
  local function walk(n, prefix, is_root)
    if not n.children then
      return
    end

    sort_children(n.children, is_root)

    for idx, ch in ipairs(n.children) do
      if ch.kind == "dir" then
        ch = compress_empty_dirs(ch)
      end

      local last = idx == #n.children
      local connector = is_root and "" or (last and "└── " or "├── ")
      local next_prefix = is_root and "" or (prefix .. (last and "    " or "│   "))
      local tree = prefix .. connector

      -- Format label with trailing slash for directories
      local label = ch.name
      if ch.kind == "dir" then
        if label == "/" then
          label = "/"
        elseif label == "~" then
          label = "~/"
        else
          label = label .. "/"
        end
      end

      -- Get icon for entry
      local icon, icon_hl = entry_module.get_icon(ch.kind, ch.name)

      -- Get diagnostic icon for file entries (if enabled)
      local diag_icon, diag_hl
      if ch.kind == "file" and diag_opts and diag_opts.enable then
        diag_icon, diag_hl = entry_module.get_diagnostic_icon(ch.bufnr, diag_opts.signs or {})
      end

      nodes[#nodes + 1] = {
        kind = ch.kind,
        bufnr = ch.bufnr,
        path = ch.path,
        ordinal = M.make_ordinal(ch.path, ch.name, ch.bufnr),
        tree = tree,
        text = label,
        icon = icon,
        icon_hl = icon_hl,
        diag_icon = diag_icon,
        diag_hl = diag_hl,
      }

      if ch.kind == "dir" then
        walk(ch, next_prefix, false)
      end
    end
  end

  walk(root, "", true)
  return nodes
end

--- Build flat entries from buffer items for filtered display.
-- @param items table Buffer items from collect_buffers()
-- @return table Array of flat entry nodes
function M.make_flat_entries(items)
  local nodes = {}
  for _, it in ipairs(items) do
    nodes[#nodes + 1] = {
      kind = "file",
      name = it.name,
      path = it.path,
      bufnr = it.bufnr,
      ordinal = M.make_ordinal(it.path, nil, it.bufnr),
      tree = "",
      text = it.path,
    }
  end
  return nodes
end

return M
