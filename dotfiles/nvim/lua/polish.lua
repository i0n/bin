return {
  polish = function()
    local ts = vim.treesitter

    ---@param node any
    ---@return any
    local function unwrap_ts_capture(node)
      if type(node) ~= "table" then return node end
      if node.node ~= nil then return unwrap_ts_capture(node.node) end
      if #node > 0 then return unwrap_ts_capture(node[#node]) end
      return node
    end

    if not ts._dotfiles_compat_wrapped then
      ts._dotfiles_compat_wrapped = true

      local get_node_text = ts.get_node_text
      ts.get_node_text = function(node, source, opts)
        return get_node_text(unwrap_ts_capture(node), source, opts)
      end

      if type(ts.get_range) == "function" then
        local get_range = ts.get_range
        ts.get_range = function(node, source, metadata)
          return get_range(unwrap_ts_capture(node), source, metadata)
        end
      end

      if type(ts.is_ancestor) == "function" then
        local is_ancestor = ts.is_ancestor
        ts.is_ancestor = function(ancestor, node)
          return is_ancestor(unwrap_ts_capture(ancestor), unwrap_ts_capture(node))
        end
      end
    end

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
