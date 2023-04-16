" Taken from https://github.com/juvenn/mustache.vim/blob/master/ftplugin/mustache.vim

set tabstop=2                    " Global tab width.
set shiftwidth=2                 " And again, related.
set expandtab

if exists("loaded_matchit")
  let b:match_ignorecase = 0

  let b:match_words = '{:},[:],(:),'
	\ . '\%({{\)\@<=[#^]\s*\([-0-9a-zA-Z_?!/.]\+\)\s*}}'
	\ . ':'
	\ . '\%({{\)\@<=/\s*\1\s*}}'
endif
