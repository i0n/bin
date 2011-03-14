" Vim color scheme
"
" Name:         raphael.vim
" Maintainer:   Ian Alexander Wood <ianalexanderwood@gmail.com>
" Last Change:  14 Mar 2011
" License:      WTFPL <http://sam.zoy.org/wtfpl/>
" Version:      0.1

set background=dark

if version > 580
	hi clear
	if exists("syntax_on")
		syntax reset
	endif
endif

let g:colors_name = "raphael"

if !has("gui_running") && &t_Co != 88 && &t_Co != 256
	finish
endif

" functions {{{
" returns an approximate grey index for the given grey level
fun <SID>grey_number(x)
	if &t_Co == 88
		if a:x < 23
			return 0
		elseif a:x < 69
			return 1
		elseif a:x < 103
			return 2
		elseif a:x < 127
			return 3
		elseif a:x < 150
			return 4
		elseif a:x < 173
			return 5
		elseif a:x < 196
			return 6
		elseif a:x < 219
			return 7
		elseif a:x < 243
			return 8
		else
			return 9
		endif
	else
		if a:x < 14
			return 0
		else
			let l:n = (a:x - 8) / 10
			let l:m = (a:x - 8) % 10
			if l:m < 5
				return l:n
			else
				return l:n + 1
			endif
		endif
	endif
endfun

" returns the actual grey level represented by the grey index
fun <SID>grey_level(n)
	if &t_Co == 88
		if a:n == 0
			return 0
		elseif a:n == 1
			return 46
		elseif a:n == 2
			return 92
		elseif a:n == 3
			return 115
		elseif a:n == 4
			return 139
		elseif a:n == 5
			return 162
		elseif a:n == 6
			return 185
		elseif a:n == 7
			return 208
		elseif a:n == 8
			return 231
		else
			return 255
		endif
	else
		if a:n == 0
			return 0
		else
			return 8 + (a:n * 10)
		endif
	endif
endfun

" returns the palette index for the given grey index
fun <SID>grey_color(n)
	if &t_Co == 88
		if a:n == 0
			return 16
		elseif a:n == 9
			return 79
		else
			return 79 + a:n
		endif
	else
		if a:n == 0
			return 16
		elseif a:n == 25
			return 231
		else
			return 231 + a:n
		endif
	endif
endfun

" returns an approximate color index for the given color level
fun <SID>rgb_number(x)
	if &t_Co == 88
		if a:x < 69
			return 0
		elseif a:x < 172
			return 1
		elseif a:x < 230
			return 2
		else
			return 3
		endif
	else
		if a:x < 75
			return 0
		else
			let l:n = (a:x - 55) / 40
			let l:m = (a:x - 55) % 40
			if l:m < 20
				return l:n
			else
				return l:n + 1
			endif
		endif
	endif
endfun

" returns the actual color level for the given color index
fun <SID>rgb_level(n)
	if &t_Co == 88
		if a:n == 0
			return 0
		elseif a:n == 1
			return 139
		elseif a:n == 2
			return 205
		else
			return 255
		endif
	else
		if a:n == 0
			return 0
		else
			return 55 + (a:n * 40)
		endif
	endif
endfun

" returns the palette index for the given R/G/B color indices
fun <SID>rgb_color(x, y, z)
	if &t_Co == 88
		return 16 + (a:x * 16) + (a:y * 4) + a:z
	else
		return 16 + (a:x * 36) + (a:y * 6) + a:z
	endif
endfun

" returns the palette index to approximate the given R/G/B color levels
fun <SID>color(r, g, b)
	" get the closest grey
	let l:gx = <SID>grey_number(a:r)
	let l:gy = <SID>grey_number(a:g)
	let l:gz = <SID>grey_number(a:b)

	" get the closest color
	let l:x = <SID>rgb_number(a:r)
	let l:y = <SID>rgb_number(a:g)
	let l:z = <SID>rgb_number(a:b)

	if l:gx == l:gy && l:gy == l:gz
		" there are two possibilities
		let l:dgr = <SID>grey_level(l:gx) - a:r
		let l:dgg = <SID>grey_level(l:gy) - a:g
		let l:dgb = <SID>grey_level(l:gz) - a:b
		let l:dgrey = (l:dgr * l:dgr) + (l:dgg * l:dgg) + (l:dgb * l:dgb)
		let l:dr = <SID>rgb_level(l:gx) - a:r
		let l:dg = <SID>rgb_level(l:gy) - a:g
		let l:db = <SID>rgb_level(l:gz) - a:b
		let l:drgb = (l:dr * l:dr) + (l:dg * l:dg) + (l:db * l:db)
		if l:dgrey < l:drgb
			" use the grey
			return <SID>grey_color(l:gx)
		else
			" use the color
			return <SID>rgb_color(l:x, l:y, l:z)
		endif
	else
		" only one possibility
		return <SID>rgb_color(l:x, l:y, l:z)
	endif
