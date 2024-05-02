-- Mapping data with "desc" stored directly by vim.keymap.set().
--
-- Please use this mappings table to set keyboard mapping since this is the
-- lower level configuration and more robust one. (which-key will
-- automatically pick-up stored data by this setting.)
--
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

return {
  -- first key is the mode
  n = {
    -- second key is the lefthand side of the map
    --
    -- Swap colon and semicolon for easier commands
    [";"] = { ":" },
    [":"] = { ";" },
    -- Move to window using arrow keys
    ["<Up>"] = { "<C-w>k" },
    ["<Down>"] = { "<C-w>j" },
    ["<Left>"] = { "<C-w>h" },
    ["<Right>"] = { "<C-w>l" },
    -- File browser
    ["<leader>d"] = { ":Neotree toggle filesystem<cr>" },
    ["<leader>b"] = { ":Neotree toggle buffers<cr>" },
    -- Create new vertical and horizontal windows
    ["<leader>v"] = { "<C-w>v<C-w>w" },
    ["<leader>h"] = { "<C-w>s<C-w>w" },
    -- Default OS X tab behaviour
    -- Weird mapping bug where mapping without shift works with shift
    ["<D-[>"] = { ":bprev<cr>" },
    ["<D-]>"] = { ":bnext<cr>" },
    --Close window
    ["<D-w>"] = { ":Bdelete<cr>" },
    -- alt j/k for adding blank lines. Functions at top of file.
    ["˚"] = function() paste_blank_line_above() end,
    ["∆"] = function() paste_blank_line_below() end,
    -- (ctrl n / ctrl p) Next and previous error from LSP
    ["<C-p>"] = { function() vim.diagnostic.goto_prev() end, desc = "Previous diagnostic" },
    ["<C-n>"] = { function() vim.diagnostic.goto_next() end, desc = "Next diagnostic" },
    -- Mappings to make text indentation in command mode easier
    [">"] = { ">>" },
    ["<"] = { "<<" },
  },
  t = {
    -- setting a mapping to false will disable it
    -- ["<esc>"] = false,
  },
}
