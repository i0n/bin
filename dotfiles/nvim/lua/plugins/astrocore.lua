-- AstroCore provides a central place to modify mappings, vim options, autocommands, and more!
-- Configuration documentation can be found with `:h astrocore`
-- NOTE: We highly recommend setting up the Lua Language Server (`:LspInstall lua_ls`)
--       as this provides autocomplete and documentation while editing

-- Functions for adding blank lines. Mapped to ctrl/alt k
local function create_array(count, item)
  local array = {}
  for _ = 1, count do
    table.insert(array, item)
  end
  return array
end

local function paste_blank_line(line)
  local lines = create_array(vim.v.count1, "")
  vim.api.nvim_buf_set_lines(0, line, line, true, lines)
end

local function paste_blank_line_above()
  paste_blank_line(vim.fn.line(".") - 1)
end

local function paste_blank_line_below()
  paste_blank_line(vim.fn.line("."))
end

---@type LazySpec
return {
  "AstroNvim/astrocore",
  ---@type AstroCoreOpts
  opts = {
    -- Configure core features of AstroNvim
    features = {
      large_buf = { size = 1024 * 500, lines = 10000 }, -- set global limits for large files for disabling features like treesitter
      autopairs = true, -- enable autopairs at start
      cmp = true, -- enable completion at start
      diagnostics = { virtual_text = true, virtual_lines = false }, -- diagnostic settings on startup
      highlighturl = true, -- highlight URLs at start
      notifications = true, -- enable notifications at start
    },
    -- Diagnostics configuration (for vim.diagnostics.config({...})) when diagnostics are on
    diagnostics = {
      virtual_text = true,
      underline = true,
    },
    -- vim options can be configured here
    options = {
      opt = { -- vim.opt.<key>
        relativenumber = false, -- sets vim.opt.relativenumber
        number = true, -- sets vim.opt.number
        spell = false, -- sets vim.opt.spell
        signcolumn = "auto", -- sets vim.opt.signcolumn to auto
        wrap = false, -- sets vim.opt.wrap
      },
      g = { -- vim.g.<key>
      },
    },
    -- Mappings can be configured through AstroCore as well.
    -- NOTE: keycodes follow the casing in the vimdocs. For example, `<Leader>` must be capitalized
    mappings = {
      -- first key is the mode
      n = {
        -- second key is the lefthand side of the map

        -- navigate buffer tabs with `H` and `L`
        L = { function() require("astrocore.buffer").nav(vim.v.count1) end, desc = "Next buffer" },
        H = { function() require("astrocore.buffer").nav(-vim.v.count1) end, desc = "Previous buffer" },

        -- mappings seen under group name "Buffer"
        ["<Leader>bD"] = {
          function()
            require("astroui.status.heirline").buffer_picker(
              function(bufnr) require("astrocore.buffer").close(bufnr) end
            )
          end,
          desc = "Pick to close",
        },
        -- quick save
        -- ["<C-s>"] = { ":w!<cr>", desc = "Save File" },  -- change description but the same command
        -- Swap colon and semicolon for easier commands
        [";"] = { ":" },
        [":"] = { ";" },
        -- Move to window using arrow keys
        ["<Up>"] = { "<C-w>k" },
        ["<Down>"] = { "<C-w>j" },
        ["<Left>"] = { "<C-w>h" },
        ["<Right>"] = { "<C-w>l" },
        -- File browser
        ["<Leader>d"] = { ":Neotree toggle filesystem<cr>", desc = "Toggle file explorer" },
        ["<Leader>b"] = { ":Neotree toggle buffers<cr>", desc = "Toggle buffer explorer" },
        -- Create new vertical and horizontal windows
        ["<Leader>v"] = { "<C-w>v<C-w>w", desc = "Vertical split" },
        ["<Leader>h"] = { "<C-w>s<C-w>w", desc = "Horizontal split" },
        -- Default OS X tab behaviour
        -- Weird mapping bug where mapping without shift works with shift
        ["<D-[>"] = { ":bprev<cr>" },
        ["<D-]>"] = { ":bnext<cr>" },
        --Close window
        ["<D-w>"] = { function() require("astrocore.buffer").close() end, desc = "Close buffer" },
        -- alt j/k for adding blank lines. Functions at top of file.
        ["˚"] = function() paste_blank_line_above() end,
        ["∆"] = function() paste_blank_line_below() end,
        -- (ctrl n / ctrl p) Next and previous error from LSP
        ["<C-p>"] = { function() vim.diagnostic.jump { count = -vim.v.count1 } end, desc = "Previous diagnostic" },
        ["<C-n>"] = { function() vim.diagnostic.jump { count = vim.v.count1 } end, desc = "Next diagnostic" },
        -- Mappings to make text indentation in command mode easier
        [">"] = { ">>" },
        ["<"] = { "<<" },
      },
      t = {
        -- setting a mapping to false will disable it
        -- ["<esc>"] = false,
      },
    },
  },
}