endfun

" returns the palette index to approximate the 'rrggbb' hex string
fun <SID>rgb(rgb)
	let l:r = ("0x" . strpart(a:rgb, 0, 2)) + 0
	let l:g = ("0x" . strpart(a:rgb, 2, 2)) + 0
	let l:b = ("0x" . strpart(a:rgb, 4, 2)) + 0
	return <SID>color(l:r, l:g, l:b)
endfun

" sets the highlighting for the given group
fun <SID>X(group, fg, bg, attr)
	if a:fg != ""
		exec "hi ".a:group." guifg=#".a:fg." ctermfg=".<SID>rgb(a:fg)
	endif
	if a:bg != ""
		exec "hi ".a:group." guibg=#".a:bg." ctermbg=".<SID>rgb(a:bg)
	endif
	if a:attr != ""
		if a:attr == 'italic'
			exec "hi ".a:group." gui=".a:attr." cterm=none"
		else
			exec "hi ".a:group." gui=".a:attr." cterm=".a:attr
		endif
	endif
endfun
" }}}

  
hi link htmlTag                     xmlTag
hi link htmlTagName                 xmlTagName
hi link htmlEndTag                  xmlEndTag

call <SID>X("Normal",		"E6E1DC",	"242424",	"NONE")
call <SID>X("Cursor",		"222222",	"00ff00",	"NONE")
call <SID>X("CursorColumn",	"",			"ecee90",	"NONE")
call <SID>X("CursorLine",	"",			"333333",	"NONE")
call <SID>X("Comment",		"696969",	"",			"italic")
call <SID>X("Constant",		"6D9CBE",	"",			"NONE")
call <SID>X("Define",		"CC7833",	"",			"NONE")
call <SID>X("Error",		"FFC66D",	"990000",	"NONE")
call <SID>X("Folded",		"a0a8b0",	"46465d",	"none")
call <SID>X("Fuction",		"FFC66D",	"",			"NONE")
call <SID>X("Identifier",	"6D9CBE",	"",			"NONE")
call <SID>X("Include",		"CC7833",	"",			"NONE")
call <SID>X("PreCondit",	"CC7833",	"",			"NONE")
call <SID>X("Keyword",		"CC7833",	"",			"NONE")
call <SID>X("LineNr",		"2B2B2B",	"C0C0FF",	"NONE")
call <SID>X("Number",		"A5C261",	"",			"NONE")
call <SID>X("PreProc",		"E6E1DC",	"",			"NONE")
call <SID>X("Search",		"2b2b2b",	"",			"italic")
call <SID>X("Statement",	"CC7833",	"",			"NONE")
call <SID>X("StatusLine",	"ffffff",	"005d00",	"NONE")
call <SID>X("StatusLineNC",	"2B2B2B",	"C0C0FF",	"NONE")
call <SID>X("String",		"A5C261",	"",			"NONE")
call <SID>X("Title",		"FFFFFF",	"",			"NONE")
call <SID>X("Type",			"DA4939",	"",			"NONE")
call <SID>X("Visual",		"",			"5A647E",	"NONE")

