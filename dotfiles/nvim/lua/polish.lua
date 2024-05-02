return {
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
