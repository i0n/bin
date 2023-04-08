-- Mapping data with "desc" stored directly by vim.keymap.set().
--
-- Please use this mappings table to set keyboard mapping since this is the
-- lower level configuration and more robust one. (which-key will
-- automatically pick-up stored data by this setting.)
return {
  -- first key is the mode
  n = {
    -- second key is the lefthand side of the map
    -- mappings seen under group name "Buffer"
    ["<leader>bb"] = { "<cmd>tabnew<cr>", desc = "New tab" },
    ["<leader>bj"] = { "<cmd>BufferLinePick<cr>", desc = "Pick to jump" },
    ["<leader>bt"] = { "<cmd>BufferLineSortByTabs<cr>", desc = "Sort by tabs" },
    ["<leader>bc"] = { "<cmd>BufferLinePickClose<cr>", desc = "Pick to close" },

    -- Swap colon and semicolon for easier commands
    [";"] = { ":"},
    [":"] = { ";"},

    -- Move to window using arrow keys
    ["<Up>"] = { "<C-w>k"},
    ["<Down>"] = { "<C-w>j" },
    ["<Left>"] = { "<C-w>h" },
    ["<Right>"] = { "<C-w>l"},

    -- File browser
    ["<leader>d"] = { ":Neotree toggle<cr>"},


    -- Create new vertical and horizontal windows
    ["<leader>v"] = { "<C-w>v<C-w>w"},
    ["<leader>h"] = { "<C-w>s<C-w>w"},

    -- Default OS X tab behaviour
    -- Weird mapping bug where mapping without shift works with shift
    ["<D-[>"] = { ":BufferLineCyclePrev<cr>"},
    ["<D-]>"] = { ":BufferLineCycleNext<cr>"},

    --Close window
    ["<D-w>"] = { ":Bdelete<cr>"},

    -- alt j/k for adding blank lines. Functions at top of file.
    ["˚"] = function() paste_blank_line_above() end,
    ["∆"] = function() paste_blank_line_below() end,

    -- (ctrl n / ctrl p) Next and previous error from LSP 
    ["<C-p>"] = { function() vim.diagnostic.goto_prev() end, desc = "Previous diagnostic" },
    ["<C-n>"] = { function() vim.diagnostic.goto_next() end, desc = "Next diagnostic" },

    -- Mappings to make text indentation in command mode easier
    [">"] = { ">>"},
    ["<"] = { "<<"},

    -- quick save
    -- ["<C-s>"] = { ":w!<cr>", desc = "Save File" },  -- change description but the same command
  },
  t = {
    -- setting a mapping to false will disable it
    -- ["<esc>"] = false,
  },
}