call <SID>X("DiffAdd",		"E6E1DC",			"519F50",	"NONE")
call <SID>X("DiffDelete",	"E6E1DC" ,			"660000 ",	"NONE")
call <SID>X("Special",		"DA4939",			"",	"NONE")
call <SID>X("pythonBuiltin","6D9CBE",			"",	"NONE")
call <SID>X("rubyBlockParameter",		"FFFFFF",			"",	"NONE")
call <SID>X("rubyClass",		"FFFFFF",			"",	"NONE")
call <SID>X("rubyConstant",		"DA4939",			"",	"NONE")
call <SID>X("rubyInstanceVariable",		"D0D0FF",			"",	"NONE")
call <SID>X("rubyInterpolation",		"519F50",			"",	"NONE")
call <SID>X("rubyLocalVariableOrMethod","D0D0FF",			"",	"NONE")
call <SID>X("rubyPredefinedConstant",		"DA4939",			"",	"NONE")
call <SID>X("rubyPseudoVariable",		"FFC66D",			"",	"NONE")
call <SID>X("rubyStringDelimiter",		"A5C261",			"",	"NONE")

call <SID>X("xmlTag",		"E8BF6A",			"",	"NONE")
call <SID>X("xmlTagName",		"E8BF6A",			"",	"NONE")
call <SID>X("xmlEndTag",		"E8BF6A",			"",	"NONE")

call <SID>X("mailSubject",		"A5C261",			"",	"NONE")
call <SID>X("mailHeaderKey",		"FFC66D",			"",	"NONE")
call <SID>X("mailEmail",		"A5C261",			"",	"italic")

call <SID>X("SpellBad",		"D70000",			"",	"NONE")
call <SID>X("SpellRare",		"D75F87",			"",	"underline")
call <SID>X("SpellCap",		"D0D0FF",			"",	"underline")
call <SID>X("MatchParen",		"FFFFFF",			"005f5f",	"NONE")

" delete functions {{{
delf <SID>X
delf <SID>rgb
delf <SID>color
delf <SID>rgb_color
delf <SID>rgb_level
delf <SID>rgb_number
delf <SID>grey_color
delf <SID>grey_level
delf <SID>grey_number
" }}}

" Color changes for the status bar when in insert mode
if has("autocmd")
  if has("gui_running")
    silent! au InsertEnter * hi StatusLine guibg=red  
    silent! au InsertLeave * hi StatusLine guibg=#005d00
  else
    silent! au InsertEnter * hi StatusLine ctermfg=7 ctermbg=1 
    silent! au InsertLeave * hi StatusLine ctermfg=0 ctermbg=2
  endif
endif
			"CursorIM
			"Question
			"IncSearch
" call <SID>X("Search",		"444444",	"af87d7",	"")
" call <SID>X("MatchParen",	"ecee90",	"857b6f",	"bold")
" call <SID>X("SpecialKey",	"6c6c6c",	"2d2d2d",	"none")
" call <SID>X("Visual",		"ecee90",	"597418",	"none")
" call <SID>X("LineNr",		"660066",	"none",	"none")
" call <SID>X("Title",		"f6f3e8",	"",			"bold")
" call <SID>X("VertSplit",	"000000",	"000000",	"none")
			"Scrollbar
			"Tooltip
			"Menu
			"WildMenu
" call <SID>X("Pmenu",		"f6f3e8",	"444444",	"")
" call <SID>X("PmenuSel",		"121212",	"caeb82",	"")
" call <SID>X("WarningMsg",	"ff0000",	"",			"")
			"ErrorMsg
			"ModeMsg
			"MoreMsg
			"Directory
			"DiffAdd
			"DiffChang
			"DiffDelete
			"DiffText

" syntax highlighting
" call <SID>X("Number",		"e5786d",	"",			"none")
" call <SID>X("Constant",		"e5786d",	"",			"none")
" call <SID>X("String",		"78a57c",	"",			"italic")
" call <SID>X("Identifier",	"caeb82",	"",			"none")
" call <SID>X("Keyword",		"87afff",	"",			"none")
" call <SID>X("Statement",	"87afff",	"",			"none")
" call <SID>X("Function",		"caeb82",	"",			"none")
" call <SID>X("PreProc",		"e5786d",	"",			"none")
" call <SID>X("Type",			"caeb82",	"",			"none")
" call <SID>X("Special",		"ffdead",	"",			"none")
" call <SID>X("Todo",			"857b6f",	"",			"italic")
			"Underlined
			"Error
			"Ignore

" hi! link VisualNOS	Visual
" hi! link NonText	LineNr
" hi! link FoldColumn	Folded


" vim:set ts=4 sw=4 noet fdm=marker:
