--              AstroNvim Configuration Table
-- All configuration changes should go inside of the table below
-- You can think of a Lua "table" as a dictionary like data structure the
-- normal format is "key = value". These also handle array like data structures
-- where a value with no key simply has an implicit numeric key

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

local config = {

  -- Configure AstroNvim updates
  updater = {
    remote = "origin", -- remote to use
    channel = "stable", -- "stable" or "nightly"
    version = "latest", -- "latest", tag name, or regex search like "v1.*" to only do updates before v2 (STABLE ONLY)
    branch = "main", -- branch name (NIGHTLY ONLY)
    commit = nil, -- commit hash (NIGHTLY ONLY)
    pin_plugins = nil, -- nil, true, false (nil will pin plugins on stable only)
    skip_prompts = false, -- skip prompts about breaking changes
    show_changelog = true, -- show the changelog after performing an update
    auto_reload = false, -- automatically reload and sync packer after a successful update
    auto_quit = false, -- automatically quit the current session after a successful update
    -- remotes = { -- easily add new remotes to track
    --   ["remote_name"] = "https://remote_url.come/repo.git", -- full remote url
    --   ["remote2"] = "github_user/repo", -- GitHub user/repo shortcut,
    --   ["remote3"] = "github_user", -- GitHub user assume AstroNvim fork
    -- },
  },

  -- Set colorscheme to use
--  colorscheme = "default_theme",
--  colorscheme = "gruvbox",
  colorscheme = "tokyonight-night",

  -- Add highlight groups in any theme
  highlights = {
    -- init = { -- this table overrides highlights in all themes
    --   Normal = { bg = "#000000" },
    -- }
    -- duskfox = { -- a table of overrides/changes to the duskfox theme
    --   Normal = { bg = "#000000" },
    -- },
  },

  -- set vim options here (vim.<first_key>.<second_key> =  value)
  options = {
    opt = {
      -- set to true or false etc.
      relativenumber = true, -- sets vim.opt.relativenumber
      number = true, -- sets vim.opt.number
      spell = true, -- sets vim.opt.spell
      signcolumn = "auto", -- sets vim.opt.signcolumn to auto
      -- Line wrapping...
      textwidth = 0,
      wrap = true, -- sets vim.opt.wrap
    },
    g = {
      mapleader = ",", -- sets vim.g.mapleader
      cmp_enabled = true, -- enable completion at start
      autopairs_enabled = true, -- enable autopairs at start
      diagnostics_enabled = true, -- enable diagnostics at start
      status_diagnostics_enabled = true, -- enable diagnostics in statusline
    },
  },
  -- If you need more control, you can use the function()...end notation
  -- options = function(local_vim)
  --   local_vim.opt.relativenumber = true
  --   local_vim.g.mapleader = " "
  --   local_vim.opt.whichwrap = vim.opt.whichwrap - { 'b', 's' } -- removing option from list
  --   local_vim.opt.shortmess = vim.opt.shortmess + { I = true } -- add to option list
  --
  --   return local_vim
  -- end,

  -- Set dashboard header
  header = {
    " █████  ███████ ████████ ██████   ██████",
    "██   ██ ██         ██    ██   ██ ██    ██",
    "███████ ███████    ██    ██████  ██    ██",
    "██   ██      ██    ██    ██   ██ ██    ██",
    "██   ██ ███████    ██    ██   ██  ██████",
    " ",
    "    ███    ██ ██    ██ ██ ███    ███",
    "    ████   ██ ██    ██ ██ ████  ████",
    "    ██ ██  ██ ██    ██ ██ ██ ████ ██",
    "    ██  ██ ██  ██  ██  ██ ██  ██  ██",
    "    ██   ████   ████   ██ ██      ██",
  },

  -- Default theme configuration
  default_theme = {
    -- Modify the color palette for the default theme
    -- colors = {
    --   fg = "#abb2bf",
    --   bg = "#1e222a",
    -- },
    -- highlights = function(hl) -- or a function that returns a new table of colors to set
    --   local C = require "default_theme.colors"

    --   hl.Normal = { fg = C.fg, bg = C.bg }

    --   -- New approach instead of diagnostic_style
    --   hl.DiagnosticError.italic = true
    --   hl.DiagnosticHint.italic = true
    --   hl.DiagnosticInfo.italic = true
    --   hl.DiagnosticWarn.italic = true

    --   return hl
    -- end,
    -- enable or disable highlighting for extra plugins
    plugins = {
      aerial = true,
      beacon = false,
      bufferline = true,
      dashboard = true,
      highlighturl = true,
      hop = false,
      indent_blankline = true,
      lightspeed = false,
      ["neo-tree"] = true,
      notify = true,
      ["nvim-tree"] = false,
      ["nvim-web-devicons"] = true,
      rainbow = true,
      symbols_outline = false,
      telescope = true,
      vimwiki = false,
      ["which-key"] = true,
    },
  },

  -- Diagnostics configuration (for vim.diagnostics.config({...})) when diagnostics are on
  diagnostics = {
    virtual_text = true,
    underline = true,
  },

  -- Extend LSP configuration
  lsp = {
    -- enable servers that you already have installed without mason
    servers = {
      -- "pyright"
    },
    formatting = {
      disabled = { -- disable formatting capabilities for the listed clients
        -- "sumneko_lua",
      },
      -- filter = function(client) -- fully override the default formatting function
      --   return true
      -- end
    },
    -- easily add or disable built in mappings added during LSP attaching
    mappings = {
      n = {
        -- ["<leader>lf"] = false -- disable formatting keymap
      },
    },
    -- add to the global LSP on_attach function
    -- on_attach = function(client, bufnr)
    -- end,

    -- override the mason server-registration function
    -- server_registration = function(server, opts)
    --   require("lspconfig")[server].setup(opts)
    -- end,

    -- Add overrides for LSP server settings, the keys are the name of the server
    ["server-settings"] = {
      -- example for addings schemas to yamlls
      -- yamlls = { -- override table for require("lspconfig").yamlls.setup({...})
      --   settings = {
      --     yaml = {
      --       schemas = {
      --         ["http://json.schemastore.org/github-workflow"] = ".github/workflows/*.{yml,yaml}",
      --         ["http://json.schemastore.org/github-action"] = ".github/action.{yml,yaml}",
      --         ["http://json.schemastore.org/ansible-stable-2.9"] = "roles/tasks/*.{yml,yaml}",
      --       },
      --     },
      --   },
      -- },
    },
  },

  -- Mapping data with "desc" stored directly by vim.keymap.set().
  --
  -- Please use this mappings table to set keyboard mapping since this is the
  -- lower level configuration and more robust one. (which-key will
  -- automatically pick-up stored data by this setting.)
  mappings = {
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
  },

  -- Configure plugins
  plugins = {
    init = {
      {"folke/tokyonight.nvim"},
    },
    -- All other entries override the require("<key>").setup({...}) call for default plugins
    ["null-ls"] = function(config) -- overrides `require("null-ls").setup(config)`
      -- config variable is the default configuration table for the setup functino call
      -- local null_ls = require "null-ls"

      -- Check supported formatters and linters
      -- https://github.com/jose-elias-alvarez/null-ls.nvim/tree/main/lua/null-ls/builtins/formatting
      -- https://github.com/jose-elias-alvarez/null-ls.nvim/tree/main/lua/null-ls/builtins/diagnostics
      config.sources = {
        -- Set a formatter
        -- null_ls.builtins.formatting.stylua,
        -- null_ls.builtins.formatting.prettier,
      }
      return config -- return final config table
    end,
    ["neo-tree"] = {
      filesystem = {
        filtered_items = {
          visible = true, -- This is what you want: If you set this to `true`, all "hide" just mean "dimmed out"
          hide_dotfiles = false,
          hide_gitignored = false,
        },
      },
    },
    treesitter = { -- overrides `require("treesitter").setup(...)`
      -- ensure_installed = { "lua" },
    },
    -- use mason-lspconfig to configure LSP installations
    ["mason-lspconfig"] = { -- overrides `require("mason-lspconfig").setup(...)`
      -- ensure_installed = { "sumneko_lua" },
    },
    -- use mason-tool-installer to configure DAP/Formatters/Linter installation
    ["mason-tool-installer"] = { -- overrides `require("mason-tool-installer").setup(...)`
      -- ensure_installed = { "prettier", "stylua" },
    },
  },

  -- LuaSnip Options
  luasnip = {
    -- Add paths for including more VS Code style snippets in luasnip
    vscode_snippet_paths = {},
    -- Extend filetypes
    filetype_extend = {
      -- javascript = { "javascriptreact" },
    },
  },

  -- CMP Source Priorities
  -- modify here the priorities of default cmp sources
  -- higher value == higher priority
  -- The value can also be set to a boolean for disabling default sources:
  -- false == disabled
  -- true == 1000
  cmp = {
    source_priority = {
      nvim_lsp = 1000,
      luasnip = 750,
      buffer = 500,
      path = 250,
    },
  },

  -- Modify which-key registration (Use this with mappings table in the above.)
  ["which-key"] = {
    -- Add bindings which show up as group name
    register = {
      -- first key is the mode, n == normal mode
      n = {
        -- second key is the prefix, <leader> prefixes
        ["<leader>"] = {
          -- third key is the key to bring up next level and its displayed
          -- group name in which-key top level menu
          ["b"] = { name = "Buffer" },
        },
      },
    },
  },

  -- This function is run last and is a good place to configuring
  -- augroups/autocommands and custom filetypes also this just pure lua so
  -- anything that doesn't fit in the normal config locations above can go here
  polish = function()
    -- neovide
    vim.cmd([[
      if exists('g:neovide')
        let g:neovide_input_use_logo=v:true
        " copy
        vnoremap <D-c> "+y

        " paste
        nnoremap <D-v> "+p
        inoremap <D-v> <Esc>"+pa
        cnoremap <D-v> <c-r>+

        " undo
        nnoremap <D-z> u
        inoremap <D-z> <Esc>ua
      endif
    ]])

    -- Ctrl-j/k deletes blank line below/above
    vim.cmd([[
      nnoremap <silent><C-j> m`:silent +g/\m^\s*$/d<CR>``:noh<CR>
    ]])
    vim.cmd([[
      nnoremap <silent><C-k> m`:silent -g/\m^\s*$/d<CR>``:noh<CR>
    ]])

    -- Fix for neo-tree not setting wrap on windows it opens if it is the first window opened.
    vim.cmd([[
      augroup WrapAlways
        autocmd!
        autocmd FileType * setlocal wrap
      augroup END
    ]])

  end,
}

return config
