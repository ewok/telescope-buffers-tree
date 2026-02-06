# telescope-buffers-tree

A [Telescope](https://github.com/nvim-telescope/telescope.nvim) extension that displays open buffers in a hierarchical tree view, grouped by directory structure.

![Demo](https://img.shields.io/badge/demo-placeholder-blue?style=flat-square)

## Features

- **Tree View**: Displays buffers organized by their directory hierarchy
- **Smart Filtering**: Automatically switches to flat list when typing (insert mode) for easy fuzzy finding
- **File Icons**: Optional integration with [mini.icons](https://github.com/echasnovski/mini.icons) for file/directory icons
- **Diagnostics**: Shows diagnostic indicators (errors, warnings)
- **Buffer Deletion**: Delete buffers with `dd` (normal) or `<C-d>` (insert)

## Comparison with `:Telescope buffers`

| Feature | `:Telescope buffers` | `:Telescope buffers_tree` |
|---------|---------------------|---------------------------|
| Display | Flat list | Hierarchical tree |
| Grouping | None | By directory |
| Directory visibility | Hidden in path | Explicit nodes |
| Empty dir cleanup | N/A | Automatic |
| Insert mode | Same view | Switches to flat for filtering |

## Requirements

- Neovim >= 0.9.0
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
- [mini.icons](https://github.com/echasnovski/mini.icons) (optional, for file icons)

## Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "ewok/telescope-buffers-tree",
  dependencies = {
    "nvim-telescope/telescope.nvim",
    "echasnovski/mini.icons", -- optional
  },
  config = function()
    require("telescope").load_extension("buffers_tree")
  end,
}
```

### [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "ewok/telescope-buffers-tree",
  requires = {
    "nvim-telescope/telescope.nvim",
    "echasnovski/mini.icons", -- optional
  },
  config = function()
    require("telescope").load_extension("buffers_tree")
  end,
}
```

### [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'nvim-telescope/telescope.nvim'
Plug 'echasnovski/mini.icons' " optional
Plug 'ewok/telescope-buffers-tree'

" In your init.vim/init.lua after plug#end():
lua require("telescope").load_extension("buffers_tree")
```

## Configuration

Configure the extension via `telescope.setup()`:

```lua
require("telescope").setup({
  extensions = {
    buffers_tree = {
      -- Theme: "dropdown", "ivy", "cursor", or custom function
      theme = "dropdown",

      -- Options passed to the theme function
      theme_opts = {},

      -- Initial mode: "normal" or "insert"
      initial_mode = "normal",

      -- Show file previewer
      previewer = false,

      -- Auto-switch to flat list in insert mode (for filtering)
      switch_on_insert = true,

      -- Close picker after executing an action
      action_close = true,

      -- Diagnostics: false, true, or table with custom signs
      diagnostics = false,
      -- Example with custom signs:
      -- diagnostics = {
      --   signs = {
      --     error = { "", "DiagnosticError" },
      --     warn = { "", "DiagnosticWarn" },
      --     info = { "", "DiagnosticInfo" },
      --     hint = { "", "DiagnosticHint" },
      --   },
      -- },

      -- Custom actions (normal mode mappings)
      actions = {
        -- ["<C-v>"] = function(prompt_bufnr, entry)
        --   vim.cmd("vsplit")
        --   vim.api.nvim_set_current_buf(entry.bufnr)
        -- end,
      },

      -- Custom telescope mappings
      mappings = {
        n = {},
        i = {},
      },

      -- Callback when selecting a directory node
      on_folder_select = nil,
      -- Example: open directory in file browser
      -- on_folder_select = function(path)
      --   require("telescope").extensions.file_browser.file_browser({ path = path })
      -- end,
    },
  },
})

-- Load the extension
require("telescope").load_extension("buffers_tree")
```

## Usage

### Commands

```vim
:Telescope buffers_tree
```

### Lua API

```lua
-- Open with default configuration
require("telescope").extensions.buffers_tree.buffers_tree()

-- Open with custom options (overrides global config)
require("telescope").extensions.buffers_tree.buffers_tree({
  theme = "ivy",
  diagnostics = true,
})
```

### Suggested Keymap

```lua
vim.keymap.set("n", "<leader>bb", function()
  require("telescope").extensions.buffers_tree.buffers_tree()
end, { desc = "Buffer tree" })
```

## Mappings

### Default Mappings

| Mode | Key | Action |
|------|-----|--------|
| `n` | `<CR>` | Open selected buffer |
| `n` | `dd` | Delete buffer (rebuilds tree) |
| `i` | `<C-d>` | Delete buffer (rebuilds tree) |
| `n`/`i` | (standard) | All default Telescope mappings |

### View Switching

- **Insert mode**: Automatically switches to flat list for easy fuzzy filtering
- **Normal mode**: Returns to tree view

## Health Check

Run the health check to verify the extension is properly configured:

```vim
:checkhealth telescope
```

## Documentation

For detailed documentation, see:

```vim
:help telescope-buffers-tree
```

## License

MIT License - see [LICENSE](LICENSE) for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Credits

- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) - The amazing fuzzy finder
- [mini.icons](https://github.com/echasnovski/mini.icons) - Beautiful file icons
