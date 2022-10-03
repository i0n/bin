"dein Scripts-----------------------------
if &compatible
  set nocompatible               " Be iMproved
endif

" Required:
set runtimepath+=/Users/i0n/bin/dotfiles/nvim/dein/.cache/repos/github.com/Shougo/dein.vim

" Required:
if dein#load_state('/Users/i0n/bin/dotfiles/nvim/dein/.cache')
  call dein#begin('/Users/i0n/bin/dotfiles/nvim/dein/.cache')

  " Let dein manage dein
  " Required:
  call dein#add('/Users/i0n/bin/dotfiles/nvim/dein/.cache/repos/github.com/Shougo/dein.vim')

  " Add or remove your plugins here:
  "call dein#add('Shougo/neosnippet.vim')
  "call dein#add('Shougo/neosnippet-snippets')

	call dein#add('scrooloose/nerdtree')
	call dein#add('vim-airline/vim-airline')
	call dein#add('vim-airline/vim-airline-themes')
	call dein#add('kien/ctrlp.vim')
	call dein#add('mileszs/ack.vim')
	call dein#add('tpope/vim-git')
	call dein#add('tpope/vim-fugitive')
	call dein#add('airblade/vim-rooter')
	call dein#add('jlanzarotta/bufexplorer')
	call dein#add('tpope/vim-surround')
	call dein#add('vim-scripts/hexHighlight.vim')
	call dein#add('w0rp/ale')
	call dein#add('fatih/vim-go')
	call dein#add('buoto/gotests-vim')

	""""""""""""""""""""""""""""""""""""""""""""""""""" deoplete
	call dein#add('Shougo/deoplete.nvim')
	if !has('nvim')
		call dein#add('roxma/nvim-yarp')
		call dein#add('roxma/vim-hug-neovim-rpc')
	endif
	"call dein#add('zchee/deoplete-go', {'build': 'make'})
	"""""""""""""""""""""""""""""""""""""""""""""""""""


  " Required:
  call dein#end()
  call dein#save_state()
endif

" Required:
filetype plugin indent on
syntax enable

" If you want to install not installed plugins on startup.
"if dein#check_install()
"  call dein#install()
"endif

"End dein Scripts-------------------------
"
set termguicolors

set showcmd                       " Display incomplete commands.
set showmode                      " Display the mode you're in.

set hidden                        " Handle multiple buffers better.

set wildmenu                      " Enhanced command line completion.
set wildmode=list:longest         " Complete files like a shell.

"set ignorecase                    " Case-insensitive searching.
"set smartcase                     " But case-sensitive if expression contains a capital letter.

set cmdheight=2                   " Number of lines used for the command-line
set number                        " Show line numbers.
set ruler                         " Show cursor position.

set incsearch                     " Highlight matches as you type.
set hlsearch                      " Highlight matches.

set scrolloff=3                   " Show 3 lines of context around the cursor.

set title                         " Set the terminal's title

set visualbell                    " No beeping.

set nobackup                      " Don't make a backup before overwriting a file.
set nowritebackup                 " And again.
set directory=$HOME/.vimtmp//,    " Keep swap files in one location

set clipboard=unnamed            " Set up clipboard
map <F2> ;.w !pbcopy<CR><CR>     " Copies the current line to the clipboard.
map <F3> ;r !pbpaste<CR>         " Pastes the current content from the clipboard.

set shiftwidth=2
set tabstop=2

" For spaces...
"set expandtab
"set softtabstop=2

" For tabs...
set autoindent
set noexpandtab

set backspace=indent,eol,start  " backspace through everything in insert mode
"set smarttab autoindent

" Indentation viewer
let g:indent_guides_enable_on_vim_startup = 0
let g:indent_guides_guide_size = 1
let g:indent_guides_start_level = 2
let g:indent_guides_exclude_filetypes = ['help', 'nerdtree']

"set laststatus=2                 " Show the status line all the time

colorscheme raphael

" Mapping to set leader key
let mapleader=","
let maplocalleader=","

" Mapping terminal command key for quick commands
nmap \ ;!

" Tab mappings.
map <leader>tn ;tabnew<cr>
map <leader>te ;tabedit
map <leader>tc ;tabclose<cr>
map <leader>to ;tabonly<cr>
map <leader>] ;tabnext<cr>
map <leader>[ ;tabprevious<cr>
map <leader>tf ;tabfirst<cr>
map <leader>tl ;tablast<cr>
map <leader>tm ;tabmove

" Finding all todos in project
map <leader>t ;Ack TODO --ignore-dir 'vendor' --ignore-dir 'log' --ignore-dir 'tmp' --ignore-dir 'public'<cr>
" Maps Enter to open QuickFixes currently selected file.
:autocmd BufReadPost quickfix nnoremap <buffer> <CR> <CR>

" Window mappings.
map <leader><Tab> <C-w>w
map <leader>o <C-w>o
map <leader>v <C-w>v<C-w>w
map <leader>h <C-w>s<C-w>w
map <leader>p <C-w>p
map <leader>j <C-w>j
map <leader>k <C-w>k
map <leader>w <C-w>c
map <Leader>y ;%y+<cr>
map <Up> <C-w>k
map <Down> <C-w>j
map <Left> <C-w>h
map <Right> <C-w>l
map  <C-w><C-w>

" swap colon and semicolon for easier commands
nnoremap ; :
nnoremap : ;

vnoremap ; :
vnoremap : ;

" Mappings to make text indentation in command mode easier
nnoremap > >>
nnoremap < <<

" Mappings to make text indentation in visual mode easier
vmap > >gv
vmap < <gv

" Insert mode mappings
" set macmeta
imap ≥  <space>=>
imap ≤ <%= %>
imap <C-Space> %
imap <A-Space> %
" Ctrl-j/k deletes blank line below/above, and Alt-j/k inserts.
nnoremap <silent><C-j> m`:silent +g/\m^\s*$/d<CR>``:noh<CR>
nnoremap <silent><C-k> m`:silent -g/\m^\s*$/d<CR>``:noh<CR>
nnoremap  :set paste<CR>m`o<Esc>``:set nopaste<CR>
nnoremap <S-> :set paste<CR>m`O<Esc>``:set nopaste<CR>
nnoremap <silent>∆ :set paste<CR>m`o<Esc>``:set nopaste<CR>
nnoremap <silent>˚ :set paste<CR>m`O<Esc>``:set nopaste<CR>

" Automatic fold settings for specific files. Uncomment to use.
set foldmethod=manual

" Sets the line height of the preview window
set previewheight=25

" Highlights the current line in all windows
set cursorline
" Stop cursor blink in normal mode
set gcr=n:blinkon0

" Automatically saves files when the buffer is changed
set autowrite

" Auto indent entire file with Alt =
map   <silent> ≠ mmgg=G'm
imap  <silent> ≠ <Esc> mmgg=G'm

" Add auto-expander for Handlebars template tags
imap {{ {{}}<Esc>hi

" Stops vim swapfile alert
set shortmess+=A

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""" airline

set guifont=DejaVu\ Sans\ Mono\ for\ Powerline:h12

let g:airline_powerline_fonts = 1
let g:Powerline_symbols = 'unicode'
let g:airline_theme = 'molokai'
let g:airline#extensions#ale#enabled = 1

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""" ctrlp

nmap <silent> <leader>f ;CtrlP<cr>

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""" NERDTree

map <leader>d ;NERDTreeToggle<cr>
let NERDTreeShowHidden=1

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""" BufExplorer

map <leader>b ;BufExplorer<cr>

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""" hexHighlight

map <leader>c ;call HexHighlight()<cr>

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""" ctrlp & ack

" Use The Silver Searcher https://github.com/ggreer/the_silver_searcher
if executable('ag')

  " Silver Searcher compatibility with Vim.Ack
  let g:ackprg = 'ag --nogroup --nocolor --column'

  " Use Ag over Grep
  set grepprg=ag\ --nogroup\ --nocolor

  " Use ag in CtrlP for listing files. Lightning fast and respects .gitignore
  let g:ctrlp_user_command = 'ag %s -l --nocolor -g ""'

  " ag is fast enough that CtrlP doesn't need to cache
  let g:ctrlp_use_caching = 0
endif

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""" deoplete
set completeopt+=noselect
set completeopt-=preview

let g:deoplete#enable_at_startup = 1

" deoplete-go settings
"let g:deoplete#sources#go#gocode_binary = $GOPATH.'/bin/gocode'
"let g:deoplete#sources#go#sort_class = ['package', 'func', 'type', 'var', 'const']

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""" vim-go

map <C-n> :cnext<CR>
map <C-m> :cprevious<CR>
nnoremap <leader>a :cclose<CR>
autocmd FileType go nmap <leader>r  <Plug>(go-run)
"autocmd FileType go nmap <leader>v  <Plug>(go-vet)
autocmd FileType go nmap <leader>t  <Plug>(go-test)
autocmd FileType go nmap <Leader>c <Plug>(go-coverage-toggle)
autocmd FileType go nmap <Leader>i <Plug>(go-doc)
" run :GoBuild or :GoTestCompile based on the go file
function! s:build_go_files()
  let l:file = expand('%')
  if l:file =~# '^\f\+_test\.go$'
    call go#test#Test(0, 1)
  elseif l:file =~# '^\f\+\.go$'
    call go#cmd#Build(0)
  endif
endfunction

"autocmd FileType go nmap <leader>b :<C-u>call <SID>build_go_files()<CR>
let g:go_list_type = "quickfix"
let g:go_fmt_command = "goimports"
let g:go_addtags_transform = "camelcase"
let g:go_highlight_types = 1
let g:go_highlight_fields = 1
let g:go_highlight_functions = 1
let g:go_highlight_function_calls = 1
let g:go_highlight_operators = 1
let g:go_highlight_build_constraints = 1
let g:go_metalinter_enabled = 0
"let g:go_metalinter_enabled = ['vet', 'golint', 'errcheck']
"let g:go_metalinter_autosave = 1
let g:go_metalinter_deadline = "1s"
autocmd Filetype go command! -bang A call go#alternate#Switch(<bang>0, 'edit')
autocmd Filetype go command! -bang AV call go#alternate#Switch(<bang>0, 'vsplit')
autocmd Filetype go command! -bang AS call go#alternate#Switch(<bang>0, 'split')
autocmd Filetype go command! -bang AT call go#alternate#Switch(<bang>0, 'tabe')
"let g:go_auto_type_info = 1
"set updatetime=100
let g:go_auto_sameids = 1

" Changes the cursor shape in insert mode
set guicursor=i-ci-ve:ver10

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""" neovide
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


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""" ale

"let g:ale_go_gometalinter_options = '--fast --vendor'
"let g:ale_linters = {
"	\'go': ['gometalinter', 'go fmt'],
"\}

let g:ale_linters = {
	\'go': ['gofmt', 'golint', 'go vet'],
\}

"let g:ale_fixers = ['trim_whitespace']

nmap <silent> <C-b> <Plug>(ale_previous_wrap)
nmap <silent> <C-n> <Plug>(ale_next_wrap)

let g:ale_set_loclist = 0
let g:ale_set_quickfix = 0

"let g:ale_open_list = 1
"let g:ale_list_window_size = 5

let g:ale_lint_on_insert_leave = 1
let g:ale_lint_on_text_changed = 'never'
let g:ale_fix_on_save = 1

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""" neosnippet

" Plugin key-mappings.
" Note: It must be "imap" and "smap".  It uses <Plug> mappings.
"imap <C-k>     <Plug>(neosnippet_expand_or_jump)
"smap <C-k>     <Plug>(neosnippet_expand_or_jump)
"xmap <C-k>     <Plug>(neosnippet_expand_target)
"
"" SuperTab like snippets behavior.
"" Note: It must be "imap" and "smap".  It uses <Plug> mappings.
""imap <expr><TAB>
"" \ pumvisible() ? "\<C-n>" :
"" \ neosnippet#expandable_or_jumpable() ?
"" \    "\<Plug>(neosnippet_expand_or_jump)" : "\<TAB>"
"smap <expr><TAB> neosnippet#expandable_or_jumpable() ?
"\ "\<Plug>(neosnippet_expand_or_jump)" : "\<TAB>"
"
"" For conceal markers.
"if has('conceal')
"  set conceallevel=2 concealcursor=niv
"endif
