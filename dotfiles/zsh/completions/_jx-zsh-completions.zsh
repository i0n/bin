#compdef jx

__jx_bash_source() {
	alias shopt=':'
	alias _expand=_bash_expand
	alias _complete=_bash_comp
	emulate -L sh
	setopt kshglob noshglob braceexpand
	source "$@"
}
__jx_type() {
	# -t is not supported by zsh
	if [ "$1" == "-t" ]; then
		shift
		# fake Bash 4 to disable "complete -o nospace". Instead
		# "compopt +-o nospace" is used in the code to toggle trailing
		# spaces. We don't support that, but leave trailing spaces on
		# all the time
		if [ "$1" = "__jx_compopt" ]; then
			echo builtin
			return 0
		fi
	fi
	type "$@"
}
__jx_compgen() {
	local completions w
	completions=( $(compgen "$@") ) || return $?
	# filter by given word as prefix
	while [[ "$1" = -* && "$1" != -- ]]; do
		shift
		shift
	done
	if [[ "$1" == -- ]]; then
		shift
	fi
	for w in "${completions[@]}"; do
		if [[ "${w}" = "$1"* ]]; then
			echo "${w}"
		fi
	done
}
__jx_compopt() {
	true # don't do anything. Not supported by bashcompinit in zsh
}
__jx_ltrim_colon_completions()
{
	if [[ "$1" == *:* && "$COMP_WORDBREAKS" == *:* ]]; then
		# Remove colon-word prefix from COMPREPLY items
		local colon_word=${1%${1##*:}}
		local i=${#COMPREPLY[*]}
		while [[ $((--i)) -ge 0 ]]; do
			COMPREPLY[$i]=${COMPREPLY[$i]#"$colon_word"}
		done
	fi
}
__jx_get_comp_words_by_ref() {
	cur="${COMP_WORDS[COMP_CWORD]}"
	prev="${COMP_WORDS[${COMP_CWORD}-1]}"
	words=("${COMP_WORDS[@]}")
	cword=("${COMP_CWORD[@]}")
}
__jx_filedir() {
	local RET OLD_IFS w qw
	__jx_debug "_filedir $@ cur=$cur"
	if [[ "$1" = \~* ]]; then
		# somehow does not work. Maybe, zsh does not call this at all
		eval echo "$1"
		return 0
	fi
	OLD_IFS="$IFS"
	IFS=$'\n'
	if [ "$1" = "-d" ]; then
		shift
		RET=( $(compgen -d) )
	else
		RET=( $(compgen -f) )
	fi
	IFS="$OLD_IFS"
	IFS="," __jx_debug "RET=${RET[@]} len=${#RET[@]}"
	for w in ${RET[@]}; do
		if [[ ! "${w}" = "${cur}"* ]]; then
			continue
		fi
		if eval "[[ \"\${w}\" = *.$1 || -d \"\${w}\" ]]"; then
			qw="$(__jx_quote "${w}")"
			if [ -d "${w}" ]; then
				COMPREPLY+=("${qw}/")
			else
				COMPREPLY+=("${qw}")
			fi
		fi
	done
}
__jx_quote() {
    if [[ $1 == \'* || $1 == \"* ]]; then
        # Leave out first character
        printf %q "${1:1}"
    else
    	printf %q "$1"
    fi
}
autoload -U +X bashcompinit && bashcompinit
# use word boundary patterns for BSD or GNU sed
LWORD='[[:<:]]'
RWORD='[[:>:]]'
if sed --help 2>&1 | grep -q GNU; then
	LWORD='\<'
	RWORD='\>'
fi
__jx_convert_bash_to_zsh() {
	sed \
	-e 's/declare -F/whence -w/' \
	-e 's/_get_comp_words_by_ref "\$@"/_get_comp_words_by_ref "\$*"/' \
	-e 's/local \([a-zA-Z0-9_]*\)=/local \1; \1=/' \
	-e 's/flags+=("\(--.*\)=")/flags+=("\1"); two_word_flags+=("\1")/' \
	-e 's/must_have_one_flag+=("\(--.*\)=")/must_have_one_flag+=("\1")/' \
	-e "s/${LWORD}_filedir${RWORD}/__jx_filedir/g" \
	-e "s/${LWORD}_get_comp_words_by_ref${RWORD}/__jx_get_comp_words_by_ref/g" \
	-e "s/${LWORD}__ltrim_colon_completions${RWORD}/__jx_ltrim_colon_completions/g" \
	-e "s/${LWORD}compgen${RWORD}/__jx_compgen/g" \
	-e "s/${LWORD}compopt${RWORD}/__jx_compopt/g" \
	-e "s/${LWORD}declare${RWORD}/builtin declare/g" \
	-e "s/\\\$(type${RWORD}/\$(__jx_type/g" \
	<<'BASH_COMPLETION_EOF'
# bash completion for jx                                   -*- shell-script -*-

__jx_debug()
{
    if [[ -n ${BASH_COMP_DEBUG_FILE} ]]; then
        echo "$*" >> "${BASH_COMP_DEBUG_FILE}"
    fi
}

# Homebrew on Macs have version 1.3 of bash-completion which doesn't include
# _init_completion. This is a very minimal version of that function.
__jx_init_completion()
{
    COMPREPLY=()
    _get_comp_words_by_ref "$@" cur prev words cword
}

__jx_index_of_word()
{
    local w word=$1
    shift
    index=0
    for w in "$@"; do
        [[ $w = "$word" ]] && return
        index=$((index+1))
    done
    index=-1
}

__jx_contains_word()
{
    local w word=$1; shift
    for w in "$@"; do
        [[ $w = "$word" ]] && return
    done
    return 1
}

__jx_handle_reply()
{
    __jx_debug "${FUNCNAME[0]}"
    case $cur in
        -*)
            if [[ $(type -t compopt) = "builtin" ]]; then
                compopt -o nospace
            fi
            local allflags
            if [ ${#must_have_one_flag[@]} -ne 0 ]; then
                allflags=("${must_have_one_flag[@]}")
            else
                allflags=("${flags[*]} ${two_word_flags[*]}")
            fi
            COMPREPLY=( $(compgen -W "${allflags[*]}" -- "$cur") )
            if [[ $(type -t compopt) = "builtin" ]]; then
                [[ "${COMPREPLY[0]}" == *= ]] || compopt +o nospace
            fi

            # complete after --flag=abc
            if [[ $cur == *=* ]]; then
                if [[ $(type -t compopt) = "builtin" ]]; then
                    compopt +o nospace
                fi

                local index flag
                flag="${cur%=*}"
                __jx_index_of_word "${flag}" "${flags_with_completion[@]}"
                COMPREPLY=()
                if [[ ${index} -ge 0 ]]; then
                    PREFIX=""
                    cur="${cur#*=}"
                    ${flags_completion[${index}]}
                    if [ -n "${ZSH_VERSION}" ]; then
                        # zsh completion needs --flag= prefix
                        eval "COMPREPLY=( \"\${COMPREPLY[@]/#/${flag}=}\" )"
                    fi
                fi
            fi
            return 0;
            ;;
    esac

    # check if we are handling a flag with special work handling
    local index
    __jx_index_of_word "${prev}" "${flags_with_completion[@]}"
    if [[ ${index} -ge 0 ]]; then
        ${flags_completion[${index}]}
        return
    fi

    # we are parsing a flag and don't have a special handler, no completion
    if [[ ${cur} != "${words[cword]}" ]]; then
        return
    fi

    local completions
    completions=("${commands[@]}")
    if [[ ${#must_have_one_noun[@]} -ne 0 ]]; then
        completions=("${must_have_one_noun[@]}")
    fi
    if [[ ${#must_have_one_flag[@]} -ne 0 ]]; then
        completions+=("${must_have_one_flag[@]}")
    fi
    COMPREPLY=( $(compgen -W "${completions[*]}" -- "$cur") )

    if [[ ${#COMPREPLY[@]} -eq 0 && ${#noun_aliases[@]} -gt 0 && ${#must_have_one_noun[@]} -ne 0 ]]; then
        COMPREPLY=( $(compgen -W "${noun_aliases[*]}" -- "$cur") )
    fi

    if [[ ${#COMPREPLY[@]} -eq 0 ]]; then
        declare -F __custom_func >/dev/null && __custom_func
    fi

    # available in bash-completion >= 2, not always present on macOS
    if declare -F __ltrim_colon_completions >/dev/null; then
        __ltrim_colon_completions "$cur"
    fi

    # If there is only 1 completion and it is a flag with an = it will be completed
    # but we don't want a space after the =
    if [[ "${#COMPREPLY[@]}" -eq "1" ]] && [[ $(type -t compopt) = "builtin" ]] && [[ "${COMPREPLY[0]}" == --*= ]]; then
       compopt -o nospace
    fi
}

# The arguments should be in the form "ext1|ext2|extn"
__jx_handle_filename_extension_flag()
{
    local ext="$1"
    _filedir "@(${ext})"
}

__jx_handle_subdirs_in_dir_flag()
{
    local dir="$1"
    pushd "${dir}" >/dev/null 2>&1 && _filedir -d && popd >/dev/null 2>&1
}

__jx_handle_flag()
{
    __jx_debug "${FUNCNAME[0]}: c is $c words[c] is ${words[c]}"

    # if a command required a flag, and we found it, unset must_have_one_flag()
    local flagname=${words[c]}
    local flagvalue
    # if the word contained an =
    if [[ ${words[c]} == *"="* ]]; then
        flagvalue=${flagname#*=} # take in as flagvalue after the =
        flagname=${flagname%=*} # strip everything after the =
        flagname="${flagname}=" # but put the = back
    fi
    __jx_debug "${FUNCNAME[0]}: looking for ${flagname}"
    if __jx_contains_word "${flagname}" "${must_have_one_flag[@]}"; then
        must_have_one_flag=()
    fi

    # if you set a flag which only applies to this command, don't show subcommands
    if __jx_contains_word "${flagname}" "${local_nonpersistent_flags[@]}"; then
      commands=()
    fi

    # keep flag value with flagname as flaghash
    # flaghash variable is an associative array which is only supported in bash > 3.
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        if [ -n "${flagvalue}" ] ; then
            flaghash[${flagname}]=${flagvalue}
        elif [ -n "${words[ $((c+1)) ]}" ] ; then
            flaghash[${flagname}]=${words[ $((c+1)) ]}
        else
            flaghash[${flagname}]="true" # pad "true" for bool flag
        fi
    fi

    # skip the argument to a two word flag
    if __jx_contains_word "${words[c]}" "${two_word_flags[@]}"; then
        c=$((c+1))
        # if we are looking for a flags value, don't show commands
        if [[ $c -eq $cword ]]; then
            commands=()
        fi
    fi

    c=$((c+1))

}

__jx_handle_noun()
{
    __jx_debug "${FUNCNAME[0]}: c is $c words[c] is ${words[c]}"

    if __jx_contains_word "${words[c]}" "${must_have_one_noun[@]}"; then
        must_have_one_noun=()
    elif __jx_contains_word "${words[c]}" "${noun_aliases[@]}"; then
        must_have_one_noun=()
    fi

    nouns+=("${words[c]}")
    c=$((c+1))
}

__jx_handle_command()
{
    __jx_debug "${FUNCNAME[0]}: c is $c words[c] is ${words[c]}"

    local next_command
    if [[ -n ${last_command} ]]; then
        next_command="_${last_command}_${words[c]//:/__}"
    else
        if [[ $c -eq 0 ]]; then
            next_command="_jx_root_command"
        else
            next_command="_${words[c]//:/__}"
        fi
    fi
    c=$((c+1))
    __jx_debug "${FUNCNAME[0]}: looking for ${next_command}"
    declare -F "$next_command" >/dev/null && $next_command
}

__jx_handle_word()
{
    if [[ $c -ge $cword ]]; then
        __jx_handle_reply
        return
    fi
    __jx_debug "${FUNCNAME[0]}: c is $c words[c] is ${words[c]}"
    if [[ "${words[c]}" == -* ]]; then
        __jx_handle_flag
    elif __jx_contains_word "${words[c]}" "${commands[@]}"; then
        __jx_handle_command
    elif [[ $c -eq 0 ]]; then
        __jx_handle_command
    elif __jx_contains_word "${words[c]}" "${command_aliases[@]}"; then
        # aliashash variable is an associative array which is only supported in bash > 3.
        if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
            words[c]=${aliashash[${words[c]}]}
            __jx_handle_command
        else
            __jx_handle_noun
        fi
    else
        __jx_handle_noun
    fi
    __jx_handle_word
}

_jx_cloudbees()
{
    last_command="jx_cloudbees"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--url")
    flags+=("-u")
    local_nonpersistent_flags+=("--url")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_completion()
{
    last_command="jx_completion"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--help")
    flags+=("-h")
    local_nonpersistent_flags+=("--help")

    must_have_one_flag=()
    must_have_one_noun=()
    must_have_one_noun+=("bash")
    must_have_one_noun+=("zsh")
    noun_aliases=()
}

_jx_compliance_delete()
{
    last_command="jx_compliance_delete"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()


    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_compliance_logs()
{
    last_command="jx_compliance_logs"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--follow")
    flags+=("-f")
    local_nonpersistent_flags+=("--follow")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_compliance_results()
{
    last_command="jx_compliance_results"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()


    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_compliance_run()
{
    last_command="jx_compliance_run"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()


    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_compliance_status()
{
    last_command="jx_compliance_status"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()


    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_compliance()
{
    last_command="jx_compliance"

    command_aliases=()

    commands=()
    commands+=("delete")
    commands+=("logs")
    commands+=("results")
    commands+=("run")
    commands+=("status")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()


    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_console()
{
    last_command="jx_console"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--classic")
    local_nonpersistent_flags+=("--classic")
    flags+=("--env=")
    two_word_flags+=("-e")
    local_nonpersistent_flags+=("--env=")
    flags+=("--namespace=")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--namespace=")
    flags+=("--url")
    flags+=("-u")
    local_nonpersistent_flags+=("--url")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_context()
{
    last_command="jx_context"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--batch-mode")
    flags+=("-b")
    local_nonpersistent_flags+=("--batch-mode")
    flags+=("--headless")
    local_nonpersistent_flags+=("--headless")
    flags+=("--install-dependencies")
    local_nonpersistent_flags+=("--install-dependencies")
    flags+=("--no-brew")
    local_nonpersistent_flags+=("--no-brew")
    flags+=("--verbose")
    local_nonpersistent_flags+=("--verbose")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_controller_build()
{
    last_command="jx_controller_build"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--namespace=")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--namespace=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_controller()
{
    last_command="jx_controller"

    command_aliases=()

    commands=()
    commands+=("build")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("builds")
        aliashash["builds"]="build"
    fi

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()


    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_create_addon_ambassador()
{
    last_command="jx_create_addon_ambassador"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--batch-mode")
    flags+=("-b")
    local_nonpersistent_flags+=("--batch-mode")
    flags+=("--chart=")
    two_word_flags+=("-c")
    local_nonpersistent_flags+=("--chart=")
    flags+=("--headless")
    local_nonpersistent_flags+=("--headless")
    flags+=("--helm-update")
    local_nonpersistent_flags+=("--helm-update")
    flags+=("--install-dependencies")
    local_nonpersistent_flags+=("--install-dependencies")
    flags+=("--namespace=")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--namespace=")
    flags+=("--no-brew")
    local_nonpersistent_flags+=("--no-brew")
    flags+=("--release=")
    two_word_flags+=("-r")
    local_nonpersistent_flags+=("--release=")
    flags+=("--set=")
    two_word_flags+=("-s")
    local_nonpersistent_flags+=("--set=")
    flags+=("--verbose")
    local_nonpersistent_flags+=("--verbose")
    flags+=("--version=")
    two_word_flags+=("-v")
    local_nonpersistent_flags+=("--version=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_create_addon_anchore()
{
    last_command="jx_create_addon_anchore"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--batch-mode")
    flags+=("-b")
    local_nonpersistent_flags+=("--batch-mode")
    flags+=("--chart=")
    two_word_flags+=("-c")
    local_nonpersistent_flags+=("--chart=")
    flags+=("--config-dir=")
    two_word_flags+=("-d")
    local_nonpersistent_flags+=("--config-dir=")
    flags+=("--headless")
    local_nonpersistent_flags+=("--headless")
    flags+=("--helm-update")
    local_nonpersistent_flags+=("--helm-update")
    flags+=("--install-dependencies")
    local_nonpersistent_flags+=("--install-dependencies")
    flags+=("--namespace=")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--namespace=")
    flags+=("--no-brew")
    local_nonpersistent_flags+=("--no-brew")
    flags+=("--password=")
    two_word_flags+=("-p")
    local_nonpersistent_flags+=("--password=")
    flags+=("--release=")
    two_word_flags+=("-r")
    local_nonpersistent_flags+=("--release=")
    flags+=("--set=")
    two_word_flags+=("-s")
    local_nonpersistent_flags+=("--set=")
    flags+=("--verbose")
    local_nonpersistent_flags+=("--verbose")
    flags+=("--version=")
    two_word_flags+=("-v")
    local_nonpersistent_flags+=("--version=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_create_addon_cloudbees()
{
    last_command="jx_create_addon_cloudbees"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--batch-mode")
    flags+=("-b")
    local_nonpersistent_flags+=("--batch-mode")
    flags+=("--headless")
    local_nonpersistent_flags+=("--headless")
    flags+=("--helm-update")
    local_nonpersistent_flags+=("--helm-update")
    flags+=("--install-dependencies")
    local_nonpersistent_flags+=("--install-dependencies")
    flags+=("--namespace=")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--namespace=")
    flags+=("--no-brew")
    local_nonpersistent_flags+=("--no-brew")
    flags+=("--release=")
    two_word_flags+=("-r")
    local_nonpersistent_flags+=("--release=")
    flags+=("--set=")
    two_word_flags+=("-s")
    local_nonpersistent_flags+=("--set=")
    flags+=("--verbose")
    local_nonpersistent_flags+=("--verbose")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_create_addon_gitea()
{
    last_command="jx_create_addon_gitea"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--admin")
    local_nonpersistent_flags+=("--admin")
    flags+=("--batch-mode")
    flags+=("-b")
    local_nonpersistent_flags+=("--batch-mode")
    flags+=("--chart=")
    two_word_flags+=("-c")
    local_nonpersistent_flags+=("--chart=")
    flags+=("--email=")
    two_word_flags+=("-e")
    local_nonpersistent_flags+=("--email=")
    flags+=("--headless")
    local_nonpersistent_flags+=("--headless")
    flags+=("--helm-update")
    local_nonpersistent_flags+=("--helm-update")
    flags+=("--install-dependencies")
    local_nonpersistent_flags+=("--install-dependencies")
    flags+=("--namespace=")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--namespace=")
    flags+=("--no-brew")
    local_nonpersistent_flags+=("--no-brew")
    flags+=("--no-token")
    local_nonpersistent_flags+=("--no-token")
    flags+=("--no-user")
    local_nonpersistent_flags+=("--no-user")
    flags+=("--password=")
    two_word_flags+=("-p")
    local_nonpersistent_flags+=("--password=")
    flags+=("--release=")
    two_word_flags+=("-r")
    local_nonpersistent_flags+=("--release=")
    flags+=("--set=")
    two_word_flags+=("-s")
    local_nonpersistent_flags+=("--set=")
    flags+=("--username=")
    two_word_flags+=("-u")
    local_nonpersistent_flags+=("--username=")
    flags+=("--verbose")
    local_nonpersistent_flags+=("--verbose")
    flags+=("--version=")
    two_word_flags+=("-v")
    local_nonpersistent_flags+=("--version=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_create_addon_istio()
{
    last_command="jx_create_addon_istio"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--batch-mode")
    flags+=("-b")
    local_nonpersistent_flags+=("--batch-mode")
    flags+=("--chart=")
    two_word_flags+=("-c")
    local_nonpersistent_flags+=("--chart=")
    flags+=("--config-dir=")
    two_word_flags+=("-d")
    local_nonpersistent_flags+=("--config-dir=")
    flags+=("--headless")
    local_nonpersistent_flags+=("--headless")
    flags+=("--helm-update")
    local_nonpersistent_flags+=("--helm-update")
    flags+=("--install-dependencies")
    local_nonpersistent_flags+=("--install-dependencies")
    flags+=("--namespace=")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--namespace=")
    flags+=("--no-brew")
    local_nonpersistent_flags+=("--no-brew")
    flags+=("--no-injector-webhook")
    local_nonpersistent_flags+=("--no-injector-webhook")
    flags+=("--password=")
    two_word_flags+=("-p")
    local_nonpersistent_flags+=("--password=")
    flags+=("--release=")
    two_word_flags+=("-r")
    local_nonpersistent_flags+=("--release=")
    flags+=("--set=")
    two_word_flags+=("-s")
    local_nonpersistent_flags+=("--set=")
    flags+=("--verbose")
    local_nonpersistent_flags+=("--verbose")
    flags+=("--version=")
    two_word_flags+=("-v")
    local_nonpersistent_flags+=("--version=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_create_addon_kubeless()
{
    last_command="jx_create_addon_kubeless"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--batch-mode")
    flags+=("-b")
    local_nonpersistent_flags+=("--batch-mode")
    flags+=("--chart=")
    two_word_flags+=("-c")
    local_nonpersistent_flags+=("--chart=")
    flags+=("--headless")
    local_nonpersistent_flags+=("--headless")
    flags+=("--helm-update")
    local_nonpersistent_flags+=("--helm-update")
    flags+=("--install-dependencies")
    local_nonpersistent_flags+=("--install-dependencies")
    flags+=("--namespace=")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--namespace=")
    flags+=("--no-brew")
    local_nonpersistent_flags+=("--no-brew")
    flags+=("--release=")
    two_word_flags+=("-r")
    local_nonpersistent_flags+=("--release=")
    flags+=("--set=")
    two_word_flags+=("-s")
    local_nonpersistent_flags+=("--set=")
    flags+=("--verbose")
    local_nonpersistent_flags+=("--verbose")
    flags+=("--version=")
    two_word_flags+=("-v")
    local_nonpersistent_flags+=("--version=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_create_addon_owasp-zap()
{
    last_command="jx_create_addon_owasp-zap"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--backoff-limit=")
    two_word_flags+=("-l")
    local_nonpersistent_flags+=("--backoff-limit=")
    flags+=("--image=")
    two_word_flags+=("-i")
    local_nonpersistent_flags+=("--image=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_create_addon_pipeline-events()
{
    last_command="jx_create_addon_pipeline-events"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--batch-mode")
    flags+=("-b")
    local_nonpersistent_flags+=("--batch-mode")
    flags+=("--headless")
    local_nonpersistent_flags+=("--headless")
    flags+=("--helm-update")
    local_nonpersistent_flags+=("--helm-update")
    flags+=("--install-dependencies")
    local_nonpersistent_flags+=("--install-dependencies")
    flags+=("--namespace=")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--namespace=")
    flags+=("--no-brew")
    local_nonpersistent_flags+=("--no-brew")
    flags+=("--password=")
    two_word_flags+=("-p")
    local_nonpersistent_flags+=("--password=")
    flags+=("--release=")
    two_word_flags+=("-r")
    local_nonpersistent_flags+=("--release=")
    flags+=("--set=")
    two_word_flags+=("-s")
    local_nonpersistent_flags+=("--set=")
    flags+=("--verbose")
    local_nonpersistent_flags+=("--verbose")
    flags+=("--version=")
    two_word_flags+=("-v")
    local_nonpersistent_flags+=("--version=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_create_addon_prow()
{
    last_command="jx_create_addon_prow"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--batch-mode")
    flags+=("-b")
    local_nonpersistent_flags+=("--batch-mode")
    flags+=("--chart=")
    two_word_flags+=("-c")
    local_nonpersistent_flags+=("--chart=")
    flags+=("--headless")
    local_nonpersistent_flags+=("--headless")
    flags+=("--helm-update")
    local_nonpersistent_flags+=("--helm-update")
    flags+=("--hmac-token=")
    local_nonpersistent_flags+=("--hmac-token=")
    flags+=("--install-dependencies")
    local_nonpersistent_flags+=("--install-dependencies")
    flags+=("--namespace=")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--namespace=")
    flags+=("--no-brew")
    local_nonpersistent_flags+=("--no-brew")
    flags+=("--oauth-token=")
    local_nonpersistent_flags+=("--oauth-token=")
    flags+=("--password=")
    local_nonpersistent_flags+=("--password=")
    flags+=("--release=")
    two_word_flags+=("-r")
    local_nonpersistent_flags+=("--release=")
    flags+=("--set=")
    two_word_flags+=("-s")
    local_nonpersistent_flags+=("--set=")
    flags+=("--verbose")
    local_nonpersistent_flags+=("--verbose")
    flags+=("--version=")
    two_word_flags+=("-v")
    local_nonpersistent_flags+=("--version=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_create_addon()
{
    last_command="jx_create_addon"

    command_aliases=()

    commands=()
    commands+=("ambassador")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("env")
        aliashash["env"]="ambassador"
    fi
    commands+=("anchore")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("env")
        aliashash["env"]="anchore"
    fi
    commands+=("cloudbees")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("cb")
        aliashash["cb"]="cloudbees"
        command_aliases+=("cdx")
        aliashash["cdx"]="cloudbees"
        command_aliases+=("cloudbee")
        aliashash["cloudbee"]="cloudbees"
        command_aliases+=("kubecd")
        aliashash["kubecd"]="cloudbees"
    fi
    commands+=("gitea")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("env")
        aliashash["env"]="gitea"
    fi
    commands+=("istio")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("env")
        aliashash["env"]="istio"
    fi
    commands+=("kubeless")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("env")
        aliashash["env"]="kubeless"
    fi
    commands+=("owasp-zap")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("env")
        aliashash["env"]="owasp-zap"
    fi
    commands+=("pipeline-events")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("pe")
        aliashash["pe"]="pipeline-events"
    fi
    commands+=("prow")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--helm-update")
    local_nonpersistent_flags+=("--helm-update")
    flags+=("--namespace=")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--namespace=")
    flags+=("--release=")
    two_word_flags+=("-r")
    local_nonpersistent_flags+=("--release=")
    flags+=("--set=")
    two_word_flags+=("-s")
    local_nonpersistent_flags+=("--set=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_create_archetype()
{
    last_command="jx_create_archetype"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--artifact=")
    two_word_flags+=("-a")
    local_nonpersistent_flags+=("--artifact=")
    flags+=("--batch-mode")
    flags+=("-b")
    local_nonpersistent_flags+=("--batch-mode")
    flags+=("--branches=")
    local_nonpersistent_flags+=("--branches=")
    flags+=("--catalog=")
    two_word_flags+=("-c")
    local_nonpersistent_flags+=("--catalog=")
    flags+=("--credentials=")
    local_nonpersistent_flags+=("--credentials=")
    flags+=("--default-owner=")
    local_nonpersistent_flags+=("--default-owner=")
    flags+=("--dry-run")
    local_nonpersistent_flags+=("--dry-run")
    flags+=("--filter-artifact=")
    local_nonpersistent_flags+=("--filter-artifact=")
    flags+=("--filter-group=")
    two_word_flags+=("-f")
    local_nonpersistent_flags+=("--filter-group=")
    flags+=("--filter-version=")
    local_nonpersistent_flags+=("--filter-version=")
    flags+=("--git-api-token=")
    local_nonpersistent_flags+=("--git-api-token=")
    flags+=("--git-provider-url=")
    local_nonpersistent_flags+=("--git-provider-url=")
    flags+=("--git-username=")
    local_nonpersistent_flags+=("--git-username=")
    flags+=("--group=")
    two_word_flags+=("-g")
    local_nonpersistent_flags+=("--group=")
    flags+=("--group-ids=")
    local_nonpersistent_flags+=("--group-ids=")
    flags+=("--headless")
    local_nonpersistent_flags+=("--headless")
    flags+=("--import-commit-message=")
    local_nonpersistent_flags+=("--import-commit-message=")
    flags+=("--install-dependencies")
    local_nonpersistent_flags+=("--install-dependencies")
    flags+=("--interactive")
    flags+=("-i")
    local_nonpersistent_flags+=("--interactive")
    flags+=("--jenkinsfile=")
    local_nonpersistent_flags+=("--jenkinsfile=")
    flags+=("--list-packs")
    local_nonpersistent_flags+=("--list-packs")
    flags+=("--name=")
    local_nonpersistent_flags+=("--name=")
    flags+=("--no-brew")
    local_nonpersistent_flags+=("--no-brew")
    flags+=("--no-draft")
    local_nonpersistent_flags+=("--no-draft")
    flags+=("--no-import")
    local_nonpersistent_flags+=("--no-import")
    flags+=("--no-jenkinsfile")
    local_nonpersistent_flags+=("--no-jenkinsfile")
    flags+=("--org=")
    local_nonpersistent_flags+=("--org=")
    flags+=("--output-dir=")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--output-dir=")
    flags+=("--pack=")
    local_nonpersistent_flags+=("--pack=")
    flags+=("--pick")
    flags+=("-p")
    local_nonpersistent_flags+=("--pick")
    flags+=("--verbose")
    local_nonpersistent_flags+=("--verbose")
    flags+=("--version=")
    two_word_flags+=("-v")
    local_nonpersistent_flags+=("--version=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_create_branchpattern()
{
    last_command="jx_create_branchpattern"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--batch-mode")
    flags+=("-b")
    local_nonpersistent_flags+=("--batch-mode")
    flags+=("--headless")
    local_nonpersistent_flags+=("--headless")
    flags+=("--install-dependencies")
    local_nonpersistent_flags+=("--install-dependencies")
    flags+=("--no-brew")
    local_nonpersistent_flags+=("--no-brew")
    flags+=("--verbose")
    local_nonpersistent_flags+=("--verbose")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_create_camel()
{
    last_command="jx_create_camel"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--artifact=")
    two_word_flags+=("-a")
    local_nonpersistent_flags+=("--artifact=")
    flags+=("--batch-mode")
    flags+=("-b")
    local_nonpersistent_flags+=("--batch-mode")
    flags+=("--branches=")
    local_nonpersistent_flags+=("--branches=")
    flags+=("--camel-version=")
    two_word_flags+=("-c")
    local_nonpersistent_flags+=("--camel-version=")
    flags+=("--credentials=")
    local_nonpersistent_flags+=("--credentials=")
    flags+=("--default-owner=")
    local_nonpersistent_flags+=("--default-owner=")
    flags+=("--dry-run")
    local_nonpersistent_flags+=("--dry-run")
    flags+=("--git-api-token=")
    local_nonpersistent_flags+=("--git-api-token=")
    flags+=("--git-provider-url=")
    local_nonpersistent_flags+=("--git-provider-url=")
    flags+=("--git-username=")
    local_nonpersistent_flags+=("--git-username=")
    flags+=("--group=")
    two_word_flags+=("-g")
    local_nonpersistent_flags+=("--group=")
    flags+=("--headless")
    local_nonpersistent_flags+=("--headless")
    flags+=("--import-commit-message=")
    local_nonpersistent_flags+=("--import-commit-message=")
    flags+=("--install-dependencies")
    local_nonpersistent_flags+=("--install-dependencies")
    flags+=("--interactive")
    flags+=("-i")
    local_nonpersistent_flags+=("--interactive")
    flags+=("--jenkinsfile=")
    local_nonpersistent_flags+=("--jenkinsfile=")
    flags+=("--list-packs")
    local_nonpersistent_flags+=("--list-packs")
    flags+=("--name=")
    local_nonpersistent_flags+=("--name=")
    flags+=("--no-brew")
    local_nonpersistent_flags+=("--no-brew")
    flags+=("--no-draft")
    local_nonpersistent_flags+=("--no-draft")
    flags+=("--no-import")
    local_nonpersistent_flags+=("--no-import")
    flags+=("--no-jenkinsfile")
    local_nonpersistent_flags+=("--no-jenkinsfile")
    flags+=("--org=")
    local_nonpersistent_flags+=("--org=")
    flags+=("--output-dir=")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--output-dir=")
    flags+=("--pack=")
    local_nonpersistent_flags+=("--pack=")
    flags+=("--verbose")
    local_nonpersistent_flags+=("--verbose")
    flags+=("--version=")
    two_word_flags+=("-v")
    local_nonpersistent_flags+=("--version=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_create_chat_server()
{
    last_command="jx_create_chat_server"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--name=")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--name=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_create_chat_token()
{
    last_command="jx_create_chat_token"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--api-token=")
    two_word_flags+=("-t")
    local_nonpersistent_flags+=("--api-token=")
    flags+=("--batch-mode")
    flags+=("-b")
    local_nonpersistent_flags+=("--batch-mode")
    flags+=("--headless")
    local_nonpersistent_flags+=("--headless")
    flags+=("--install-dependencies")
    local_nonpersistent_flags+=("--install-dependencies")
    flags+=("--name=")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--name=")
    flags+=("--no-brew")
    local_nonpersistent_flags+=("--no-brew")
    flags+=("--timeout=")
    local_nonpersistent_flags+=("--timeout=")
    flags+=("--url=")
    two_word_flags+=("-u")
    local_nonpersistent_flags+=("--url=")
    flags+=("--verbose")
    local_nonpersistent_flags+=("--verbose")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_create_chat()
{
    last_command="jx_create_chat"

    command_aliases=()

    commands=()
    commands+=("server")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("provider")
        aliashash["provider"]="server"
    fi
    commands+=("token")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("login")
        aliashash["login"]="token"
    fi

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()


    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_create_cluster_aks()
{
    last_command="jx_create_cluster_aks"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--cleanup-temp-files")
    local_nonpersistent_flags+=("--cleanup-temp-files")
    flags+=("--cloud-environment-repo=")
    local_nonpersistent_flags+=("--cloud-environment-repo=")
    flags+=("--cluster-name=")
    two_word_flags+=("-c")
    local_nonpersistent_flags+=("--cluster-name=")
    flags+=("--default-admin-password=")
    local_nonpersistent_flags+=("--default-admin-password=")
    flags+=("--default-environment-prefix=")
    local_nonpersistent_flags+=("--default-environment-prefix=")
    flags+=("--disk-size=")
    local_nonpersistent_flags+=("--disk-size=")
    flags+=("--docker-registry=")
    local_nonpersistent_flags+=("--docker-registry=")
    flags+=("--domain=")
    local_nonpersistent_flags+=("--domain=")
    flags+=("--draft-client-only")
    local_nonpersistent_flags+=("--draft-client-only")
    flags+=("--environment-git-owner=")
    local_nonpersistent_flags+=("--environment-git-owner=")
    flags+=("--exposecontroller-pathmode=")
    local_nonpersistent_flags+=("--exposecontroller-pathmode=")
    flags+=("--exposer=")
    local_nonpersistent_flags+=("--exposer=")
    flags+=("--external-ip=")
    local_nonpersistent_flags+=("--external-ip=")
    flags+=("--git-api-token=")
    local_nonpersistent_flags+=("--git-api-token=")
    flags+=("--git-provider-url=")
    local_nonpersistent_flags+=("--git-provider-url=")
    flags+=("--git-username=")
    local_nonpersistent_flags+=("--git-username=")
    flags+=("--global-tiller")
    local_nonpersistent_flags+=("--global-tiller")
    flags+=("--helm-client-only")
    local_nonpersistent_flags+=("--helm-client-only")
    flags+=("--helm-tls")
    local_nonpersistent_flags+=("--helm-tls")
    flags+=("--helm3")
    local_nonpersistent_flags+=("--helm3")
    flags+=("--http=")
    local_nonpersistent_flags+=("--http=")
    flags+=("--ingress-cluster-role=")
    local_nonpersistent_flags+=("--ingress-cluster-role=")
    flags+=("--ingress-deployment=")
    local_nonpersistent_flags+=("--ingress-deployment=")
    flags+=("--ingress-namespace=")
    local_nonpersistent_flags+=("--ingress-namespace=")
    flags+=("--ingress-service=")
    local_nonpersistent_flags+=("--ingress-service=")
    flags+=("--install-only")
    local_nonpersistent_flags+=("--install-only")
    flags+=("--keep-exposecontroller-job")
    local_nonpersistent_flags+=("--keep-exposecontroller-job")
    flags+=("--kubernetes-version=")
    two_word_flags+=("-v")
    local_nonpersistent_flags+=("--kubernetes-version=")
    flags+=("--local-cloud-environment")
    local_nonpersistent_flags+=("--local-cloud-environment")
    flags+=("--local-helm-repo-name=")
    local_nonpersistent_flags+=("--local-helm-repo-name=")
    flags+=("--location=")
    two_word_flags+=("-l")
    local_nonpersistent_flags+=("--location=")
    flags+=("--namespace=")
    local_nonpersistent_flags+=("--namespace=")
    flags+=("--no-default-environments")
    local_nonpersistent_flags+=("--no-default-environments")
    flags+=("--node-vm-size=")
    two_word_flags+=("-s")
    local_nonpersistent_flags+=("--node-vm-size=")
    flags+=("--nodes=")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--nodes=")
    flags+=("--on-premise")
    local_nonpersistent_flags+=("--on-premise")
    flags+=("--password=")
    two_word_flags+=("-p")
    local_nonpersistent_flags+=("--password=")
    flags+=("--path-To-public-rsa-key=")
    two_word_flags+=("-k")
    local_nonpersistent_flags+=("--path-To-public-rsa-key=")
    flags+=("--prow")
    local_nonpersistent_flags+=("--prow")
    flags+=("--recreate-existing-draft-repos")
    local_nonpersistent_flags+=("--recreate-existing-draft-repos")
    flags+=("--register-local-helmrepo")
    local_nonpersistent_flags+=("--register-local-helmrepo")
    flags+=("--resource-group-name=")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--resource-group-name=")
    flags+=("--skip-ingress")
    local_nonpersistent_flags+=("--skip-ingress")
    flags+=("--skip-login")
    local_nonpersistent_flags+=("--skip-login")
    flags+=("--skip-provider-registration")
    local_nonpersistent_flags+=("--skip-provider-registration")
    flags+=("--skip-resource-group-creation")
    local_nonpersistent_flags+=("--skip-resource-group-creation")
    flags+=("--skip-tiller")
    local_nonpersistent_flags+=("--skip-tiller")
    flags+=("--tags=")
    local_nonpersistent_flags+=("--tags=")
    flags+=("--tiller-cluster-role=")
    local_nonpersistent_flags+=("--tiller-cluster-role=")
    flags+=("--tiller-namespace=")
    local_nonpersistent_flags+=("--tiller-namespace=")
    flags+=("--timeout=")
    local_nonpersistent_flags+=("--timeout=")
    flags+=("--tls-acme=")
    local_nonpersistent_flags+=("--tls-acme=")
    flags+=("--user-cluster-role=")
    local_nonpersistent_flags+=("--user-cluster-role=")
    flags+=("--user-name=")
    two_word_flags+=("-u")
    local_nonpersistent_flags+=("--user-name=")
    flags+=("--username=")
    local_nonpersistent_flags+=("--username=")
    flags+=("--version=")
    local_nonpersistent_flags+=("--version=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_create_cluster_aws()
{
    last_command="jx_create_cluster_aws"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--batch-mode")
    flags+=("-b")
    local_nonpersistent_flags+=("--batch-mode")
    flags+=("--cleanup-temp-files")
    local_nonpersistent_flags+=("--cleanup-temp-files")
    flags+=("--cloud-environment-repo=")
    local_nonpersistent_flags+=("--cloud-environment-repo=")
    flags+=("--cluster-name=")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--cluster-name=")
    flags+=("--default-admin-password=")
    local_nonpersistent_flags+=("--default-admin-password=")
    flags+=("--default-environment-prefix=")
    local_nonpersistent_flags+=("--default-environment-prefix=")
    flags+=("--docker-registry=")
    local_nonpersistent_flags+=("--docker-registry=")
    flags+=("--domain=")
    local_nonpersistent_flags+=("--domain=")
    flags+=("--draft-client-only")
    local_nonpersistent_flags+=("--draft-client-only")
    flags+=("--environment-git-owner=")
    local_nonpersistent_flags+=("--environment-git-owner=")
    flags+=("--exposecontroller-pathmode=")
    local_nonpersistent_flags+=("--exposecontroller-pathmode=")
    flags+=("--exposer=")
    local_nonpersistent_flags+=("--exposer=")
    flags+=("--external-ip=")
    local_nonpersistent_flags+=("--external-ip=")
    flags+=("--git-api-token=")
    local_nonpersistent_flags+=("--git-api-token=")
    flags+=("--git-provider-url=")
    local_nonpersistent_flags+=("--git-provider-url=")
    flags+=("--git-username=")
    local_nonpersistent_flags+=("--git-username=")
    flags+=("--global-tiller")
    local_nonpersistent_flags+=("--global-tiller")
    flags+=("--headless")
    local_nonpersistent_flags+=("--headless")
    flags+=("--helm-client-only")
    local_nonpersistent_flags+=("--helm-client-only")
    flags+=("--helm-tls")
    local_nonpersistent_flags+=("--helm-tls")
    flags+=("--helm3")
    local_nonpersistent_flags+=("--helm3")
    flags+=("--http=")
    local_nonpersistent_flags+=("--http=")
    flags+=("--ingress-cluster-role=")
    local_nonpersistent_flags+=("--ingress-cluster-role=")
    flags+=("--ingress-deployment=")
    local_nonpersistent_flags+=("--ingress-deployment=")
    flags+=("--ingress-namespace=")
    local_nonpersistent_flags+=("--ingress-namespace=")
    flags+=("--ingress-service=")
    local_nonpersistent_flags+=("--ingress-service=")
    flags+=("--insecure-registry=")
    local_nonpersistent_flags+=("--insecure-registry=")
    flags+=("--install-dependencies")
    local_nonpersistent_flags+=("--install-dependencies")
    flags+=("--install-only")
    local_nonpersistent_flags+=("--install-only")
    flags+=("--keep-exposecontroller-job")
    local_nonpersistent_flags+=("--keep-exposecontroller-job")
    flags+=("--kubernetes-version=")
    two_word_flags+=("-v")
    local_nonpersistent_flags+=("--kubernetes-version=")
    flags+=("--local-cloud-environment")
    local_nonpersistent_flags+=("--local-cloud-environment")
    flags+=("--local-helm-repo-name=")
    local_nonpersistent_flags+=("--local-helm-repo-name=")
    flags+=("--master-size=")
    local_nonpersistent_flags+=("--master-size=")
    flags+=("--namespace=")
    local_nonpersistent_flags+=("--namespace=")
    flags+=("--no-brew")
    local_nonpersistent_flags+=("--no-brew")
    flags+=("--no-default-environments")
    local_nonpersistent_flags+=("--no-default-environments")
    flags+=("--node-size=")
    local_nonpersistent_flags+=("--node-size=")
    flags+=("--nodes=")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--nodes=")
    flags+=("--on-premise")
    local_nonpersistent_flags+=("--on-premise")
    flags+=("--prow")
    local_nonpersistent_flags+=("--prow")
    flags+=("--rbac")
    flags+=("-r")
    local_nonpersistent_flags+=("--rbac")
    flags+=("--recreate-existing-draft-repos")
    local_nonpersistent_flags+=("--recreate-existing-draft-repos")
    flags+=("--register-local-helmrepo")
    local_nonpersistent_flags+=("--register-local-helmrepo")
    flags+=("--skip-ingress")
    local_nonpersistent_flags+=("--skip-ingress")
    flags+=("--skip-tiller")
    local_nonpersistent_flags+=("--skip-tiller")
    flags+=("--state=")
    local_nonpersistent_flags+=("--state=")
    flags+=("--terraform=")
    two_word_flags+=("-t")
    local_nonpersistent_flags+=("--terraform=")
    flags+=("--tiller-cluster-role=")
    local_nonpersistent_flags+=("--tiller-cluster-role=")
    flags+=("--tiller-namespace=")
    local_nonpersistent_flags+=("--tiller-namespace=")
    flags+=("--timeout=")
    local_nonpersistent_flags+=("--timeout=")
    flags+=("--tls-acme=")
    local_nonpersistent_flags+=("--tls-acme=")
    flags+=("--user-cluster-role=")
    local_nonpersistent_flags+=("--user-cluster-role=")
    flags+=("--username=")
    local_nonpersistent_flags+=("--username=")
    flags+=("--verbose")
    local_nonpersistent_flags+=("--verbose")
    flags+=("--version=")
    local_nonpersistent_flags+=("--version=")
    flags+=("--zones=")
    two_word_flags+=("-z")
    local_nonpersistent_flags+=("--zones=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_create_cluster_eks()
{
    last_command="jx_create_cluster_eks"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--aws-api-timeout=")
    local_nonpersistent_flags+=("--aws-api-timeout=")
    flags+=("--batch-mode")
    flags+=("-b")
    local_nonpersistent_flags+=("--batch-mode")
    flags+=("--cleanup-temp-files")
    local_nonpersistent_flags+=("--cleanup-temp-files")
    flags+=("--cloud-environment-repo=")
    local_nonpersistent_flags+=("--cloud-environment-repo=")
    flags+=("--cluster-name=")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--cluster-name=")
    flags+=("--default-admin-password=")
    local_nonpersistent_flags+=("--default-admin-password=")
    flags+=("--default-environment-prefix=")
    local_nonpersistent_flags+=("--default-environment-prefix=")
    flags+=("--docker-registry=")
    local_nonpersistent_flags+=("--docker-registry=")
    flags+=("--domain=")
    local_nonpersistent_flags+=("--domain=")
    flags+=("--draft-client-only")
    local_nonpersistent_flags+=("--draft-client-only")
    flags+=("--environment-git-owner=")
    local_nonpersistent_flags+=("--environment-git-owner=")
    flags+=("--exposecontroller-pathmode=")
    local_nonpersistent_flags+=("--exposecontroller-pathmode=")
    flags+=("--exposer=")
    local_nonpersistent_flags+=("--exposer=")
    flags+=("--external-ip=")
    local_nonpersistent_flags+=("--external-ip=")
    flags+=("--git-api-token=")
    local_nonpersistent_flags+=("--git-api-token=")
    flags+=("--git-provider-url=")
    local_nonpersistent_flags+=("--git-provider-url=")
    flags+=("--git-username=")
    local_nonpersistent_flags+=("--git-username=")
    flags+=("--global-tiller")
    local_nonpersistent_flags+=("--global-tiller")
    flags+=("--headless")
    local_nonpersistent_flags+=("--headless")
    flags+=("--helm-client-only")
    local_nonpersistent_flags+=("--helm-client-only")
    flags+=("--helm-tls")
    local_nonpersistent_flags+=("--helm-tls")
    flags+=("--helm3")
    local_nonpersistent_flags+=("--helm3")
    flags+=("--http=")
    local_nonpersistent_flags+=("--http=")
    flags+=("--ingress-cluster-role=")
    local_nonpersistent_flags+=("--ingress-cluster-role=")
    flags+=("--ingress-deployment=")
    local_nonpersistent_flags+=("--ingress-deployment=")
    flags+=("--ingress-namespace=")
    local_nonpersistent_flags+=("--ingress-namespace=")
    flags+=("--ingress-service=")
    local_nonpersistent_flags+=("--ingress-service=")
    flags+=("--install-dependencies")
    local_nonpersistent_flags+=("--install-dependencies")
    flags+=("--install-only")
    local_nonpersistent_flags+=("--install-only")
    flags+=("--keep-exposecontroller-job")
    local_nonpersistent_flags+=("--keep-exposecontroller-job")
    flags+=("--local-cloud-environment")
    local_nonpersistent_flags+=("--local-cloud-environment")
    flags+=("--local-helm-repo-name=")
    local_nonpersistent_flags+=("--local-helm-repo-name=")
    flags+=("--log-level=")
    local_nonpersistent_flags+=("--log-level=")
    flags+=("--namespace=")
    local_nonpersistent_flags+=("--namespace=")
    flags+=("--no-brew")
    local_nonpersistent_flags+=("--no-brew")
    flags+=("--no-default-environments")
    local_nonpersistent_flags+=("--no-default-environments")
    flags+=("--nodes=")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--nodes=")
    flags+=("--nodes-max=")
    local_nonpersistent_flags+=("--nodes-max=")
    flags+=("--nodes-min=")
    local_nonpersistent_flags+=("--nodes-min=")
    flags+=("--on-premise")
    local_nonpersistent_flags+=("--on-premise")
    flags+=("--profile=")
    two_word_flags+=("-p")
    local_nonpersistent_flags+=("--profile=")
    flags+=("--prow")
    local_nonpersistent_flags+=("--prow")
    flags+=("--recreate-existing-draft-repos")
    local_nonpersistent_flags+=("--recreate-existing-draft-repos")
    flags+=("--region=")
    two_word_flags+=("-r")
    local_nonpersistent_flags+=("--region=")
    flags+=("--register-local-helmrepo")
    local_nonpersistent_flags+=("--register-local-helmrepo")
    flags+=("--skip-ingress")
    local_nonpersistent_flags+=("--skip-ingress")
    flags+=("--skip-tiller")
    local_nonpersistent_flags+=("--skip-tiller")
    flags+=("--ssh-public-key=")
    local_nonpersistent_flags+=("--ssh-public-key=")
    flags+=("--tiller-cluster-role=")
    local_nonpersistent_flags+=("--tiller-cluster-role=")
    flags+=("--tiller-namespace=")
    local_nonpersistent_flags+=("--tiller-namespace=")
    flags+=("--timeout=")
    local_nonpersistent_flags+=("--timeout=")
    flags+=("--tls-acme=")
    local_nonpersistent_flags+=("--tls-acme=")
    flags+=("--user-cluster-role=")
    local_nonpersistent_flags+=("--user-cluster-role=")
    flags+=("--username=")
    local_nonpersistent_flags+=("--username=")
    flags+=("--verbose")
    local_nonpersistent_flags+=("--verbose")
    flags+=("--version=")
    local_nonpersistent_flags+=("--version=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_create_cluster_gke_terraform()
{
    last_command="jx_create_cluster_gke_terraform"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--batch-mode")
    flags+=("-b")
    local_nonpersistent_flags+=("--batch-mode")
    flags+=("--cleanup-temp-files")
    local_nonpersistent_flags+=("--cleanup-temp-files")
    flags+=("--cloud-environment-repo=")
    local_nonpersistent_flags+=("--cloud-environment-repo=")
    flags+=("--cluster-name=")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--cluster-name=")
    flags+=("--default-admin-password=")
    local_nonpersistent_flags+=("--default-admin-password=")
    flags+=("--default-environment-prefix=")
    local_nonpersistent_flags+=("--default-environment-prefix=")
    flags+=("--disk-size=")
    two_word_flags+=("-d")
    local_nonpersistent_flags+=("--disk-size=")
    flags+=("--docker-registry=")
    local_nonpersistent_flags+=("--docker-registry=")
    flags+=("--domain=")
    local_nonpersistent_flags+=("--domain=")
    flags+=("--draft-client-only")
    local_nonpersistent_flags+=("--draft-client-only")
    flags+=("--enable-autoupgrade")
    local_nonpersistent_flags+=("--enable-autoupgrade")
    flags+=("--environment-git-owner=")
    local_nonpersistent_flags+=("--environment-git-owner=")
    flags+=("--exposecontroller-pathmode=")
    local_nonpersistent_flags+=("--exposecontroller-pathmode=")
    flags+=("--exposer=")
    local_nonpersistent_flags+=("--exposer=")
    flags+=("--external-ip=")
    local_nonpersistent_flags+=("--external-ip=")
    flags+=("--git-api-token=")
    local_nonpersistent_flags+=("--git-api-token=")
    flags+=("--git-provider-url=")
    local_nonpersistent_flags+=("--git-provider-url=")
    flags+=("--git-username=")
    local_nonpersistent_flags+=("--git-username=")
    flags+=("--global-tiller")
    local_nonpersistent_flags+=("--global-tiller")
    flags+=("--headless")
    local_nonpersistent_flags+=("--headless")
    flags+=("--helm-client-only")
    local_nonpersistent_flags+=("--helm-client-only")
    flags+=("--helm-tls")
    local_nonpersistent_flags+=("--helm-tls")
    flags+=("--helm3")
    local_nonpersistent_flags+=("--helm3")
    flags+=("--http=")
    local_nonpersistent_flags+=("--http=")
    flags+=("--ingress-cluster-role=")
    local_nonpersistent_flags+=("--ingress-cluster-role=")
    flags+=("--ingress-deployment=")
    local_nonpersistent_flags+=("--ingress-deployment=")
    flags+=("--ingress-namespace=")
    local_nonpersistent_flags+=("--ingress-namespace=")
    flags+=("--ingress-service=")
    local_nonpersistent_flags+=("--ingress-service=")
    flags+=("--install-dependencies")
    local_nonpersistent_flags+=("--install-dependencies")
    flags+=("--install-only")
    local_nonpersistent_flags+=("--install-only")
    flags+=("--keep-exposecontroller-job")
    local_nonpersistent_flags+=("--keep-exposecontroller-job")
    flags+=("--labels=")
    local_nonpersistent_flags+=("--labels=")
    flags+=("--local-cloud-environment")
    local_nonpersistent_flags+=("--local-cloud-environment")
    flags+=("--local-helm-repo-name=")
    local_nonpersistent_flags+=("--local-helm-repo-name=")
    flags+=("--machine-type=")
    two_word_flags+=("-m")
    local_nonpersistent_flags+=("--machine-type=")
    flags+=("--max-num-nodes=")
    local_nonpersistent_flags+=("--max-num-nodes=")
    flags+=("--min-num-nodes=")
    local_nonpersistent_flags+=("--min-num-nodes=")
    flags+=("--namespace=")
    local_nonpersistent_flags+=("--namespace=")
    flags+=("--no-brew")
    local_nonpersistent_flags+=("--no-brew")
    flags+=("--no-default-environments")
    local_nonpersistent_flags+=("--no-default-environments")
    flags+=("--on-premise")
    local_nonpersistent_flags+=("--on-premise")
    flags+=("--project-id=")
    two_word_flags+=("-p")
    local_nonpersistent_flags+=("--project-id=")
    flags+=("--prow")
    local_nonpersistent_flags+=("--prow")
    flags+=("--recreate-existing-draft-repos")
    local_nonpersistent_flags+=("--recreate-existing-draft-repos")
    flags+=("--register-local-helmrepo")
    local_nonpersistent_flags+=("--register-local-helmrepo")
    flags+=("--service-account=")
    local_nonpersistent_flags+=("--service-account=")
    flags+=("--skip-ingress")
    local_nonpersistent_flags+=("--skip-ingress")
    flags+=("--skip-login")
    local_nonpersistent_flags+=("--skip-login")
    flags+=("--skip-tiller")
    local_nonpersistent_flags+=("--skip-tiller")
    flags+=("--tiller-cluster-role=")
    local_nonpersistent_flags+=("--tiller-cluster-role=")
    flags+=("--tiller-namespace=")
    local_nonpersistent_flags+=("--tiller-namespace=")
    flags+=("--timeout=")
    local_nonpersistent_flags+=("--timeout=")
    flags+=("--tls-acme=")
    local_nonpersistent_flags+=("--tls-acme=")
    flags+=("--user-cluster-role=")
    local_nonpersistent_flags+=("--user-cluster-role=")
    flags+=("--username=")
    local_nonpersistent_flags+=("--username=")
    flags+=("--verbose")
    local_nonpersistent_flags+=("--verbose")
    flags+=("--version=")
    local_nonpersistent_flags+=("--version=")
    flags+=("--zone=")
    two_word_flags+=("-z")
    local_nonpersistent_flags+=("--zone=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_create_cluster_gke()
{
    last_command="jx_create_cluster_gke"

    command_aliases=()

    commands=()
    commands+=("terraform")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--batch-mode")
    flags+=("-b")
    local_nonpersistent_flags+=("--batch-mode")
    flags+=("--cleanup-temp-files")
    local_nonpersistent_flags+=("--cleanup-temp-files")
    flags+=("--cloud-environment-repo=")
    local_nonpersistent_flags+=("--cloud-environment-repo=")
    flags+=("--cluster-ipv4-cidr=")
    local_nonpersistent_flags+=("--cluster-ipv4-cidr=")
    flags+=("--cluster-name=")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--cluster-name=")
    flags+=("--default-admin-password=")
    local_nonpersistent_flags+=("--default-admin-password=")
    flags+=("--default-environment-prefix=")
    local_nonpersistent_flags+=("--default-environment-prefix=")
    flags+=("--disk-size=")
    two_word_flags+=("-d")
    local_nonpersistent_flags+=("--disk-size=")
    flags+=("--docker-registry=")
    local_nonpersistent_flags+=("--docker-registry=")
    flags+=("--domain=")
    local_nonpersistent_flags+=("--domain=")
    flags+=("--draft-client-only")
    local_nonpersistent_flags+=("--draft-client-only")
    flags+=("--enable-autoupgrade")
    local_nonpersistent_flags+=("--enable-autoupgrade")
    flags+=("--environment-git-owner=")
    local_nonpersistent_flags+=("--environment-git-owner=")
    flags+=("--exposecontroller-pathmode=")
    local_nonpersistent_flags+=("--exposecontroller-pathmode=")
    flags+=("--exposer=")
    local_nonpersistent_flags+=("--exposer=")
    flags+=("--external-ip=")
    local_nonpersistent_flags+=("--external-ip=")
    flags+=("--git-api-token=")
    local_nonpersistent_flags+=("--git-api-token=")
    flags+=("--git-provider-url=")
    local_nonpersistent_flags+=("--git-provider-url=")
    flags+=("--git-username=")
    local_nonpersistent_flags+=("--git-username=")
    flags+=("--global-tiller")
    local_nonpersistent_flags+=("--global-tiller")
    flags+=("--headless")
    local_nonpersistent_flags+=("--headless")
    flags+=("--helm-client-only")
    local_nonpersistent_flags+=("--helm-client-only")
    flags+=("--helm-tls")
    local_nonpersistent_flags+=("--helm-tls")
    flags+=("--helm3")
    local_nonpersistent_flags+=("--helm3")
    flags+=("--http=")
    local_nonpersistent_flags+=("--http=")
    flags+=("--ingress-cluster-role=")
    local_nonpersistent_flags+=("--ingress-cluster-role=")
    flags+=("--ingress-deployment=")
    local_nonpersistent_flags+=("--ingress-deployment=")
    flags+=("--ingress-namespace=")
    local_nonpersistent_flags+=("--ingress-namespace=")
    flags+=("--ingress-service=")
    local_nonpersistent_flags+=("--ingress-service=")
    flags+=("--install-dependencies")
    local_nonpersistent_flags+=("--install-dependencies")
    flags+=("--install-only")
    local_nonpersistent_flags+=("--install-only")
    flags+=("--keep-exposecontroller-job")
    local_nonpersistent_flags+=("--keep-exposecontroller-job")
    flags+=("--kubernetes-version=")
    two_word_flags+=("-v")
    local_nonpersistent_flags+=("--kubernetes-version=")
    flags+=("--labels=")
    local_nonpersistent_flags+=("--labels=")
    flags+=("--local-cloud-environment")
    local_nonpersistent_flags+=("--local-cloud-environment")
    flags+=("--local-helm-repo-name=")
    local_nonpersistent_flags+=("--local-helm-repo-name=")
    flags+=("--machine-type=")
    two_word_flags+=("-m")
    local_nonpersistent_flags+=("--machine-type=")
    flags+=("--max-num-nodes=")
    local_nonpersistent_flags+=("--max-num-nodes=")
    flags+=("--min-num-nodes=")
    local_nonpersistent_flags+=("--min-num-nodes=")
    flags+=("--namespace=")
    local_nonpersistent_flags+=("--namespace=")
    flags+=("--network=")
    local_nonpersistent_flags+=("--network=")
    flags+=("--no-brew")
    local_nonpersistent_flags+=("--no-brew")
    flags+=("--no-default-environments")
    local_nonpersistent_flags+=("--no-default-environments")
    flags+=("--on-premise")
    local_nonpersistent_flags+=("--on-premise")
    flags+=("--project-id=")
    two_word_flags+=("-p")
    local_nonpersistent_flags+=("--project-id=")
    flags+=("--prow")
    local_nonpersistent_flags+=("--prow")
    flags+=("--recreate-existing-draft-repos")
    local_nonpersistent_flags+=("--recreate-existing-draft-repos")
    flags+=("--register-local-helmrepo")
    local_nonpersistent_flags+=("--register-local-helmrepo")
    flags+=("--skip-ingress")
    local_nonpersistent_flags+=("--skip-ingress")
    flags+=("--skip-login")
    local_nonpersistent_flags+=("--skip-login")
    flags+=("--skip-tiller")
    local_nonpersistent_flags+=("--skip-tiller")
    flags+=("--subnetwork=")
    local_nonpersistent_flags+=("--subnetwork=")
    flags+=("--tiller-cluster-role=")
    local_nonpersistent_flags+=("--tiller-cluster-role=")
    flags+=("--tiller-namespace=")
    local_nonpersistent_flags+=("--tiller-namespace=")
    flags+=("--timeout=")
    local_nonpersistent_flags+=("--timeout=")
    flags+=("--tls-acme=")
    local_nonpersistent_flags+=("--tls-acme=")
    flags+=("--user-cluster-role=")
    local_nonpersistent_flags+=("--user-cluster-role=")
    flags+=("--username=")
    local_nonpersistent_flags+=("--username=")
    flags+=("--verbose")
    local_nonpersistent_flags+=("--verbose")
    flags+=("--version=")
    local_nonpersistent_flags+=("--version=")
    flags+=("--zone=")
    two_word_flags+=("-z")
    local_nonpersistent_flags+=("--zone=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_create_cluster_minikube()
{
    last_command="jx_create_cluster_minikube"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--batch-mode")
    flags+=("-b")
    local_nonpersistent_flags+=("--batch-mode")
    flags+=("--cleanup-temp-files")
    local_nonpersistent_flags+=("--cleanup-temp-files")
    flags+=("--cloud-environment-repo=")
    local_nonpersistent_flags+=("--cloud-environment-repo=")
    flags+=("--cpu=")
    two_word_flags+=("-c")
    local_nonpersistent_flags+=("--cpu=")
    flags+=("--default-admin-password=")
    local_nonpersistent_flags+=("--default-admin-password=")
    flags+=("--default-environment-prefix=")
    local_nonpersistent_flags+=("--default-environment-prefix=")
    flags+=("--docker-registry=")
    local_nonpersistent_flags+=("--docker-registry=")
    flags+=("--domain=")
    local_nonpersistent_flags+=("--domain=")
    flags+=("--draft-client-only")
    local_nonpersistent_flags+=("--draft-client-only")
    flags+=("--environment-git-owner=")
    local_nonpersistent_flags+=("--environment-git-owner=")
    flags+=("--exposecontroller-pathmode=")
    local_nonpersistent_flags+=("--exposecontroller-pathmode=")
    flags+=("--exposer=")
    local_nonpersistent_flags+=("--exposer=")
    flags+=("--external-ip=")
    local_nonpersistent_flags+=("--external-ip=")
    flags+=("--git-api-token=")
    local_nonpersistent_flags+=("--git-api-token=")
    flags+=("--git-provider-url=")
    local_nonpersistent_flags+=("--git-provider-url=")
    flags+=("--git-username=")
    local_nonpersistent_flags+=("--git-username=")
    flags+=("--global-tiller")
    local_nonpersistent_flags+=("--global-tiller")
    flags+=("--headless")
    local_nonpersistent_flags+=("--headless")
    flags+=("--helm-client-only")
    local_nonpersistent_flags+=("--helm-client-only")
    flags+=("--helm-tls")
    local_nonpersistent_flags+=("--helm-tls")
    flags+=("--helm3")
    local_nonpersistent_flags+=("--helm3")
    flags+=("--http=")
    local_nonpersistent_flags+=("--http=")
    flags+=("--hyperv-virtual-switch=")
    two_word_flags+=("-v")
    local_nonpersistent_flags+=("--hyperv-virtual-switch=")
    flags+=("--ingress-cluster-role=")
    local_nonpersistent_flags+=("--ingress-cluster-role=")
    flags+=("--ingress-deployment=")
    local_nonpersistent_flags+=("--ingress-deployment=")
    flags+=("--ingress-namespace=")
    local_nonpersistent_flags+=("--ingress-namespace=")
    flags+=("--ingress-service=")
    local_nonpersistent_flags+=("--ingress-service=")
    flags+=("--install-dependencies")
    local_nonpersistent_flags+=("--install-dependencies")
    flags+=("--install-only")
    local_nonpersistent_flags+=("--install-only")
    flags+=("--keep-exposecontroller-job")
    local_nonpersistent_flags+=("--keep-exposecontroller-job")
    flags+=("--kubernetes-version=")
    local_nonpersistent_flags+=("--kubernetes-version=")
    flags+=("--local-cloud-environment")
    local_nonpersistent_flags+=("--local-cloud-environment")
    flags+=("--local-helm-repo-name=")
    local_nonpersistent_flags+=("--local-helm-repo-name=")
    flags+=("--memory=")
    two_word_flags+=("-m")
    local_nonpersistent_flags+=("--memory=")
    flags+=("--namespace=")
    local_nonpersistent_flags+=("--namespace=")
    flags+=("--no-brew")
    local_nonpersistent_flags+=("--no-brew")
    flags+=("--no-default-environments")
    local_nonpersistent_flags+=("--no-default-environments")
    flags+=("--on-premise")
    local_nonpersistent_flags+=("--on-premise")
    flags+=("--prow")
    local_nonpersistent_flags+=("--prow")
    flags+=("--recreate-existing-draft-repos")
    local_nonpersistent_flags+=("--recreate-existing-draft-repos")
    flags+=("--register-local-helmrepo")
    local_nonpersistent_flags+=("--register-local-helmrepo")
    flags+=("--skip-ingress")
    local_nonpersistent_flags+=("--skip-ingress")
    flags+=("--skip-tiller")
    local_nonpersistent_flags+=("--skip-tiller")
    flags+=("--tiller-cluster-role=")
    local_nonpersistent_flags+=("--tiller-cluster-role=")
    flags+=("--tiller-namespace=")
    local_nonpersistent_flags+=("--tiller-namespace=")
    flags+=("--timeout=")
    local_nonpersistent_flags+=("--timeout=")
    flags+=("--tls-acme=")
    local_nonpersistent_flags+=("--tls-acme=")
    flags+=("--user-cluster-role=")
    local_nonpersistent_flags+=("--user-cluster-role=")
    flags+=("--username=")
    local_nonpersistent_flags+=("--username=")
    flags+=("--verbose")
    local_nonpersistent_flags+=("--verbose")
    flags+=("--version=")
    local_nonpersistent_flags+=("--version=")
    flags+=("--vm-driver=")
    two_word_flags+=("-d")
    local_nonpersistent_flags+=("--vm-driver=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_create_cluster_minishift()
{
    last_command="jx_create_cluster_minishift"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--batch-mode")
    flags+=("-b")
    local_nonpersistent_flags+=("--batch-mode")
    flags+=("--cleanup-temp-files")
    local_nonpersistent_flags+=("--cleanup-temp-files")
    flags+=("--cloud-environment-repo=")
    local_nonpersistent_flags+=("--cloud-environment-repo=")
    flags+=("--cpu=")
    two_word_flags+=("-c")
    local_nonpersistent_flags+=("--cpu=")
    flags+=("--default-admin-password=")
    local_nonpersistent_flags+=("--default-admin-password=")
    flags+=("--default-environment-prefix=")
    local_nonpersistent_flags+=("--default-environment-prefix=")
    flags+=("--docker-registry=")
    local_nonpersistent_flags+=("--docker-registry=")
    flags+=("--domain=")
    local_nonpersistent_flags+=("--domain=")
    flags+=("--draft-client-only")
    local_nonpersistent_flags+=("--draft-client-only")
    flags+=("--environment-git-owner=")
    local_nonpersistent_flags+=("--environment-git-owner=")
    flags+=("--exposecontroller-pathmode=")
    local_nonpersistent_flags+=("--exposecontroller-pathmode=")
    flags+=("--exposer=")
    local_nonpersistent_flags+=("--exposer=")
    flags+=("--external-ip=")
    local_nonpersistent_flags+=("--external-ip=")
    flags+=("--git-api-token=")
    local_nonpersistent_flags+=("--git-api-token=")
    flags+=("--git-provider-url=")
    local_nonpersistent_flags+=("--git-provider-url=")
    flags+=("--git-username=")
    local_nonpersistent_flags+=("--git-username=")
    flags+=("--global-tiller")
    local_nonpersistent_flags+=("--global-tiller")
    flags+=("--headless")
    local_nonpersistent_flags+=("--headless")
    flags+=("--helm-client-only")
    local_nonpersistent_flags+=("--helm-client-only")
    flags+=("--helm-tls")
    local_nonpersistent_flags+=("--helm-tls")
    flags+=("--helm3")
    local_nonpersistent_flags+=("--helm3")
    flags+=("--http=")
    local_nonpersistent_flags+=("--http=")
    flags+=("--hyperv-virtual-switch=")
    two_word_flags+=("-v")
    local_nonpersistent_flags+=("--hyperv-virtual-switch=")
    flags+=("--ingress-cluster-role=")
    local_nonpersistent_flags+=("--ingress-cluster-role=")
    flags+=("--ingress-deployment=")
    local_nonpersistent_flags+=("--ingress-deployment=")
    flags+=("--ingress-namespace=")
    local_nonpersistent_flags+=("--ingress-namespace=")
    flags+=("--ingress-service=")
    local_nonpersistent_flags+=("--ingress-service=")
    flags+=("--install-dependencies")
    local_nonpersistent_flags+=("--install-dependencies")
    flags+=("--install-only")
    local_nonpersistent_flags+=("--install-only")
    flags+=("--keep-exposecontroller-job")
    local_nonpersistent_flags+=("--keep-exposecontroller-job")
    flags+=("--local-cloud-environment")
    local_nonpersistent_flags+=("--local-cloud-environment")
    flags+=("--local-helm-repo-name=")
    local_nonpersistent_flags+=("--local-helm-repo-name=")
    flags+=("--memory=")
    two_word_flags+=("-m")
    local_nonpersistent_flags+=("--memory=")
    flags+=("--namespace=")
    local_nonpersistent_flags+=("--namespace=")
    flags+=("--no-brew")
    local_nonpersistent_flags+=("--no-brew")
    flags+=("--no-default-environments")
    local_nonpersistent_flags+=("--no-default-environments")
    flags+=("--on-premise")
    local_nonpersistent_flags+=("--on-premise")
    flags+=("--prow")
    local_nonpersistent_flags+=("--prow")
    flags+=("--recreate-existing-draft-repos")
    local_nonpersistent_flags+=("--recreate-existing-draft-repos")
    flags+=("--register-local-helmrepo")
    local_nonpersistent_flags+=("--register-local-helmrepo")
    flags+=("--skip-ingress")
    local_nonpersistent_flags+=("--skip-ingress")
    flags+=("--skip-tiller")
    local_nonpersistent_flags+=("--skip-tiller")
    flags+=("--tiller-cluster-role=")
    local_nonpersistent_flags+=("--tiller-cluster-role=")
    flags+=("--tiller-namespace=")
    local_nonpersistent_flags+=("--tiller-namespace=")
    flags+=("--timeout=")
    local_nonpersistent_flags+=("--timeout=")
    flags+=("--tls-acme=")
    local_nonpersistent_flags+=("--tls-acme=")
    flags+=("--user-cluster-role=")
    local_nonpersistent_flags+=("--user-cluster-role=")
    flags+=("--username=")
    local_nonpersistent_flags+=("--username=")
    flags+=("--verbose")
    local_nonpersistent_flags+=("--verbose")
    flags+=("--version=")
    local_nonpersistent_flags+=("--version=")
    flags+=("--vm-driver=")
    two_word_flags+=("-d")
    local_nonpersistent_flags+=("--vm-driver=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_create_cluster_oke()
{
    last_command="jx_create_cluster_oke"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--batch-mode")
    flags+=("-b")
    local_nonpersistent_flags+=("--batch-mode")
    flags+=("--cleanup-temp-files")
    local_nonpersistent_flags+=("--cleanup-temp-files")
    flags+=("--cloud-environment-repo=")
    local_nonpersistent_flags+=("--cloud-environment-repo=")
    flags+=("--clusterMaxWaitSeconds=")
    local_nonpersistent_flags+=("--clusterMaxWaitSeconds=")
    flags+=("--clusterWaitIntervalSeconds=")
    local_nonpersistent_flags+=("--clusterWaitIntervalSeconds=")
    flags+=("--compartmentId=")
    local_nonpersistent_flags+=("--compartmentId=")
    flags+=("--default-admin-password=")
    local_nonpersistent_flags+=("--default-admin-password=")
    flags+=("--default-environment-prefix=")
    local_nonpersistent_flags+=("--default-environment-prefix=")
    flags+=("--docker-registry=")
    local_nonpersistent_flags+=("--docker-registry=")
    flags+=("--domain=")
    local_nonpersistent_flags+=("--domain=")
    flags+=("--draft-client-only")
    local_nonpersistent_flags+=("--draft-client-only")
    flags+=("--endpoint=")
    local_nonpersistent_flags+=("--endpoint=")
    flags+=("--environment-git-owner=")
    local_nonpersistent_flags+=("--environment-git-owner=")
    flags+=("--exposecontroller-pathmode=")
    local_nonpersistent_flags+=("--exposecontroller-pathmode=")
    flags+=("--exposer=")
    local_nonpersistent_flags+=("--exposer=")
    flags+=("--external-ip=")
    local_nonpersistent_flags+=("--external-ip=")
    flags+=("--git-api-token=")
    local_nonpersistent_flags+=("--git-api-token=")
    flags+=("--git-provider-url=")
    local_nonpersistent_flags+=("--git-provider-url=")
    flags+=("--git-username=")
    local_nonpersistent_flags+=("--git-username=")
    flags+=("--global-tiller")
    local_nonpersistent_flags+=("--global-tiller")
    flags+=("--headless")
    local_nonpersistent_flags+=("--headless")
    flags+=("--helm-client-only")
    local_nonpersistent_flags+=("--helm-client-only")
    flags+=("--helm-tls")
    local_nonpersistent_flags+=("--helm-tls")
    flags+=("--helm3")
    local_nonpersistent_flags+=("--helm3")
    flags+=("--http=")
    local_nonpersistent_flags+=("--http=")
    flags+=("--ingress-cluster-role=")
    local_nonpersistent_flags+=("--ingress-cluster-role=")
    flags+=("--ingress-deployment=")
    local_nonpersistent_flags+=("--ingress-deployment=")
    flags+=("--ingress-namespace=")
    local_nonpersistent_flags+=("--ingress-namespace=")
    flags+=("--ingress-service=")
    local_nonpersistent_flags+=("--ingress-service=")
    flags+=("--initialNodeLabels=")
    local_nonpersistent_flags+=("--initialNodeLabels=")
    flags+=("--install-dependencies")
    local_nonpersistent_flags+=("--install-dependencies")
    flags+=("--install-only")
    local_nonpersistent_flags+=("--install-only")
    flags+=("--isKubernetesDashboardEnabled")
    local_nonpersistent_flags+=("--isKubernetesDashboardEnabled")
    flags+=("--isTillerEnabled")
    local_nonpersistent_flags+=("--isTillerEnabled")
    flags+=("--keep-exposecontroller-job")
    local_nonpersistent_flags+=("--keep-exposecontroller-job")
    flags+=("--kubernetesVersion=")
    local_nonpersistent_flags+=("--kubernetesVersion=")
    flags+=("--local-cloud-environment")
    local_nonpersistent_flags+=("--local-cloud-environment")
    flags+=("--local-helm-repo-name=")
    local_nonpersistent_flags+=("--local-helm-repo-name=")
    flags+=("--name=")
    local_nonpersistent_flags+=("--name=")
    flags+=("--namespace=")
    local_nonpersistent_flags+=("--namespace=")
    flags+=("--no-brew")
    local_nonpersistent_flags+=("--no-brew")
    flags+=("--no-default-environments")
    local_nonpersistent_flags+=("--no-default-environments")
    flags+=("--nodeImageName=")
    local_nonpersistent_flags+=("--nodeImageName=")
    flags+=("--nodePoolName=")
    local_nonpersistent_flags+=("--nodePoolName=")
    flags+=("--nodePoolSubnetIds=")
    local_nonpersistent_flags+=("--nodePoolSubnetIds=")
    flags+=("--nodeShape=")
    local_nonpersistent_flags+=("--nodeShape=")
    flags+=("--on-premise")
    local_nonpersistent_flags+=("--on-premise")
    flags+=("--podsCidr=")
    local_nonpersistent_flags+=("--podsCidr=")
    flags+=("--poolMaxWaitSeconds=")
    local_nonpersistent_flags+=("--poolMaxWaitSeconds=")
    flags+=("--poolWaitIntervalSeconds=")
    local_nonpersistent_flags+=("--poolWaitIntervalSeconds=")
    flags+=("--prow")
    local_nonpersistent_flags+=("--prow")
    flags+=("--quantityPerSubnet=")
    local_nonpersistent_flags+=("--quantityPerSubnet=")
    flags+=("--recreate-existing-draft-repos")
    local_nonpersistent_flags+=("--recreate-existing-draft-repos")
    flags+=("--register-local-helmrepo")
    local_nonpersistent_flags+=("--register-local-helmrepo")
    flags+=("--serviceLbSubnetIds=")
    local_nonpersistent_flags+=("--serviceLbSubnetIds=")
    flags+=("--servicesCidr=")
    local_nonpersistent_flags+=("--servicesCidr=")
    flags+=("--skip-ingress")
    local_nonpersistent_flags+=("--skip-ingress")
    flags+=("--skip-tiller")
    local_nonpersistent_flags+=("--skip-tiller")
    flags+=("--sshPublicKey=")
    local_nonpersistent_flags+=("--sshPublicKey=")
    flags+=("--tiller-cluster-role=")
    local_nonpersistent_flags+=("--tiller-cluster-role=")
    flags+=("--tiller-namespace=")
    local_nonpersistent_flags+=("--tiller-namespace=")
    flags+=("--timeout=")
    local_nonpersistent_flags+=("--timeout=")
    flags+=("--tls-acme=")
    local_nonpersistent_flags+=("--tls-acme=")
    flags+=("--user-cluster-role=")
    local_nonpersistent_flags+=("--user-cluster-role=")
    flags+=("--username=")
    local_nonpersistent_flags+=("--username=")
    flags+=("--vcnId=")
    local_nonpersistent_flags+=("--vcnId=")
    flags+=("--verbose")
    local_nonpersistent_flags+=("--verbose")
    flags+=("--version=")
    local_nonpersistent_flags+=("--version=")
    flags+=("--waitForState=")
    local_nonpersistent_flags+=("--waitForState=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_create_cluster()
{
    last_command="jx_create_cluster"

    command_aliases=()

    commands=()
    commands+=("aks")
    commands+=("aws")
    commands+=("eks")
    commands+=("gke")
    commands+=("minikube")
    commands+=("minishift")
    commands+=("oke")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()


    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_create_codeship()
{
    last_command="jx_create_codeship"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--batch-mode")
    flags+=("-b")
    local_nonpersistent_flags+=("--batch-mode")
    flags+=("--cluster=")
    two_word_flags+=("-c")
    local_nonpersistent_flags+=("--cluster=")
    flags+=("--codeship-organisation=")
    local_nonpersistent_flags+=("--codeship-organisation=")
    flags+=("--codeship-password=")
    local_nonpersistent_flags+=("--codeship-password=")
    flags+=("--codeship-username=")
    local_nonpersistent_flags+=("--codeship-username=")
    flags+=("--fork-git-repo=")
    two_word_flags+=("-f")
    local_nonpersistent_flags+=("--fork-git-repo=")
    flags+=("--git-email=")
    local_nonpersistent_flags+=("--git-email=")
    flags+=("--git-user=")
    local_nonpersistent_flags+=("--git-user=")
    flags+=("--gke-disk-size=")
    local_nonpersistent_flags+=("--gke-disk-size=")
    flags+=("--gke-enable-autorepair")
    local_nonpersistent_flags+=("--gke-enable-autorepair")
    flags+=("--gke-enable-autoupgrade")
    local_nonpersistent_flags+=("--gke-enable-autoupgrade")
    flags+=("--gke-machine-type=")
    local_nonpersistent_flags+=("--gke-machine-type=")
    flags+=("--gke-max-num-nodes=")
    local_nonpersistent_flags+=("--gke-max-num-nodes=")
    flags+=("--gke-min-num-nodes=")
    local_nonpersistent_flags+=("--gke-min-num-nodes=")
    flags+=("--gke-project-id=")
    local_nonpersistent_flags+=("--gke-project-id=")
    flags+=("--gke-service-account=")
    local_nonpersistent_flags+=("--gke-service-account=")
    flags+=("--gke-zone=")
    local_nonpersistent_flags+=("--gke-zone=")
    flags+=("--headless")
    local_nonpersistent_flags+=("--headless")
    flags+=("--ignore-terraform-warnings")
    local_nonpersistent_flags+=("--ignore-terraform-warnings")
    flags+=("--install-dependencies")
    local_nonpersistent_flags+=("--install-dependencies")
    flags+=("--jx-environment=")
    local_nonpersistent_flags+=("--jx-environment=")
    flags+=("--local-organisation-repository=")
    local_nonpersistent_flags+=("--local-organisation-repository=")
    flags+=("--name=")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--name=")
    flags+=("--no-brew")
    local_nonpersistent_flags+=("--no-brew")
    flags+=("--organisation-name=")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--organisation-name=")
    flags+=("--project=")
    two_word_flags+=("-p")
    local_nonpersistent_flags+=("--project=")
    flags+=("--skip-login")
    local_nonpersistent_flags+=("--skip-login")
    flags+=("--skip-terraform-apply")
    local_nonpersistent_flags+=("--skip-terraform-apply")
    flags+=("--verbose")
    local_nonpersistent_flags+=("--verbose")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_create_devpod()
{
    last_command="jx_create_devpod"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--batch-mode")
    flags+=("-b")
    local_nonpersistent_flags+=("--batch-mode")
    flags+=("--headless")
    local_nonpersistent_flags+=("--headless")
    flags+=("--install-dependencies")
    local_nonpersistent_flags+=("--install-dependencies")
    flags+=("--label=")
    two_word_flags+=("-l")
    local_nonpersistent_flags+=("--label=")
    flags+=("--no-brew")
    local_nonpersistent_flags+=("--no-brew")
    flags+=("--request-cpu=")
    two_word_flags+=("-c")
    local_nonpersistent_flags+=("--request-cpu=")
    flags+=("--reuse")
    local_nonpersistent_flags+=("--reuse")
    flags+=("--suffix=")
    two_word_flags+=("-s")
    local_nonpersistent_flags+=("--suffix=")
    flags+=("--sync")
    local_nonpersistent_flags+=("--sync")
    flags+=("--verbose")
    local_nonpersistent_flags+=("--verbose")
    flags+=("--working-dir=")
    two_word_flags+=("-w")
    local_nonpersistent_flags+=("--working-dir=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_create_docs()
{
    last_command="jx_create_docs"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--dir=")
    two_word_flags+=("-d")
    local_nonpersistent_flags+=("--dir=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_create_environment()
{
    last_command="jx_create_environment"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--branches=")
    local_nonpersistent_flags+=("--branches=")
    flags+=("--cluster=")
    two_word_flags+=("-c")
    local_nonpersistent_flags+=("--cluster=")
    flags+=("--domain=")
    local_nonpersistent_flags+=("--domain=")
    flags+=("--env-job-credentials=")
    local_nonpersistent_flags+=("--env-job-credentials=")
    flags+=("--exposer=")
    local_nonpersistent_flags+=("--exposer=")
    flags+=("--fork-git-repo=")
    two_word_flags+=("-f")
    local_nonpersistent_flags+=("--fork-git-repo=")
    flags+=("--git-api-token=")
    local_nonpersistent_flags+=("--git-api-token=")
    flags+=("--git-provider-url=")
    local_nonpersistent_flags+=("--git-provider-url=")
    flags+=("--git-ref=")
    two_word_flags+=("-r")
    local_nonpersistent_flags+=("--git-ref=")
    flags+=("--git-url=")
    two_word_flags+=("-g")
    local_nonpersistent_flags+=("--git-url=")
    flags+=("--git-username=")
    local_nonpersistent_flags+=("--git-username=")
    flags+=("--http=")
    local_nonpersistent_flags+=("--http=")
    flags+=("--keep-exposecontroller-job")
    local_nonpersistent_flags+=("--keep-exposecontroller-job")
    flags+=("--label=")
    two_word_flags+=("-l")
    local_nonpersistent_flags+=("--label=")
    flags+=("--name=")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--name=")
    flags+=("--namespace=")
    two_word_flags+=("-s")
    local_nonpersistent_flags+=("--namespace=")
    flags+=("--no-gitops")
    flags+=("-x")
    local_nonpersistent_flags+=("--no-gitops")
    flags+=("--order=")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--order=")
    flags+=("--prefix=")
    local_nonpersistent_flags+=("--prefix=")
    flags+=("--promotion=")
    two_word_flags+=("-p")
    local_nonpersistent_flags+=("--promotion=")
    flags+=("--prow")
    local_nonpersistent_flags+=("--prow")
    flags+=("--tls-acme=")
    local_nonpersistent_flags+=("--tls-acme=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_create_etc-hosts()
{
    last_command="jx_create_etc-hosts"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--ip=")
    two_word_flags+=("-i")
    local_nonpersistent_flags+=("--ip=")
    flags+=("--name=")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--name=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_create_git_server()
{
    last_command="jx_create_git_server"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--name=")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--name=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_create_git_token()
{
    last_command="jx_create_git_token"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--api-token=")
    two_word_flags+=("-t")
    local_nonpersistent_flags+=("--api-token=")
    flags+=("--batch-mode")
    flags+=("-b")
    local_nonpersistent_flags+=("--batch-mode")
    flags+=("--headless")
    local_nonpersistent_flags+=("--headless")
    flags+=("--install-dependencies")
    local_nonpersistent_flags+=("--install-dependencies")
    flags+=("--name=")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--name=")
    flags+=("--no-brew")
    local_nonpersistent_flags+=("--no-brew")
    flags+=("--password=")
    two_word_flags+=("-p")
    local_nonpersistent_flags+=("--password=")
    flags+=("--timeout=")
    local_nonpersistent_flags+=("--timeout=")
    flags+=("--url=")
    two_word_flags+=("-u")
    local_nonpersistent_flags+=("--url=")
    flags+=("--verbose")
    local_nonpersistent_flags+=("--verbose")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_create_git_user()
{
    last_command="jx_create_git_user"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--admin")
    flags+=("-a")
    local_nonpersistent_flags+=("--admin")
    flags+=("--api-token=")
    two_word_flags+=("-t")
    local_nonpersistent_flags+=("--api-token=")
    flags+=("--batch-mode")
    flags+=("-b")
    local_nonpersistent_flags+=("--batch-mode")
    flags+=("--email=")
    two_word_flags+=("-e")
    local_nonpersistent_flags+=("--email=")
    flags+=("--headless")
    local_nonpersistent_flags+=("--headless")
    flags+=("--install-dependencies")
    local_nonpersistent_flags+=("--install-dependencies")
    flags+=("--name=")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--name=")
    flags+=("--no-brew")
    local_nonpersistent_flags+=("--no-brew")
    flags+=("--password=")
    two_word_flags+=("-p")
    local_nonpersistent_flags+=("--password=")
    flags+=("--url=")
    two_word_flags+=("-u")
    local_nonpersistent_flags+=("--url=")
    flags+=("--verbose")
    local_nonpersistent_flags+=("--verbose")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_create_git()
{
    last_command="jx_create_git"

    command_aliases=()

    commands=()
    commands+=("server")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("provider")
        aliashash["provider"]="server"
    fi
    commands+=("token")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("api-token")
        aliashash["api-token"]="token"
    fi
    commands+=("user")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()


    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_create_gke-service-account()
{
    last_command="jx_create_gke-service-account"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--batch-mode")
    flags+=("-b")
    local_nonpersistent_flags+=("--batch-mode")
    flags+=("--headless")
    local_nonpersistent_flags+=("--headless")
    flags+=("--install-dependencies")
    local_nonpersistent_flags+=("--install-dependencies")
    flags+=("--name=")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--name=")
    flags+=("--no-brew")
    local_nonpersistent_flags+=("--no-brew")
    flags+=("--project=")
    two_word_flags+=("-p")
    local_nonpersistent_flags+=("--project=")
    flags+=("--skip-login")
    local_nonpersistent_flags+=("--skip-login")
    flags+=("--verbose")
    local_nonpersistent_flags+=("--verbose")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_create_issue()
{
    last_command="jx_create_issue"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--batch-mode")
    flags+=("-b")
    local_nonpersistent_flags+=("--batch-mode")
    flags+=("--body=")
    local_nonpersistent_flags+=("--body=")
    flags+=("--dir=")
    local_nonpersistent_flags+=("--dir=")
    flags+=("--headless")
    local_nonpersistent_flags+=("--headless")
    flags+=("--install-dependencies")
    local_nonpersistent_flags+=("--install-dependencies")
    flags+=("--label=")
    two_word_flags+=("-l")
    local_nonpersistent_flags+=("--label=")
    flags+=("--no-brew")
    local_nonpersistent_flags+=("--no-brew")
    flags+=("--title=")
    two_word_flags+=("-t")
    local_nonpersistent_flags+=("--title=")
    flags+=("--verbose")
    local_nonpersistent_flags+=("--verbose")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_create_jenkins_token()
{
    last_command="jx_create_jenkins_token"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--api-token=")
    two_word_flags+=("-t")
    local_nonpersistent_flags+=("--api-token=")
    flags+=("--batch-mode")
    flags+=("-b")
    local_nonpersistent_flags+=("--batch-mode")
    flags+=("--browser")
    local_nonpersistent_flags+=("--browser")
    flags+=("--headless")
    local_nonpersistent_flags+=("--headless")
    flags+=("--install-dependencies")
    local_nonpersistent_flags+=("--install-dependencies")
    flags+=("--name=")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--name=")
    flags+=("--no-brew")
    local_nonpersistent_flags+=("--no-brew")
    flags+=("--password=")
    two_word_flags+=("-p")
    local_nonpersistent_flags+=("--password=")
    flags+=("--timeout=")
    local_nonpersistent_flags+=("--timeout=")
    flags+=("--url=")
    two_word_flags+=("-u")
    local_nonpersistent_flags+=("--url=")
    flags+=("--verbose")
    local_nonpersistent_flags+=("--verbose")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_create_jenkins()
{
    last_command="jx_create_jenkins"

    command_aliases=()

    commands=()
    commands+=("token")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("api-token")
        aliashash["api-token"]="token"
    fi

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()


    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_create_jhipster()
{
    last_command="jx_create_jhipster"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--batch-mode")
    flags+=("-b")
    local_nonpersistent_flags+=("--batch-mode")
    flags+=("--branches=")
    local_nonpersistent_flags+=("--branches=")
    flags+=("--credentials=")
    local_nonpersistent_flags+=("--credentials=")
    flags+=("--default-owner=")
    local_nonpersistent_flags+=("--default-owner=")
    flags+=("--dry-run")
    local_nonpersistent_flags+=("--dry-run")
    flags+=("--git-api-token=")
    local_nonpersistent_flags+=("--git-api-token=")
    flags+=("--git-provider-url=")
    local_nonpersistent_flags+=("--git-provider-url=")
    flags+=("--git-username=")
    local_nonpersistent_flags+=("--git-username=")
    flags+=("--headless")
    local_nonpersistent_flags+=("--headless")
    flags+=("--import-commit-message=")
    local_nonpersistent_flags+=("--import-commit-message=")
    flags+=("--install-dependencies")
    local_nonpersistent_flags+=("--install-dependencies")
    flags+=("--jenkinsfile=")
    local_nonpersistent_flags+=("--jenkinsfile=")
    flags+=("--list-packs")
    local_nonpersistent_flags+=("--list-packs")
    flags+=("--name=")
    local_nonpersistent_flags+=("--name=")
    flags+=("--no-brew")
    local_nonpersistent_flags+=("--no-brew")
    flags+=("--no-draft")
    local_nonpersistent_flags+=("--no-draft")
    flags+=("--no-import")
    local_nonpersistent_flags+=("--no-import")
    flags+=("--no-jenkinsfile")
    local_nonpersistent_flags+=("--no-jenkinsfile")
    flags+=("--org=")
    local_nonpersistent_flags+=("--org=")
    flags+=("--output-dir=")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--output-dir=")
    flags+=("--pack=")
    local_nonpersistent_flags+=("--pack=")
    flags+=("--verbose")
    local_nonpersistent_flags+=("--verbose")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_create_lile()
{
    last_command="jx_create_lile"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--output-dir=")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--output-dir=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_create_micro()
{
    last_command="jx_create_micro"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()


    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_create_post()
{
    last_command="jx_create_post"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--backoff-limit=")
    two_word_flags+=("-l")
    local_nonpersistent_flags+=("--backoff-limit=")
    flags+=("--batch-mode")
    flags+=("-b")
    local_nonpersistent_flags+=("--batch-mode")
    flags+=("--commands=")
    two_word_flags+=("-c")
    local_nonpersistent_flags+=("--commands=")
    flags+=("--headless")
    local_nonpersistent_flags+=("--headless")
    flags+=("--image=")
    two_word_flags+=("-i")
    local_nonpersistent_flags+=("--image=")
    flags+=("--install-dependencies")
    local_nonpersistent_flags+=("--install-dependencies")
    flags+=("--name=")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--name=")
    flags+=("--no-brew")
    local_nonpersistent_flags+=("--no-brew")
    flags+=("--verbose")
    local_nonpersistent_flags+=("--verbose")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_create_quickstart()
{
    last_command="jx_create_quickstart"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--batch-mode")
    flags+=("-b")
    local_nonpersistent_flags+=("--batch-mode")
    flags+=("--branches=")
    local_nonpersistent_flags+=("--branches=")
    flags+=("--credentials=")
    local_nonpersistent_flags+=("--credentials=")
    flags+=("--default-owner=")
    local_nonpersistent_flags+=("--default-owner=")
    flags+=("--dry-run")
    local_nonpersistent_flags+=("--dry-run")
    flags+=("--filter=")
    two_word_flags+=("-f")
    local_nonpersistent_flags+=("--filter=")
    flags+=("--framework=")
    local_nonpersistent_flags+=("--framework=")
    flags+=("--git-api-token=")
    local_nonpersistent_flags+=("--git-api-token=")
    flags+=("--git-host=")
    local_nonpersistent_flags+=("--git-host=")
    flags+=("--git-provider-url=")
    local_nonpersistent_flags+=("--git-provider-url=")
    flags+=("--git-username=")
    local_nonpersistent_flags+=("--git-username=")
    flags+=("--headless")
    local_nonpersistent_flags+=("--headless")
    flags+=("--import-commit-message=")
    local_nonpersistent_flags+=("--import-commit-message=")
    flags+=("--install-dependencies")
    local_nonpersistent_flags+=("--install-dependencies")
    flags+=("--jenkinsfile=")
    local_nonpersistent_flags+=("--jenkinsfile=")
    flags+=("--language=")
    two_word_flags+=("-l")
    local_nonpersistent_flags+=("--language=")
    flags+=("--list-packs")
    local_nonpersistent_flags+=("--list-packs")
    flags+=("--name=")
    local_nonpersistent_flags+=("--name=")
    flags+=("--no-brew")
    local_nonpersistent_flags+=("--no-brew")
    flags+=("--no-draft")
    local_nonpersistent_flags+=("--no-draft")
    flags+=("--no-import")
    local_nonpersistent_flags+=("--no-import")
    flags+=("--no-jenkinsfile")
    local_nonpersistent_flags+=("--no-jenkinsfile")
    flags+=("--org=")
    local_nonpersistent_flags+=("--org=")
    flags+=("--organisations=")
    two_word_flags+=("-g")
    local_nonpersistent_flags+=("--organisations=")
    flags+=("--output-dir=")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--output-dir=")
    flags+=("--owner=")
    local_nonpersistent_flags+=("--owner=")
    flags+=("--pack=")
    local_nonpersistent_flags+=("--pack=")
    flags+=("--project-name=")
    two_word_flags+=("-p")
    local_nonpersistent_flags+=("--project-name=")
    flags+=("--tag=")
    two_word_flags+=("-t")
    local_nonpersistent_flags+=("--tag=")
    flags+=("--verbose")
    local_nonpersistent_flags+=("--verbose")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_create_quickstartlocation()
{
    last_command="jx_create_quickstartlocation"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--batch-mode")
    flags+=("-b")
    local_nonpersistent_flags+=("--batch-mode")
    flags+=("--excludes=")
    two_word_flags+=("-x")
    local_nonpersistent_flags+=("--excludes=")
    flags+=("--headless")
    local_nonpersistent_flags+=("--headless")
    flags+=("--includes=")
    two_word_flags+=("-i")
    local_nonpersistent_flags+=("--includes=")
    flags+=("--install-dependencies")
    local_nonpersistent_flags+=("--install-dependencies")
    flags+=("--kind=")
    two_word_flags+=("-k")
    local_nonpersistent_flags+=("--kind=")
    flags+=("--no-brew")
    local_nonpersistent_flags+=("--no-brew")
    flags+=("--owner=")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--owner=")
    flags+=("--url=")
    two_word_flags+=("-u")
    local_nonpersistent_flags+=("--url=")
    flags+=("--verbose")
    local_nonpersistent_flags+=("--verbose")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_create_shell-completions()
{
    last_command="jx_create_shell-completions"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()


    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_create_spring()
{
    last_command="jx_create_spring"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--advanced")
    flags+=("-x")
    local_nonpersistent_flags+=("--advanced")
    flags+=("--artifact=")
    two_word_flags+=("-a")
    local_nonpersistent_flags+=("--artifact=")
    flags+=("--batch-mode")
    flags+=("-b")
    local_nonpersistent_flags+=("--batch-mode")
    flags+=("--boot-version=")
    two_word_flags+=("-t")
    local_nonpersistent_flags+=("--boot-version=")
    flags+=("--branches=")
    local_nonpersistent_flags+=("--branches=")
    flags+=("--credentials=")
    local_nonpersistent_flags+=("--credentials=")
    flags+=("--default-owner=")
    local_nonpersistent_flags+=("--default-owner=")
    flags+=("--dep=")
    two_word_flags+=("-d")
    local_nonpersistent_flags+=("--dep=")
    flags+=("--dry-run")
    local_nonpersistent_flags+=("--dry-run")
    flags+=("--git-api-token=")
    local_nonpersistent_flags+=("--git-api-token=")
    flags+=("--git-provider-url=")
    local_nonpersistent_flags+=("--git-provider-url=")
    flags+=("--git-username=")
    local_nonpersistent_flags+=("--git-username=")
    flags+=("--group=")
    two_word_flags+=("-g")
    local_nonpersistent_flags+=("--group=")
    flags+=("--headless")
    local_nonpersistent_flags+=("--headless")
    flags+=("--import-commit-message=")
    local_nonpersistent_flags+=("--import-commit-message=")
    flags+=("--install-dependencies")
    local_nonpersistent_flags+=("--install-dependencies")
    flags+=("--java-version=")
    two_word_flags+=("-j")
    local_nonpersistent_flags+=("--java-version=")
    flags+=("--jenkinsfile=")
    local_nonpersistent_flags+=("--jenkinsfile=")
    flags+=("--kind=")
    two_word_flags+=("-k")
    local_nonpersistent_flags+=("--kind=")
    flags+=("--language=")
    two_word_flags+=("-l")
    local_nonpersistent_flags+=("--language=")
    flags+=("--list-packs")
    local_nonpersistent_flags+=("--list-packs")
    flags+=("--name=")
    local_nonpersistent_flags+=("--name=")
    flags+=("--no-brew")
    local_nonpersistent_flags+=("--no-brew")
    flags+=("--no-draft")
    local_nonpersistent_flags+=("--no-draft")
    flags+=("--no-import")
    local_nonpersistent_flags+=("--no-import")
    flags+=("--no-jenkinsfile")
    local_nonpersistent_flags+=("--no-jenkinsfile")
    flags+=("--org=")
    local_nonpersistent_flags+=("--org=")
    flags+=("--output-dir=")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--output-dir=")
    flags+=("--pack=")
    local_nonpersistent_flags+=("--pack=")
    flags+=("--packaging=")
    two_word_flags+=("-p")
    local_nonpersistent_flags+=("--packaging=")
    flags+=("--type=")
    local_nonpersistent_flags+=("--type=")
    flags+=("--verbose")
    local_nonpersistent_flags+=("--verbose")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_create_team()
{
    last_command="jx_create_team"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--batch-mode")
    flags+=("-b")
    local_nonpersistent_flags+=("--batch-mode")
    flags+=("--headless")
    local_nonpersistent_flags+=("--headless")
    flags+=("--install-dependencies")
    local_nonpersistent_flags+=("--install-dependencies")
    flags+=("--member=")
    two_word_flags+=("-m")
    local_nonpersistent_flags+=("--member=")
    flags+=("--name=")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--name=")
    flags+=("--no-brew")
    local_nonpersistent_flags+=("--no-brew")
    flags+=("--verbose")
    local_nonpersistent_flags+=("--verbose")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_create_terraform()
{
    last_command="jx_create_terraform"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--batch-mode")
    flags+=("-b")
    local_nonpersistent_flags+=("--batch-mode")
    flags+=("--cleanup-temp-files")
    local_nonpersistent_flags+=("--cleanup-temp-files")
    flags+=("--cloud-environment-repo=")
    local_nonpersistent_flags+=("--cloud-environment-repo=")
    flags+=("--cluster=")
    two_word_flags+=("-c")
    local_nonpersistent_flags+=("--cluster=")
    flags+=("--default-admin-password=")
    local_nonpersistent_flags+=("--default-admin-password=")
    flags+=("--default-environment-prefix=")
    local_nonpersistent_flags+=("--default-environment-prefix=")
    flags+=("--docker-registry=")
    local_nonpersistent_flags+=("--docker-registry=")
    flags+=("--domain=")
    local_nonpersistent_flags+=("--domain=")
    flags+=("--draft-client-only")
    local_nonpersistent_flags+=("--draft-client-only")
    flags+=("--environment-git-owner=")
    local_nonpersistent_flags+=("--environment-git-owner=")
    flags+=("--exposecontroller-pathmode=")
    local_nonpersistent_flags+=("--exposecontroller-pathmode=")
    flags+=("--exposer=")
    local_nonpersistent_flags+=("--exposer=")
    flags+=("--external-ip=")
    local_nonpersistent_flags+=("--external-ip=")
    flags+=("--fork-git-repo=")
    two_word_flags+=("-f")
    local_nonpersistent_flags+=("--fork-git-repo=")
    flags+=("--git-api-token=")
    local_nonpersistent_flags+=("--git-api-token=")
    flags+=("--git-provider-url=")
    local_nonpersistent_flags+=("--git-provider-url=")
    flags+=("--git-username=")
    local_nonpersistent_flags+=("--git-username=")
    flags+=("--gke-disk-size=")
    local_nonpersistent_flags+=("--gke-disk-size=")
    flags+=("--gke-enable-autorepair")
    local_nonpersistent_flags+=("--gke-enable-autorepair")
    flags+=("--gke-enable-autoupgrade")
    local_nonpersistent_flags+=("--gke-enable-autoupgrade")
    flags+=("--gke-machine-type=")
    local_nonpersistent_flags+=("--gke-machine-type=")
    flags+=("--gke-max-num-nodes=")
    local_nonpersistent_flags+=("--gke-max-num-nodes=")
    flags+=("--gke-min-num-nodes=")
    local_nonpersistent_flags+=("--gke-min-num-nodes=")
    flags+=("--gke-project-id=")
    local_nonpersistent_flags+=("--gke-project-id=")
    flags+=("--gke-service-account=")
    local_nonpersistent_flags+=("--gke-service-account=")
    flags+=("--gke-zone=")
    local_nonpersistent_flags+=("--gke-zone=")
    flags+=("--global-tiller")
    local_nonpersistent_flags+=("--global-tiller")
    flags+=("--headless")
    local_nonpersistent_flags+=("--headless")
    flags+=("--helm-client-only")
    local_nonpersistent_flags+=("--helm-client-only")
    flags+=("--helm-tls")
    local_nonpersistent_flags+=("--helm-tls")
    flags+=("--helm3")
    local_nonpersistent_flags+=("--helm3")
    flags+=("--http=")
    local_nonpersistent_flags+=("--http=")
    flags+=("--ignore-terraform-warnings")
    local_nonpersistent_flags+=("--ignore-terraform-warnings")
    flags+=("--ingress-cluster-role=")
    local_nonpersistent_flags+=("--ingress-cluster-role=")
    flags+=("--ingress-deployment=")
    local_nonpersistent_flags+=("--ingress-deployment=")
    flags+=("--ingress-namespace=")
    local_nonpersistent_flags+=("--ingress-namespace=")
    flags+=("--ingress-service=")
    local_nonpersistent_flags+=("--ingress-service=")
    flags+=("--install-dependencies")
    local_nonpersistent_flags+=("--install-dependencies")
    flags+=("--install-only")
    local_nonpersistent_flags+=("--install-only")
    flags+=("--jx-environment=")
    local_nonpersistent_flags+=("--jx-environment=")
    flags+=("--keep-exposecontroller-job")
    local_nonpersistent_flags+=("--keep-exposecontroller-job")
    flags+=("--local-cloud-environment")
    local_nonpersistent_flags+=("--local-cloud-environment")
    flags+=("--local-helm-repo-name=")
    local_nonpersistent_flags+=("--local-helm-repo-name=")
    flags+=("--local-organisation-repository=")
    local_nonpersistent_flags+=("--local-organisation-repository=")
    flags+=("--namespace=")
    local_nonpersistent_flags+=("--namespace=")
    flags+=("--no-brew")
    local_nonpersistent_flags+=("--no-brew")
    flags+=("--no-default-environments")
    local_nonpersistent_flags+=("--no-default-environments")
    flags+=("--on-premise")
    local_nonpersistent_flags+=("--on-premise")
    flags+=("--organisation-name=")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--organisation-name=")
    flags+=("--prow")
    local_nonpersistent_flags+=("--prow")
    flags+=("--recreate-existing-draft-repos")
    local_nonpersistent_flags+=("--recreate-existing-draft-repos")
    flags+=("--register-local-helmrepo")
    local_nonpersistent_flags+=("--register-local-helmrepo")
    flags+=("--skip-ingress")
    local_nonpersistent_flags+=("--skip-ingress")
    flags+=("--skip-terraform-apply")
    local_nonpersistent_flags+=("--skip-terraform-apply")
    flags+=("--skip-tiller")
    local_nonpersistent_flags+=("--skip-tiller")
    flags+=("--tiller-cluster-role=")
    local_nonpersistent_flags+=("--tiller-cluster-role=")
    flags+=("--tiller-namespace=")
    local_nonpersistent_flags+=("--tiller-namespace=")
    flags+=("--timeout=")
    local_nonpersistent_flags+=("--timeout=")
    flags+=("--tls-acme=")
    local_nonpersistent_flags+=("--tls-acme=")
    flags+=("--user-cluster-role=")
    local_nonpersistent_flags+=("--user-cluster-role=")
    flags+=("--username=")
    local_nonpersistent_flags+=("--username=")
    flags+=("--verbose")
    local_nonpersistent_flags+=("--verbose")
    flags+=("--version=")
    local_nonpersistent_flags+=("--version=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_create_token_addon()
{
    last_command="jx_create_token_addon"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--api-token=")
    two_word_flags+=("-t")
    local_nonpersistent_flags+=("--api-token=")
    flags+=("--batch-mode")
    flags+=("-b")
    local_nonpersistent_flags+=("--batch-mode")
    flags+=("--headless")
    local_nonpersistent_flags+=("--headless")
    flags+=("--install-dependencies")
    local_nonpersistent_flags+=("--install-dependencies")
    flags+=("--kind=")
    two_word_flags+=("-k")
    local_nonpersistent_flags+=("--kind=")
    flags+=("--name=")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--name=")
    flags+=("--no-brew")
    local_nonpersistent_flags+=("--no-brew")
    flags+=("--password=")
    two_word_flags+=("-p")
    local_nonpersistent_flags+=("--password=")
    flags+=("--timeout=")
    local_nonpersistent_flags+=("--timeout=")
    flags+=("--url=")
    two_word_flags+=("-u")
    local_nonpersistent_flags+=("--url=")
    flags+=("--verbose")
    local_nonpersistent_flags+=("--verbose")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_create_token()
{
    last_command="jx_create_token"

    command_aliases=()

    commands=()
    commands+=("addon")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("login")
        aliashash["login"]="addon"
    fi

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()


    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_create_tracker_server()
{
    last_command="jx_create_tracker_server"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--name=")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--name=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_create_tracker_token()
{
    last_command="jx_create_tracker_token"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--api-token=")
    two_word_flags+=("-t")
    local_nonpersistent_flags+=("--api-token=")
    flags+=("--batch-mode")
    flags+=("-b")
    local_nonpersistent_flags+=("--batch-mode")
    flags+=("--headless")
    local_nonpersistent_flags+=("--headless")
    flags+=("--install-dependencies")
    local_nonpersistent_flags+=("--install-dependencies")
    flags+=("--name=")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--name=")
    flags+=("--no-brew")
    local_nonpersistent_flags+=("--no-brew")
    flags+=("--timeout=")
    local_nonpersistent_flags+=("--timeout=")
    flags+=("--url=")
    two_word_flags+=("-u")
    local_nonpersistent_flags+=("--url=")
    flags+=("--verbose")
    local_nonpersistent_flags+=("--verbose")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_create_tracker()
{
    last_command="jx_create_tracker"

    command_aliases=()

    commands=()
    commands+=("server")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("provider")
        aliashash["provider"]="server"
    fi
    commands+=("token")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("login")
        aliashash["login"]="token"
    fi

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()


    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_create_user()
{
    last_command="jx_create_user"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--batch-mode")
    flags+=("-b")
    local_nonpersistent_flags+=("--batch-mode")
    flags+=("--email=")
    two_word_flags+=("-e")
    local_nonpersistent_flags+=("--email=")
    flags+=("--headless")
    local_nonpersistent_flags+=("--headless")
    flags+=("--install-dependencies")
    local_nonpersistent_flags+=("--install-dependencies")
    flags+=("--login=")
    two_word_flags+=("-l")
    local_nonpersistent_flags+=("--login=")
    flags+=("--name=")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--name=")
    flags+=("--no-brew")
    local_nonpersistent_flags+=("--no-brew")
    flags+=("--verbose")
    local_nonpersistent_flags+=("--verbose")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_create()
{
    last_command="jx_create"

    command_aliases=()

    commands=()
    commands+=("addon")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("scm")
        aliashash["scm"]="addon"
    fi
    commands+=("archetype")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("arch")
        aliashash["arch"]="archetype"
    fi
    commands+=("branchpattern")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("branch pattern")
        aliashash["branch pattern"]="branchpattern"
    fi
    commands+=("camel")
    commands+=("chat")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("slackr")
        aliashash["slackr"]="chat"
    fi
    commands+=("cluster")
    commands+=("codeship")
    commands+=("devpod")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("buildpod")
        aliashash["buildpod"]="devpod"
        command_aliases+=("dpod")
        aliashash["dpod"]="devpod"
    fi
    commands+=("docs")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("doc")
        aliashash["doc"]="docs"
    fi
    commands+=("environment")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("env")
        aliashash["env"]="environment"
    fi
    commands+=("etc-hosts")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("etc_hosts")
        aliashash["etc_hosts"]="etc-hosts"
        command_aliases+=("etchosts")
        aliashash["etchosts"]="etc-hosts"
    fi
    commands+=("git")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("scm")
        aliashash["scm"]="git"
    fi
    commands+=("gke-service-account")
    commands+=("issue")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("env")
        aliashash["env"]="issue"
    fi
    commands+=("jenkins")
    commands+=("jhipster")
    commands+=("lile")
    commands+=("micro")
    commands+=("post")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("branch pattern")
        aliashash["branch pattern"]="post"
    fi
    commands+=("quickstart")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("arch")
        aliashash["arch"]="quickstart"
    fi
    commands+=("quickstartlocation")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("qsloc")
        aliashash["qsloc"]="quickstartlocation"
        command_aliases+=("quickstartloc")
        aliashash["quickstartloc"]="quickstartlocation"
        command_aliases+=("quickstartlocation")
        aliashash["quickstartlocation"]="quickstartlocation"
    fi
    commands+=("shell-completions")
    commands+=("spring")
    commands+=("team")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("env")
        aliashash["env"]="team"
    fi
    commands+=("terraform")
    commands+=("token")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("api-token")
        aliashash["api-token"]="token"
        command_aliases+=("password")
        aliashash["password"]="token"
        command_aliases+=("pwd")
        aliashash["pwd"]="token"
    fi
    commands+=("tracker")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("issue-tracker")
        aliashash["issue-tracker"]="tracker"
        command_aliases+=("jra")
        aliashash["jra"]="tracker"
        command_aliases+=("trello")
        aliashash["trello"]="tracker"
    fi
    commands+=("user")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("env")
        aliashash["env"]="user"
    fi

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()


    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_delete_addon_cloudbees()
{
    last_command="jx_delete_addon_cloudbees"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--purge")
    flags+=("-p")
    local_nonpersistent_flags+=("--purge")
    flags+=("--release=")
    two_word_flags+=("-r")
    local_nonpersistent_flags+=("--release=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_delete_addon_gitea()
{
    last_command="jx_delete_addon_gitea"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--purge")
    flags+=("-p")
    local_nonpersistent_flags+=("--purge")
    flags+=("--release=")
    two_word_flags+=("-r")
    local_nonpersistent_flags+=("--release=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_delete_addon()
{
    last_command="jx_delete_addon"

    command_aliases=()

    commands=()
    commands+=("cloudbees")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("cb")
        aliashash["cb"]="cloudbees"
        command_aliases+=("cdx")
        aliashash["cdx"]="cloudbees"
        command_aliases+=("cloudbee")
        aliashash["cloudbee"]="cloudbees"
    fi
    commands+=("gitea")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--purge")
    flags+=("-p")
    local_nonpersistent_flags+=("--purge")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_delete_application()
{
    last_command="jx_delete_application"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--all")
    flags+=("-a")
    local_nonpersistent_flags+=("--all")
    flags+=("--batch-mode")
    flags+=("-b")
    local_nonpersistent_flags+=("--batch-mode")
    flags+=("--filter=")
    two_word_flags+=("-f")
    local_nonpersistent_flags+=("--filter=")
    flags+=("--no-env")
    local_nonpersistent_flags+=("--no-env")
    flags+=("--no-merge")
    local_nonpersistent_flags+=("--no-merge")
    flags+=("--pull-request-poll-time=")
    local_nonpersistent_flags+=("--pull-request-poll-time=")
    flags+=("--timeout=")
    two_word_flags+=("-t")
    local_nonpersistent_flags+=("--timeout=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_delete_chat_server()
{
    last_command="jx_delete_chat_server"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--ignore-missing")
    flags+=("-i")
    local_nonpersistent_flags+=("--ignore-missing")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_delete_chat_token()
{
    last_command="jx_delete_chat_token"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--name=")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--name=")
    flags+=("--url=")
    two_word_flags+=("-u")
    local_nonpersistent_flags+=("--url=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_delete_chat()
{
    last_command="jx_delete_chat"

    command_aliases=()

    commands=()
    commands+=("server")
    commands+=("token")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("api-token")
        aliashash["api-token"]="token"
    fi

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()


    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_delete_contexts()
{
    last_command="jx_delete_contexts"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--all")
    flags+=("-a")
    local_nonpersistent_flags+=("--all")
    flags+=("--filter=")
    two_word_flags+=("-f")
    local_nonpersistent_flags+=("--filter=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_delete_devpod()
{
    last_command="jx_delete_devpod"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()


    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_delete_environment()
{
    last_command="jx_delete_environment"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--namespace")
    flags+=("-n")
    local_nonpersistent_flags+=("--namespace")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_delete_git_server()
{
    last_command="jx_delete_git_server"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--ignore-missing")
    flags+=("-i")
    local_nonpersistent_flags+=("--ignore-missing")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_delete_git_token()
{
    last_command="jx_delete_git_token"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--name=")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--name=")
    flags+=("--url=")
    two_word_flags+=("-u")
    local_nonpersistent_flags+=("--url=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_delete_git()
{
    last_command="jx_delete_git"

    command_aliases=()

    commands=()
    commands+=("server")
    commands+=("token")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("api-token")
        aliashash["api-token"]="token"
    fi

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()


    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_delete_jenkins_user()
{
    last_command="jx_delete_jenkins_user"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--name=")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--name=")
    flags+=("--url=")
    two_word_flags+=("-u")
    local_nonpersistent_flags+=("--url=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_delete_jenkins()
{
    last_command="jx_delete_jenkins"

    command_aliases=()

    commands=()
    commands+=("user")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("token")
        aliashash["token"]="user"
    fi

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()


    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_delete_post()
{
    last_command="jx_delete_post"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--batch-mode")
    flags+=("-b")
    local_nonpersistent_flags+=("--batch-mode")
    flags+=("--headless")
    local_nonpersistent_flags+=("--headless")
    flags+=("--install-dependencies")
    local_nonpersistent_flags+=("--install-dependencies")
    flags+=("--name=")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--name=")
    flags+=("--no-brew")
    local_nonpersistent_flags+=("--no-brew")
    flags+=("--verbose")
    local_nonpersistent_flags+=("--verbose")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_delete_preview()
{
    last_command="jx_delete_preview"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--batch-mode")
    flags+=("-b")
    local_nonpersistent_flags+=("--batch-mode")
    flags+=("--cluster=")
    two_word_flags+=("-c")
    local_nonpersistent_flags+=("--cluster=")
    flags+=("--dev-namespace=")
    local_nonpersistent_flags+=("--dev-namespace=")
    flags+=("--dir=")
    local_nonpersistent_flags+=("--dir=")
    flags+=("--headless")
    local_nonpersistent_flags+=("--headless")
    flags+=("--install-dependencies")
    local_nonpersistent_flags+=("--install-dependencies")
    flags+=("--label=")
    two_word_flags+=("-l")
    local_nonpersistent_flags+=("--label=")
    flags+=("--name=")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--name=")
    flags+=("--namespace=")
    local_nonpersistent_flags+=("--namespace=")
    flags+=("--no-brew")
    local_nonpersistent_flags+=("--no-brew")
    flags+=("--post-preview-job-timeout=")
    local_nonpersistent_flags+=("--post-preview-job-timeout=")
    flags+=("--post-preview-poll-time=")
    local_nonpersistent_flags+=("--post-preview-poll-time=")
    flags+=("--pr=")
    local_nonpersistent_flags+=("--pr=")
    flags+=("--pr-url=")
    local_nonpersistent_flags+=("--pr-url=")
    flags+=("--source-ref=")
    local_nonpersistent_flags+=("--source-ref=")
    flags+=("--source-url=")
    two_word_flags+=("-s")
    local_nonpersistent_flags+=("--source-url=")
    flags+=("--verbose")
    local_nonpersistent_flags+=("--verbose")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_delete_quickstartlocation()
{
    last_command="jx_delete_quickstartlocation"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--batch-mode")
    flags+=("-b")
    local_nonpersistent_flags+=("--batch-mode")
    flags+=("--headless")
    local_nonpersistent_flags+=("--headless")
    flags+=("--install-dependencies")
    local_nonpersistent_flags+=("--install-dependencies")
    flags+=("--no-brew")
    local_nonpersistent_flags+=("--no-brew")
    flags+=("--owner=")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--owner=")
    flags+=("--url=")
    two_word_flags+=("-u")
    local_nonpersistent_flags+=("--url=")
    flags+=("--verbose")
    local_nonpersistent_flags+=("--verbose")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_delete_repo()
{
    last_command="jx_delete_repo"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--all")
    flags+=("-a")
    local_nonpersistent_flags+=("--all")
    flags+=("--batch-mode")
    flags+=("-b")
    local_nonpersistent_flags+=("--batch-mode")
    flags+=("--filter=")
    two_word_flags+=("-f")
    local_nonpersistent_flags+=("--filter=")
    flags+=("--git-host=")
    two_word_flags+=("-g")
    local_nonpersistent_flags+=("--git-host=")
    flags+=("--github")
    local_nonpersistent_flags+=("--github")
    flags+=("--name=")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--name=")
    flags+=("--org=")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--org=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_delete_team()
{
    last_command="jx_delete_team"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--all")
    flags+=("-a")
    local_nonpersistent_flags+=("--all")
    flags+=("--batch-mode")
    flags+=("-b")
    local_nonpersistent_flags+=("--batch-mode")
    flags+=("--filter=")
    two_word_flags+=("-f")
    local_nonpersistent_flags+=("--filter=")
    flags+=("--headless")
    local_nonpersistent_flags+=("--headless")
    flags+=("--install-dependencies")
    local_nonpersistent_flags+=("--install-dependencies")
    flags+=("--no-brew")
    local_nonpersistent_flags+=("--no-brew")
    flags+=("--verbose")
    local_nonpersistent_flags+=("--verbose")
    flags+=("--yes")
    flags+=("-y")
    local_nonpersistent_flags+=("--yes")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_delete_token_addon()
{
    last_command="jx_delete_token_addon"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--kind=")
    two_word_flags+=("-k")
    local_nonpersistent_flags+=("--kind=")
    flags+=("--name=")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--name=")
    flags+=("--url=")
    two_word_flags+=("-u")
    local_nonpersistent_flags+=("--url=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_delete_token()
{
    last_command="jx_delete_token"

    command_aliases=()

    commands=()
    commands+=("addon")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()


    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_delete_tracker_server()
{
    last_command="jx_delete_tracker_server"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--ignore-missing")
    flags+=("-i")
    local_nonpersistent_flags+=("--ignore-missing")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_delete_tracker_token()
{
    last_command="jx_delete_tracker_token"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--name=")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--name=")
    flags+=("--url=")
    two_word_flags+=("-u")
    local_nonpersistent_flags+=("--url=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_delete_tracker()
{
    last_command="jx_delete_tracker"

    command_aliases=()

    commands=()
    commands+=("server")
    commands+=("token")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("api-token")
        aliashash["api-token"]="token"
    fi

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()


    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_delete_user()
{
    last_command="jx_delete_user"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--all")
    flags+=("-a")
    local_nonpersistent_flags+=("--all")
    flags+=("--batch-mode")
    flags+=("-b")
    local_nonpersistent_flags+=("--batch-mode")
    flags+=("--filter=")
    two_word_flags+=("-f")
    local_nonpersistent_flags+=("--filter=")
    flags+=("--headless")
    local_nonpersistent_flags+=("--headless")
    flags+=("--install-dependencies")
    local_nonpersistent_flags+=("--install-dependencies")
    flags+=("--no-brew")
    local_nonpersistent_flags+=("--no-brew")
    flags+=("--verbose")
    local_nonpersistent_flags+=("--verbose")
    flags+=("--yes")
    flags+=("-y")
    local_nonpersistent_flags+=("--yes")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_delete()
{
    last_command="jx_delete"

    command_aliases=()

    commands=()
    commands+=("addon")
    commands+=("application")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("app")
        aliashash["app"]="application"
        command_aliases+=("applications")
        aliashash["applications"]="application"
        command_aliases+=("apps")
        aliashash["apps"]="application"
    fi
    commands+=("chat")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("slack")
        aliashash["slack"]="chat"
    fi
    commands+=("contexts")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("context")
        aliashash["context"]="contexts"
        command_aliases+=("ctx")
        aliashash["ctx"]="contexts"
    fi
    commands+=("devpod")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("buildpod")
        aliashash["buildpod"]="devpod"
        command_aliases+=("buildpods")
        aliashash["buildpods"]="devpod"
        command_aliases+=("devpods")
        aliashash["devpods"]="devpod"
    fi
    commands+=("environment")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("env")
        aliashash["env"]="environment"
    fi
    commands+=("git")
    commands+=("jenkins")
    commands+=("post")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("branch pattern")
        aliashash["branch pattern"]="post"
    fi
    commands+=("preview")
    commands+=("quickstartlocation")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("qsloc")
        aliashash["qsloc"]="quickstartlocation"
        command_aliases+=("quickstartloc")
        aliashash["quickstartloc"]="quickstartlocation"
        command_aliases+=("quickstartlocation")
        aliashash["quickstartlocation"]="quickstartlocation"
    fi
    commands+=("repo")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("repository")
        aliashash["repository"]="repo"
    fi
    commands+=("team")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("teams")
        aliashash["teams"]="team"
    fi
    commands+=("token")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("api-token")
        aliashash["api-token"]="token"
    fi
    commands+=("tracker")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("issue-tracker")
        aliashash["issue-tracker"]="tracker"
        command_aliases+=("jra")
        aliashash["jra"]="tracker"
        command_aliases+=("trello")
        aliashash["trello"]="tracker"
    fi
    commands+=("user")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("users")
        aliashash["users"]="user"
    fi

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()


    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_edit_addon()
{
    last_command="jx_edit_addon"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--enabled=")
    two_word_flags+=("-e")
    local_nonpersistent_flags+=("--enabled=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_edit_branchpattern()
{
    last_command="jx_edit_branchpattern"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--batch-mode")
    flags+=("-b")
    local_nonpersistent_flags+=("--batch-mode")
    flags+=("--headless")
    local_nonpersistent_flags+=("--headless")
    flags+=("--install-dependencies")
    local_nonpersistent_flags+=("--install-dependencies")
    flags+=("--no-brew")
    local_nonpersistent_flags+=("--no-brew")
    flags+=("--verbose")
    local_nonpersistent_flags+=("--verbose")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_edit_buildpack()
{
    last_command="jx_edit_buildpack"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--batch-mode")
    flags+=("-b")
    local_nonpersistent_flags+=("--batch-mode")
    flags+=("--headless")
    local_nonpersistent_flags+=("--headless")
    flags+=("--install-dependencies")
    local_nonpersistent_flags+=("--install-dependencies")
    flags+=("--no-brew")
    local_nonpersistent_flags+=("--no-brew")
    flags+=("--ref=")
    two_word_flags+=("-r")
    local_nonpersistent_flags+=("--ref=")
    flags+=("--url=")
    two_word_flags+=("-u")
    local_nonpersistent_flags+=("--url=")
    flags+=("--verbose")
    local_nonpersistent_flags+=("--verbose")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_edit_config()
{
    last_command="jx_edit_config"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--dir=")
    two_word_flags+=("-d")
    local_nonpersistent_flags+=("--dir=")
    flags+=("--kind=")
    two_word_flags+=("-k")
    local_nonpersistent_flags+=("--kind=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_edit_environment()
{
    last_command="jx_edit_environment"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--branches=")
    local_nonpersistent_flags+=("--branches=")
    flags+=("--cluster=")
    two_word_flags+=("-c")
    local_nonpersistent_flags+=("--cluster=")
    flags+=("--domain=")
    local_nonpersistent_flags+=("--domain=")
    flags+=("--env-job-credentials=")
    local_nonpersistent_flags+=("--env-job-credentials=")
    flags+=("--exposer=")
    local_nonpersistent_flags+=("--exposer=")
    flags+=("--fork-git-repo=")
    two_word_flags+=("-f")
    local_nonpersistent_flags+=("--fork-git-repo=")
    flags+=("--git-api-token=")
    local_nonpersistent_flags+=("--git-api-token=")
    flags+=("--git-provider-url=")
    local_nonpersistent_flags+=("--git-provider-url=")
    flags+=("--git-ref=")
    two_word_flags+=("-r")
    local_nonpersistent_flags+=("--git-ref=")
    flags+=("--git-url=")
    two_word_flags+=("-g")
    local_nonpersistent_flags+=("--git-url=")
    flags+=("--git-username=")
    local_nonpersistent_flags+=("--git-username=")
    flags+=("--http=")
    local_nonpersistent_flags+=("--http=")
    flags+=("--keep-exposecontroller-job")
    local_nonpersistent_flags+=("--keep-exposecontroller-job")
    flags+=("--label=")
    two_word_flags+=("-l")
    local_nonpersistent_flags+=("--label=")
    flags+=("--name=")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--name=")
    flags+=("--namespace=")
    two_word_flags+=("-s")
    local_nonpersistent_flags+=("--namespace=")
    flags+=("--no-gitops")
    flags+=("-x")
    local_nonpersistent_flags+=("--no-gitops")
    flags+=("--order=")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--order=")
    flags+=("--prefix=")
    local_nonpersistent_flags+=("--prefix=")
    flags+=("--promotion=")
    two_word_flags+=("-p")
    local_nonpersistent_flags+=("--promotion=")
    flags+=("--tls-acme=")
    local_nonpersistent_flags+=("--tls-acme=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_edit_helmbin()
{
    last_command="jx_edit_helmbin"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--batch-mode")
    flags+=("-b")
    local_nonpersistent_flags+=("--batch-mode")
    flags+=("--headless")
    local_nonpersistent_flags+=("--headless")
    flags+=("--install-dependencies")
    local_nonpersistent_flags+=("--install-dependencies")
    flags+=("--no-brew")
    local_nonpersistent_flags+=("--no-brew")
    flags+=("--verbose")
    local_nonpersistent_flags+=("--verbose")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_edit()
{
    last_command="jx_edit"

    command_aliases=()

    commands=()
    commands+=("addon")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("addons")
        aliashash["addons"]="addon"
    fi
    commands+=("branchpattern")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("branch pattern")
        aliashash["branch pattern"]="branchpattern"
    fi
    commands+=("buildpack")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("build pack")
        aliashash["build pack"]="buildpack"
        command_aliases+=("pack")
        aliashash["pack"]="buildpack"
    fi
    commands+=("config")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("project")
        aliashash["project"]="config"
    fi
    commands+=("environment")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("env")
        aliashash["env"]="environment"
    fi
    commands+=("helmbin")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("helm")
        aliashash["helm"]="helmbin"
    fi

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()


    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_environment()
{
    last_command="jx_environment"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--batch-mode")
    flags+=("-b")
    local_nonpersistent_flags+=("--batch-mode")
    flags+=("--headless")
    local_nonpersistent_flags+=("--headless")
    flags+=("--install-dependencies")
    local_nonpersistent_flags+=("--install-dependencies")
    flags+=("--no-brew")
    local_nonpersistent_flags+=("--no-brew")
    flags+=("--verbose")
    local_nonpersistent_flags+=("--verbose")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_gc_activities()
{
    last_command="jx_gc_activities"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--revision-history-limit=")
    local_nonpersistent_flags+=("--revision-history-limit=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_gc_gke()
{
    last_command="jx_gc_gke"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()


    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_gc_helm()
{
    last_command="jx_gc_helm"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--batch-mode")
    flags+=("-b")
    local_nonpersistent_flags+=("--batch-mode")
    flags+=("--dry-run")
    local_nonpersistent_flags+=("--dry-run")
    flags+=("--headless")
    local_nonpersistent_flags+=("--headless")
    flags+=("--install-dependencies")
    local_nonpersistent_flags+=("--install-dependencies")
    flags+=("--no-backup")
    local_nonpersistent_flags+=("--no-backup")
    flags+=("--no-brew")
    local_nonpersistent_flags+=("--no-brew")
    flags+=("--output-dir=")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--output-dir=")
    flags+=("--revision-history-limit=")
    local_nonpersistent_flags+=("--revision-history-limit=")
    flags+=("--verbose")
    local_nonpersistent_flags+=("--verbose")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_gc_previews()
{
    last_command="jx_gc_previews"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--batch-mode")
    flags+=("-b")
    local_nonpersistent_flags+=("--batch-mode")
    flags+=("--headless")
    local_nonpersistent_flags+=("--headless")
    flags+=("--install-dependencies")
    local_nonpersistent_flags+=("--install-dependencies")
    flags+=("--no-brew")
    local_nonpersistent_flags+=("--no-brew")
    flags+=("--verbose")
    local_nonpersistent_flags+=("--verbose")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_gc()
{
    last_command="jx_gc"

    command_aliases=()

    commands=()
    commands+=("activities")
    commands+=("gke")
    commands+=("helm")
    commands+=("previews")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()


    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_get_activities()
{
    last_command="jx_get_activities"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--build=")
    two_word_flags+=("-b")
    local_nonpersistent_flags+=("--build=")
    flags+=("--filter=")
    two_word_flags+=("-f")
    local_nonpersistent_flags+=("--filter=")
    flags+=("--watch")
    flags+=("-w")
    local_nonpersistent_flags+=("--watch")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_get_addons()
{
    last_command="jx_get_addons"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()


    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_get_applications()
{
    last_command="jx_get_applications"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--env=")
    two_word_flags+=("-e")
    local_nonpersistent_flags+=("--env=")
    flags+=("--namespace=")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--namespace=")
    flags+=("--pod")
    flags+=("-p")
    local_nonpersistent_flags+=("--pod")
    flags+=("--preview")
    flags+=("-w")
    local_nonpersistent_flags+=("--preview")
    flags+=("--url")
    flags+=("-u")
    local_nonpersistent_flags+=("--url")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_get_aws()
{
    last_command="jx_get_aws"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--output=")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--output=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_get_branchpattern()
{
    last_command="jx_get_branchpattern"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--output=")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--output=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_get_build_log()
{
    last_command="jx_get_build_log"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--build=")
    two_word_flags+=("-b")
    local_nonpersistent_flags+=("--build=")
    flags+=("--filter=")
    two_word_flags+=("-f")
    local_nonpersistent_flags+=("--filter=")
    flags+=("--tail")
    flags+=("-t")
    local_nonpersistent_flags+=("--tail")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_get_build()
{
    last_command="jx_get_build"

    command_aliases=()

    commands=()
    commands+=("log")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("logs")
        aliashash["logs"]="log"
    fi

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()


    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_get_buildpack()
{
    last_command="jx_get_buildpack"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--output=")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--output=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_get_chat()
{
    last_command="jx_get_chat"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--kind=")
    two_word_flags+=("-k")
    local_nonpersistent_flags+=("--kind=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_get_config()
{
    last_command="jx_get_config"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--dir=")
    two_word_flags+=("-d")
    local_nonpersistent_flags+=("--dir=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_get_cve()
{
    last_command="jx_get_cve"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--batch-mode")
    flags+=("-b")
    local_nonpersistent_flags+=("--batch-mode")
    flags+=("--environment=")
    two_word_flags+=("-e")
    local_nonpersistent_flags+=("--environment=")
    flags+=("--headless")
    local_nonpersistent_flags+=("--headless")
    flags+=("--image-id=")
    local_nonpersistent_flags+=("--image-id=")
    flags+=("--image-name=")
    local_nonpersistent_flags+=("--image-name=")
    flags+=("--install-dependencies")
    local_nonpersistent_flags+=("--install-dependencies")
    flags+=("--no-brew")
    local_nonpersistent_flags+=("--no-brew")
    flags+=("--verbose")
    local_nonpersistent_flags+=("--verbose")
    flags+=("--version=")
    local_nonpersistent_flags+=("--version=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_get_devpod()
{
    last_command="jx_get_devpod"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()


    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_get_environments()
{
    last_command="jx_get_environments"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--output=")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--output=")
    flags+=("--promote=")
    two_word_flags+=("-p")
    local_nonpersistent_flags+=("--promote=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_get_git()
{
    last_command="jx_get_git"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()


    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_get_helmbin()
{
    last_command="jx_get_helmbin"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--output=")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--output=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_get_issue()
{
    last_command="jx_get_issue"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--dir=")
    two_word_flags+=("-d")
    local_nonpersistent_flags+=("--dir=")
    flags+=("--id=")
    two_word_flags+=("-i")
    local_nonpersistent_flags+=("--id=")
    flags+=("--output=")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--output=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_get_issues()
{
    last_command="jx_get_issues"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--dir=")
    two_word_flags+=("-d")
    local_nonpersistent_flags+=("--dir=")
    flags+=("--output=")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--output=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_get_pipelines()
{
    last_command="jx_get_pipelines"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--output=")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--output=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_get_post()
{
    last_command="jx_get_post"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--batch-mode")
    flags+=("-b")
    local_nonpersistent_flags+=("--batch-mode")
    flags+=("--headless")
    local_nonpersistent_flags+=("--headless")
    flags+=("--install-dependencies")
    local_nonpersistent_flags+=("--install-dependencies")
    flags+=("--no-brew")
    local_nonpersistent_flags+=("--no-brew")
    flags+=("--verbose")
    local_nonpersistent_flags+=("--verbose")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_get_previews()
{
    last_command="jx_get_previews"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--current")
    flags+=("-c")
    local_nonpersistent_flags+=("--current")
    flags+=("--output=")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--output=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_get_quickstartlocations()
{
    last_command="jx_get_quickstartlocations"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--output=")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--output=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_get_teams()
{
    last_command="jx_get_teams"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--output=")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--output=")
    flags+=("--pending")
    flags+=("-p")
    local_nonpersistent_flags+=("--pending")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_get_token_addon()
{
    last_command="jx_get_token_addon"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--kind=")
    two_word_flags+=("-k")
    local_nonpersistent_flags+=("--kind=")
    flags+=("--name=")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--name=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_get_token()
{
    last_command="jx_get_token"

    command_aliases=()

    commands=()
    commands+=("addon")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("issue-tracker")
        aliashash["issue-tracker"]="addon"
    fi

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()


    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_get_tracker()
{
    last_command="jx_get_tracker"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--kind=")
    two_word_flags+=("-k")
    local_nonpersistent_flags+=("--kind=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_get_urls()
{
    last_command="jx_get_urls"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--env=")
    two_word_flags+=("-e")
    local_nonpersistent_flags+=("--env=")
    flags+=("--namespace=")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--namespace=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_get_users()
{
    last_command="jx_get_users"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--output=")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--output=")
    flags+=("--pending")
    flags+=("-p")
    local_nonpersistent_flags+=("--pending")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_get()
{
    last_command="jx_get"

    command_aliases=()

    commands=()
    commands+=("activities")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("act")
        aliashash["act"]="activities"
        command_aliases+=("activity")
        aliashash["activity"]="activities"
    fi
    commands+=("addons")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("add-on")
        aliashash["add-on"]="addons"
        command_aliases+=("addon")
        aliashash["addon"]="addons"
    fi
    commands+=("applications")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("app")
        aliashash["app"]="applications"
        command_aliases+=("apps")
        aliashash["apps"]="applications"
        command_aliases+=("version")
        aliashash["version"]="applications"
        command_aliases+=("versions")
        aliashash["versions"]="applications"
    fi
    commands+=("aws")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("aws")
        aliashash["aws"]="aws"
    fi
    commands+=("branchpattern")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("branch pattern")
        aliashash["branch pattern"]="branchpattern"
    fi
    commands+=("build")
    commands+=("buildpack")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("build pack")
        aliashash["build pack"]="buildpack"
        command_aliases+=("pack")
        aliashash["pack"]="buildpack"
    fi
    commands+=("chat")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("slack")
        aliashash["slack"]="chat"
    fi
    commands+=("config")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("url")
        aliashash["url"]="config"
    fi
    commands+=("cve")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("cves")
        aliashash["cves"]="cve"
    fi
    commands+=("devpod")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("buildpod")
        aliashash["buildpod"]="devpod"
        command_aliases+=("buildpods")
        aliashash["buildpods"]="devpod"
        command_aliases+=("devpods")
        aliashash["devpods"]="devpod"
    fi
    commands+=("environments")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("env")
        aliashash["env"]="environments"
        command_aliases+=("environment")
        aliashash["environment"]="environments"
        command_aliases+=("envs")
        aliashash["envs"]="environments"
    fi
    commands+=("git")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("gitserver")
        aliashash["gitserver"]="git"
    fi
    commands+=("helmbin")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("helm")
        aliashash["helm"]="helmbin"
    fi
    commands+=("issue")
    commands+=("issues")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("jira")
        aliashash["jira"]="issues"
    fi
    commands+=("pipelines")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("pipe")
        aliashash["pipe"]="pipelines"
        command_aliases+=("pipeline")
        aliashash["pipeline"]="pipelines"
        command_aliases+=("pipes")
        aliashash["pipes"]="pipelines"
    fi
    commands+=("post")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("branch pattern")
        aliashash["branch pattern"]="post"
    fi
    commands+=("previews")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("preview")
        aliashash["preview"]="previews"
    fi
    commands+=("quickstartlocations")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("qsloc")
        aliashash["qsloc"]="quickstartlocations"
        command_aliases+=("quickstartloc")
        aliashash["quickstartloc"]="quickstartlocations"
        command_aliases+=("quickstartlocation")
        aliashash["quickstartlocation"]="quickstartlocations"
    fi
    commands+=("teams")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("team")
        aliashash["team"]="teams"
    fi
    commands+=("token")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("api-token")
        aliashash["api-token"]="token"
    fi
    commands+=("tracker")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("issue-tracker")
        aliashash["issue-tracker"]="tracker"
    fi
    commands+=("urls")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("url")
        aliashash["url"]="urls"
    fi
    commands+=("users")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("user")
        aliashash["user"]="users"
    fi

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()


    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_import()
{
    last_command="jx_import"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--all")
    local_nonpersistent_flags+=("--all")
    flags+=("--batch-mode")
    flags+=("-b")
    local_nonpersistent_flags+=("--batch-mode")
    flags+=("--branches=")
    local_nonpersistent_flags+=("--branches=")
    flags+=("--credentials=")
    two_word_flags+=("-c")
    local_nonpersistent_flags+=("--credentials=")
    flags+=("--default-owner=")
    local_nonpersistent_flags+=("--default-owner=")
    flags+=("--dry-run")
    local_nonpersistent_flags+=("--dry-run")
    flags+=("--filter=")
    local_nonpersistent_flags+=("--filter=")
    flags+=("--git-api-token=")
    local_nonpersistent_flags+=("--git-api-token=")
    flags+=("--git-provider-url=")
    local_nonpersistent_flags+=("--git-provider-url=")
    flags+=("--git-username=")
    local_nonpersistent_flags+=("--git-username=")
    flags+=("--github")
    local_nonpersistent_flags+=("--github")
    flags+=("--headless")
    local_nonpersistent_flags+=("--headless")
    flags+=("--import-commit-message=")
    local_nonpersistent_flags+=("--import-commit-message=")
    flags+=("--install-dependencies")
    local_nonpersistent_flags+=("--install-dependencies")
    flags+=("--jenkinsfile=")
    two_word_flags+=("-j")
    local_nonpersistent_flags+=("--jenkinsfile=")
    flags+=("--list-packs")
    local_nonpersistent_flags+=("--list-packs")
    flags+=("--name=")
    local_nonpersistent_flags+=("--name=")
    flags+=("--no-brew")
    local_nonpersistent_flags+=("--no-brew")
    flags+=("--no-draft")
    local_nonpersistent_flags+=("--no-draft")
    flags+=("--no-jenkinsfile")
    local_nonpersistent_flags+=("--no-jenkinsfile")
    flags+=("--org=")
    local_nonpersistent_flags+=("--org=")
    flags+=("--pack=")
    local_nonpersistent_flags+=("--pack=")
    flags+=("--url=")
    two_word_flags+=("-u")
    local_nonpersistent_flags+=("--url=")
    flags+=("--verbose")
    local_nonpersistent_flags+=("--verbose")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_init()
{
    last_command="jx_init"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--batch-mode")
    flags+=("-b")
    local_nonpersistent_flags+=("--batch-mode")
    flags+=("--domain=")
    local_nonpersistent_flags+=("--domain=")
    flags+=("--draft-client-only")
    local_nonpersistent_flags+=("--draft-client-only")
    flags+=("--external-ip=")
    local_nonpersistent_flags+=("--external-ip=")
    flags+=("--global-tiller")
    local_nonpersistent_flags+=("--global-tiller")
    flags+=("--headless")
    local_nonpersistent_flags+=("--headless")
    flags+=("--helm-client-only")
    local_nonpersistent_flags+=("--helm-client-only")
    flags+=("--helm3")
    local_nonpersistent_flags+=("--helm3")
    flags+=("--ingress-cluster-role=")
    local_nonpersistent_flags+=("--ingress-cluster-role=")
    flags+=("--ingress-deployment=")
    local_nonpersistent_flags+=("--ingress-deployment=")
    flags+=("--ingress-namespace=")
    local_nonpersistent_flags+=("--ingress-namespace=")
    flags+=("--ingress-service=")
    local_nonpersistent_flags+=("--ingress-service=")
    flags+=("--install-dependencies")
    local_nonpersistent_flags+=("--install-dependencies")
    flags+=("--namespace=")
    local_nonpersistent_flags+=("--namespace=")
    flags+=("--no-brew")
    local_nonpersistent_flags+=("--no-brew")
    flags+=("--on-premise")
    local_nonpersistent_flags+=("--on-premise")
    flags+=("--provider=")
    local_nonpersistent_flags+=("--provider=")
    flags+=("--recreate-existing-draft-repos")
    local_nonpersistent_flags+=("--recreate-existing-draft-repos")
    flags+=("--skip-ingress")
    local_nonpersistent_flags+=("--skip-ingress")
    flags+=("--skip-tiller")
    local_nonpersistent_flags+=("--skip-tiller")
    flags+=("--tiller-cluster-role=")
    local_nonpersistent_flags+=("--tiller-cluster-role=")
    flags+=("--tiller-namespace=")
    local_nonpersistent_flags+=("--tiller-namespace=")
    flags+=("--user-cluster-role=")
    local_nonpersistent_flags+=("--user-cluster-role=")
    flags+=("--username=")
    local_nonpersistent_flags+=("--username=")
    flags+=("--verbose")
    local_nonpersistent_flags+=("--verbose")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_install()
{
    last_command="jx_install"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--batch-mode")
    flags+=("-b")
    local_nonpersistent_flags+=("--batch-mode")
    flags+=("--cleanup-temp-files")
    local_nonpersistent_flags+=("--cleanup-temp-files")
    flags+=("--cloud-environment-repo=")
    local_nonpersistent_flags+=("--cloud-environment-repo=")
    flags+=("--default-admin-password=")
    local_nonpersistent_flags+=("--default-admin-password=")
    flags+=("--default-environment-prefix=")
    local_nonpersistent_flags+=("--default-environment-prefix=")
    flags+=("--docker-registry=")
    local_nonpersistent_flags+=("--docker-registry=")
    flags+=("--domain=")
    local_nonpersistent_flags+=("--domain=")
    flags+=("--draft-client-only")
    local_nonpersistent_flags+=("--draft-client-only")
    flags+=("--environment-git-owner=")
    local_nonpersistent_flags+=("--environment-git-owner=")
    flags+=("--exposecontroller-pathmode=")
    local_nonpersistent_flags+=("--exposecontroller-pathmode=")
    flags+=("--exposer=")
    local_nonpersistent_flags+=("--exposer=")
    flags+=("--external-ip=")
    local_nonpersistent_flags+=("--external-ip=")
    flags+=("--git-api-token=")
    local_nonpersistent_flags+=("--git-api-token=")
    flags+=("--git-provider-url=")
    local_nonpersistent_flags+=("--git-provider-url=")
    flags+=("--git-username=")
    local_nonpersistent_flags+=("--git-username=")
    flags+=("--global-tiller")
    local_nonpersistent_flags+=("--global-tiller")
    flags+=("--headless")
    local_nonpersistent_flags+=("--headless")
    flags+=("--helm-client-only")
    local_nonpersistent_flags+=("--helm-client-only")
    flags+=("--helm-tls")
    local_nonpersistent_flags+=("--helm-tls")
    flags+=("--helm3")
    local_nonpersistent_flags+=("--helm3")
    flags+=("--http=")
    local_nonpersistent_flags+=("--http=")
    flags+=("--ingress-cluster-role=")
    local_nonpersistent_flags+=("--ingress-cluster-role=")
    flags+=("--ingress-deployment=")
    local_nonpersistent_flags+=("--ingress-deployment=")
    flags+=("--ingress-namespace=")
    local_nonpersistent_flags+=("--ingress-namespace=")
    flags+=("--ingress-service=")
    local_nonpersistent_flags+=("--ingress-service=")
    flags+=("--install-dependencies")
    local_nonpersistent_flags+=("--install-dependencies")
    flags+=("--install-only")
    local_nonpersistent_flags+=("--install-only")
    flags+=("--keep-exposecontroller-job")
    local_nonpersistent_flags+=("--keep-exposecontroller-job")
    flags+=("--local-cloud-environment")
    local_nonpersistent_flags+=("--local-cloud-environment")
    flags+=("--local-helm-repo-name=")
    local_nonpersistent_flags+=("--local-helm-repo-name=")
    flags+=("--namespace=")
    local_nonpersistent_flags+=("--namespace=")
    flags+=("--no-brew")
    local_nonpersistent_flags+=("--no-brew")
    flags+=("--no-default-environments")
    local_nonpersistent_flags+=("--no-default-environments")
    flags+=("--on-premise")
    local_nonpersistent_flags+=("--on-premise")
    flags+=("--provider=")
    local_nonpersistent_flags+=("--provider=")
    flags+=("--prow")
    local_nonpersistent_flags+=("--prow")
    flags+=("--recreate-existing-draft-repos")
    local_nonpersistent_flags+=("--recreate-existing-draft-repos")
    flags+=("--register-local-helmrepo")
    local_nonpersistent_flags+=("--register-local-helmrepo")
    flags+=("--skip-ingress")
    local_nonpersistent_flags+=("--skip-ingress")
    flags+=("--skip-tiller")
    local_nonpersistent_flags+=("--skip-tiller")
    flags+=("--tiller-cluster-role=")
    local_nonpersistent_flags+=("--tiller-cluster-role=")
    flags+=("--tiller-namespace=")
    local_nonpersistent_flags+=("--tiller-namespace=")
    flags+=("--timeout=")
    local_nonpersistent_flags+=("--timeout=")
    flags+=("--tls-acme=")
    local_nonpersistent_flags+=("--tls-acme=")
    flags+=("--user-cluster-role=")
    local_nonpersistent_flags+=("--user-cluster-role=")
    flags+=("--username=")
    local_nonpersistent_flags+=("--username=")
    flags+=("--verbose")
    local_nonpersistent_flags+=("--verbose")
    flags+=("--version=")
    local_nonpersistent_flags+=("--version=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_logs()
{
    last_command="jx_logs"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--container=")
    two_word_flags+=("-c")
    local_nonpersistent_flags+=("--container=")
    flags+=("--edit")
    flags+=("-d")
    local_nonpersistent_flags+=("--edit")
    flags+=("--env=")
    two_word_flags+=("-e")
    local_nonpersistent_flags+=("--env=")
    flags+=("--filter=")
    two_word_flags+=("-f")
    local_nonpersistent_flags+=("--filter=")
    flags+=("--label=")
    two_word_flags+=("-l")
    local_nonpersistent_flags+=("--label=")
    flags+=("--namespace=")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--namespace=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_namespace()
{
    last_command="jx_namespace"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--batch-mode")
    flags+=("-b")
    local_nonpersistent_flags+=("--batch-mode")
    flags+=("--headless")
    local_nonpersistent_flags+=("--headless")
    flags+=("--install-dependencies")
    local_nonpersistent_flags+=("--install-dependencies")
    flags+=("--no-brew")
    local_nonpersistent_flags+=("--no-brew")
    flags+=("--verbose")
    local_nonpersistent_flags+=("--verbose")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_open()
{
    last_command="jx_open"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--classic")
    local_nonpersistent_flags+=("--classic")
    flags+=("--env=")
    two_word_flags+=("-e")
    local_nonpersistent_flags+=("--env=")
    flags+=("--namespace=")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--namespace=")
    flags+=("--url")
    flags+=("-u")
    local_nonpersistent_flags+=("--url")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_preview()
{
    last_command="jx_preview"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--app=")
    two_word_flags+=("-a")
    local_nonpersistent_flags+=("--app=")
    flags+=("--build=")
    local_nonpersistent_flags+=("--build=")
    flags+=("--cluster=")
    two_word_flags+=("-c")
    local_nonpersistent_flags+=("--cluster=")
    flags+=("--dev-namespace=")
    local_nonpersistent_flags+=("--dev-namespace=")
    flags+=("--dir=")
    local_nonpersistent_flags+=("--dir=")
    flags+=("--domain=")
    local_nonpersistent_flags+=("--domain=")
    flags+=("--exposer=")
    local_nonpersistent_flags+=("--exposer=")
    flags+=("--helm-repo-name=")
    two_word_flags+=("-r")
    local_nonpersistent_flags+=("--helm-repo-name=")
    flags+=("--helm-repo-url=")
    two_word_flags+=("-u")
    local_nonpersistent_flags+=("--helm-repo-url=")
    flags+=("--http=")
    local_nonpersistent_flags+=("--http=")
    flags+=("--keep-exposecontroller-job")
    local_nonpersistent_flags+=("--keep-exposecontroller-job")
    flags+=("--label=")
    two_word_flags+=("-l")
    local_nonpersistent_flags+=("--label=")
    flags+=("--name=")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--name=")
    flags+=("--namespace=")
    local_nonpersistent_flags+=("--namespace=")
    flags+=("--no-helm-update")
    local_nonpersistent_flags+=("--no-helm-update")
    flags+=("--no-merge")
    local_nonpersistent_flags+=("--no-merge")
    flags+=("--post-preview-job-timeout=")
    local_nonpersistent_flags+=("--post-preview-job-timeout=")
    flags+=("--post-preview-poll-time=")
    local_nonpersistent_flags+=("--post-preview-poll-time=")
    flags+=("--pr=")
    local_nonpersistent_flags+=("--pr=")
    flags+=("--pr-url=")
    local_nonpersistent_flags+=("--pr-url=")
    flags+=("--pull-request-poll-time=")
    local_nonpersistent_flags+=("--pull-request-poll-time=")
    flags+=("--release=")
    local_nonpersistent_flags+=("--release=")
    flags+=("--source-ref=")
    local_nonpersistent_flags+=("--source-ref=")
    flags+=("--source-url=")
    two_word_flags+=("-s")
    local_nonpersistent_flags+=("--source-url=")
    flags+=("--timeout=")
    two_word_flags+=("-t")
    local_nonpersistent_flags+=("--timeout=")
    flags+=("--tls-acme=")
    local_nonpersistent_flags+=("--tls-acme=")
    flags+=("--version=")
    two_word_flags+=("-v")
    local_nonpersistent_flags+=("--version=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_promote()
{
    last_command="jx_promote"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--all-auto")
    local_nonpersistent_flags+=("--all-auto")
    flags+=("--app=")
    two_word_flags+=("-a")
    local_nonpersistent_flags+=("--app=")
    flags+=("--batch-mode")
    flags+=("-b")
    local_nonpersistent_flags+=("--batch-mode")
    flags+=("--build=")
    local_nonpersistent_flags+=("--build=")
    flags+=("--env=")
    two_word_flags+=("-e")
    local_nonpersistent_flags+=("--env=")
    flags+=("--headless")
    local_nonpersistent_flags+=("--headless")
    flags+=("--helm-repo-name=")
    two_word_flags+=("-r")
    local_nonpersistent_flags+=("--helm-repo-name=")
    flags+=("--helm-repo-url=")
    two_word_flags+=("-u")
    local_nonpersistent_flags+=("--helm-repo-url=")
    flags+=("--install-dependencies")
    local_nonpersistent_flags+=("--install-dependencies")
    flags+=("--namespace=")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--namespace=")
    flags+=("--no-brew")
    local_nonpersistent_flags+=("--no-brew")
    flags+=("--no-helm-update")
    local_nonpersistent_flags+=("--no-helm-update")
    flags+=("--no-merge")
    local_nonpersistent_flags+=("--no-merge")
    flags+=("--pull-request-poll-time=")
    local_nonpersistent_flags+=("--pull-request-poll-time=")
    flags+=("--release=")
    local_nonpersistent_flags+=("--release=")
    flags+=("--timeout=")
    two_word_flags+=("-t")
    local_nonpersistent_flags+=("--timeout=")
    flags+=("--verbose")
    local_nonpersistent_flags+=("--verbose")
    flags+=("--version=")
    two_word_flags+=("-v")
    local_nonpersistent_flags+=("--version=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_prompt()
{
    last_command="jx_prompt"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--context-color=")
    local_nonpersistent_flags+=("--context-color=")
    flags+=("--divider=")
    two_word_flags+=("-d")
    local_nonpersistent_flags+=("--divider=")
    flags+=("--icon")
    flags+=("-i")
    local_nonpersistent_flags+=("--icon")
    flags+=("--label=")
    two_word_flags+=("-l")
    local_nonpersistent_flags+=("--label=")
    flags+=("--label-color=")
    local_nonpersistent_flags+=("--label-color=")
    flags+=("--namespace-color=")
    local_nonpersistent_flags+=("--namespace-color=")
    flags+=("--no-label")
    local_nonpersistent_flags+=("--no-label")
    flags+=("--prefix=")
    two_word_flags+=("-p")
    local_nonpersistent_flags+=("--prefix=")
    flags+=("--separator=")
    two_word_flags+=("-s")
    local_nonpersistent_flags+=("--separator=")
    flags+=("--suffix=")
    two_word_flags+=("-x")
    local_nonpersistent_flags+=("--suffix=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_repository()
{
    last_command="jx_repository"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--batch-mode")
    flags+=("-b")
    local_nonpersistent_flags+=("--batch-mode")
    flags+=("--headless")
    local_nonpersistent_flags+=("--headless")
    flags+=("--install-dependencies")
    local_nonpersistent_flags+=("--install-dependencies")
    flags+=("--no-brew")
    local_nonpersistent_flags+=("--no-brew")
    flags+=("--url")
    flags+=("-u")
    local_nonpersistent_flags+=("--url")
    flags+=("--verbose")
    local_nonpersistent_flags+=("--verbose")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_rsh()
{
    last_command="jx_rsh"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--container=")
    two_word_flags+=("-c")
    local_nonpersistent_flags+=("--container=")
    flags+=("--devpod")
    flags+=("-d")
    local_nonpersistent_flags+=("--devpod")
    flags+=("--namespace=")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--namespace=")
    flags+=("--pod=")
    two_word_flags+=("-p")
    local_nonpersistent_flags+=("--pod=")
    flags+=("--shell=")
    two_word_flags+=("-s")
    local_nonpersistent_flags+=("--shell=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_shell()
{
    last_command="jx_shell"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--batch-mode")
    flags+=("-b")
    local_nonpersistent_flags+=("--batch-mode")
    flags+=("--headless")
    local_nonpersistent_flags+=("--headless")
    flags+=("--install-dependencies")
    local_nonpersistent_flags+=("--install-dependencies")
    flags+=("--no-brew")
    local_nonpersistent_flags+=("--no-brew")
    flags+=("--verbose")
    local_nonpersistent_flags+=("--verbose")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_start_pipeline()
{
    last_command="jx_start_pipeline"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--filter=")
    two_word_flags+=("-f")
    local_nonpersistent_flags+=("--filter=")
    flags+=("--tail")
    flags+=("-t")
    local_nonpersistent_flags+=("--tail")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_start()
{
    last_command="jx_start"

    command_aliases=()

    commands=()
    commands+=("pipeline")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("build")
        aliashash["build"]="pipeline"
        command_aliases+=("pipe")
        aliashash["pipe"]="pipeline"
        command_aliases+=("pipeline")
        aliashash["pipeline"]="pipeline"
        command_aliases+=("run")
        aliashash["run"]="pipeline"
    fi

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()


    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_status()
{
    last_command="jx_status"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--node=")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--node=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_step_blog()
{
    last_command="jx_step_blog"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--batch-mode")
    flags+=("-b")
    local_nonpersistent_flags+=("--batch-mode")
    flags+=("--blog-dir=")
    local_nonpersistent_flags+=("--blog-dir=")
    flags+=("--blog-name=")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--blog-name=")
    flags+=("--combine-minor")
    flags+=("-c")
    local_nonpersistent_flags+=("--combine-minor")
    flags+=("--dev-channel-members=")
    local_nonpersistent_flags+=("--dev-channel-members=")
    flags+=("--dir=")
    two_word_flags+=("-d")
    local_nonpersistent_flags+=("--dir=")
    flags+=("--from-date=")
    two_word_flags+=("-f")
    local_nonpersistent_flags+=("--from-date=")
    flags+=("--headless")
    local_nonpersistent_flags+=("--headless")
    flags+=("--install-dependencies")
    local_nonpersistent_flags+=("--install-dependencies")
    flags+=("--no-brew")
    local_nonpersistent_flags+=("--no-brew")
    flags+=("--to-date=")
    two_word_flags+=("-t")
    local_nonpersistent_flags+=("--to-date=")
    flags+=("--user-channel-members=")
    local_nonpersistent_flags+=("--user-channel-members=")
    flags+=("--verbose")
    local_nonpersistent_flags+=("--verbose")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_step_changelog()
{
    last_command="jx_step_changelog"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--batch-mode")
    flags+=("-b")
    local_nonpersistent_flags+=("--batch-mode")
    flags+=("--build=")
    local_nonpersistent_flags+=("--build=")
    flags+=("--crd")
    flags+=("-c")
    local_nonpersistent_flags+=("--crd")
    flags+=("--crd-yaml-file=")
    local_nonpersistent_flags+=("--crd-yaml-file=")
    flags+=("--dir=")
    local_nonpersistent_flags+=("--dir=")
    flags+=("--footer=")
    local_nonpersistent_flags+=("--footer=")
    flags+=("--footer-file=")
    local_nonpersistent_flags+=("--footer-file=")
    flags+=("--generate-yaml")
    flags+=("-y")
    local_nonpersistent_flags+=("--generate-yaml")
    flags+=("--header=")
    local_nonpersistent_flags+=("--header=")
    flags+=("--header-file=")
    local_nonpersistent_flags+=("--header-file=")
    flags+=("--headless")
    local_nonpersistent_flags+=("--headless")
    flags+=("--install-dependencies")
    local_nonpersistent_flags+=("--install-dependencies")
    flags+=("--no-brew")
    local_nonpersistent_flags+=("--no-brew")
    flags+=("--output-markdown=")
    local_nonpersistent_flags+=("--output-markdown=")
    flags+=("--overwrite")
    flags+=("-o")
    local_nonpersistent_flags+=("--overwrite")
    flags+=("--previous-date=")
    local_nonpersistent_flags+=("--previous-date=")
    flags+=("--previous-rev=")
    two_word_flags+=("-p")
    local_nonpersistent_flags+=("--previous-rev=")
    flags+=("--release-yaml-file=")
    local_nonpersistent_flags+=("--release-yaml-file=")
    flags+=("--rev=")
    two_word_flags+=("-r")
    local_nonpersistent_flags+=("--rev=")
    flags+=("--templates-dir=")
    two_word_flags+=("-t")
    local_nonpersistent_flags+=("--templates-dir=")
    flags+=("--update-release")
    local_nonpersistent_flags+=("--update-release")
    flags+=("--verbose")
    local_nonpersistent_flags+=("--verbose")
    flags+=("--version=")
    two_word_flags+=("-v")
    local_nonpersistent_flags+=("--version=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_step_create()
{
    last_command="jx_step_create"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--batch-mode")
    flags+=("-b")
    local_nonpersistent_flags+=("--batch-mode")
    flags+=("--build-number=")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--build-number=")
    flags+=("--dir=")
    two_word_flags+=("-d")
    local_nonpersistent_flags+=("--dir=")
    flags+=("--headless")
    local_nonpersistent_flags+=("--headless")
    flags+=("--install-dependencies")
    local_nonpersistent_flags+=("--install-dependencies")
    flags+=("--kind=")
    two_word_flags+=("-k")
    local_nonpersistent_flags+=("--kind=")
    flags+=("--no-brew")
    local_nonpersistent_flags+=("--no-brew")
    flags+=("--output-dir=")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--output-dir=")
    flags+=("--output-prefix=")
    two_word_flags+=("-p")
    local_nonpersistent_flags+=("--output-prefix=")
    flags+=("--verbose")
    local_nonpersistent_flags+=("--verbose")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_step_envrolebinding()
{
    last_command="jx_step_envrolebinding"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--watch")
    flags+=("-w")
    local_nonpersistent_flags+=("--watch")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_step_git_credentials()
{
    last_command="jx_step_git_credentials"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--output=")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--output=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_step_git()
{
    last_command="jx_step_git"

    command_aliases=()

    commands=()
    commands+=("credentials")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("nexus_stage")
        aliashash["nexus_stage"]="credentials"
    fi

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()


    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_step_gpg()
{
    last_command="jx_step_gpg"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--output=")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--output=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_step_helm_apply()
{
    last_command="jx_step_helm_apply"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--clone-https")
    local_nonpersistent_flags+=("--clone-https")
    flags+=("--dir=")
    two_word_flags+=("-d")
    local_nonpersistent_flags+=("--dir=")
    flags+=("--git-provider=")
    local_nonpersistent_flags+=("--git-provider=")
    flags+=("--name=")
    local_nonpersistent_flags+=("--name=")
    flags+=("--namespace=")
    local_nonpersistent_flags+=("--namespace=")
    flags+=("--wait")
    local_nonpersistent_flags+=("--wait")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_step_helm_build()
{
    last_command="jx_step_helm_build"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--clone-https")
    local_nonpersistent_flags+=("--clone-https")
    flags+=("--dir=")
    two_word_flags+=("-d")
    local_nonpersistent_flags+=("--dir=")
    flags+=("--git-provider=")
    local_nonpersistent_flags+=("--git-provider=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_step_helm_release()
{
    last_command="jx_step_helm_release"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--clone-https")
    local_nonpersistent_flags+=("--clone-https")
    flags+=("--dir=")
    two_word_flags+=("-d")
    local_nonpersistent_flags+=("--dir=")
    flags+=("--git-provider=")
    local_nonpersistent_flags+=("--git-provider=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_step_helm()
{
    last_command="jx_step_helm"

    command_aliases=()

    commands=()
    commands+=("apply")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("")
        aliashash[""]="apply"
    fi
    commands+=("build")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("")
        aliashash[""]="build"
    fi
    commands+=("release")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("")
        aliashash[""]="release"
    fi

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()


    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_step_link()
{
    last_command="jx_step_link"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--batch-mode")
    flags+=("-b")
    local_nonpersistent_flags+=("--batch-mode")
    flags+=("--excludes=")
    two_word_flags+=("-e")
    local_nonpersistent_flags+=("--excludes=")
    flags+=("--from-namespace=")
    two_word_flags+=("-f")
    local_nonpersistent_flags+=("--from-namespace=")
    flags+=("--headless")
    local_nonpersistent_flags+=("--headless")
    flags+=("--includes=")
    two_word_flags+=("-i")
    local_nonpersistent_flags+=("--includes=")
    flags+=("--install-dependencies")
    local_nonpersistent_flags+=("--install-dependencies")
    flags+=("--no-brew")
    local_nonpersistent_flags+=("--no-brew")
    flags+=("--to-namespace=")
    two_word_flags+=("-t")
    local_nonpersistent_flags+=("--to-namespace=")
    flags+=("--verbose")
    local_nonpersistent_flags+=("--verbose")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_step_next-version()
{
    last_command="jx_step_next-version"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--batch-mode")
    flags+=("-b")
    local_nonpersistent_flags+=("--batch-mode")
    flags+=("--dir=")
    two_word_flags+=("-d")
    local_nonpersistent_flags+=("--dir=")
    flags+=("--filename=")
    two_word_flags+=("-f")
    local_nonpersistent_flags+=("--filename=")
    flags+=("--headless")
    local_nonpersistent_flags+=("--headless")
    flags+=("--install-dependencies")
    local_nonpersistent_flags+=("--install-dependencies")
    flags+=("--no-brew")
    local_nonpersistent_flags+=("--no-brew")
    flags+=("--tag")
    flags+=("-t")
    local_nonpersistent_flags+=("--tag")
    flags+=("--use-git-tag-only")
    local_nonpersistent_flags+=("--use-git-tag-only")
    flags+=("--verbose")
    local_nonpersistent_flags+=("--verbose")
    flags+=("--version=")
    local_nonpersistent_flags+=("--version=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_step_nexus_drop()
{
    last_command="jx_step_nexus_drop"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()


    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_step_nexus_release()
{
    last_command="jx_step_nexus_release"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--drop-on-fail")
    flags+=("-d")
    local_nonpersistent_flags+=("--drop-on-fail")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_step_nexus()
{
    last_command="jx_step_nexus"

    command_aliases=()

    commands=()
    commands+=("drop")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("nexus_stage")
        aliashash["nexus_stage"]="drop"
    fi
    commands+=("release")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("nexus_stage")
        aliashash["nexus_stage"]="release"
    fi

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()


    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_step_post_build()
{
    last_command="jx_step_post_build"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--image=")
    local_nonpersistent_flags+=("--image=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_step_post()
{
    last_command="jx_step_post"

    command_aliases=()

    commands=()
    commands+=("build")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()


    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_step_pr_comment()
{
    last_command="jx_step_pr_comment"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--batch-mode")
    flags+=("-b")
    local_nonpersistent_flags+=("--batch-mode")
    flags+=("--comment=")
    two_word_flags+=("-c")
    local_nonpersistent_flags+=("--comment=")
    flags+=("--headless")
    local_nonpersistent_flags+=("--headless")
    flags+=("--install-dependencies")
    local_nonpersistent_flags+=("--install-dependencies")
    flags+=("--no-brew")
    local_nonpersistent_flags+=("--no-brew")
    flags+=("--owner=")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--owner=")
    flags+=("--pull-request=")
    two_word_flags+=("-p")
    local_nonpersistent_flags+=("--pull-request=")
    flags+=("--repository=")
    two_word_flags+=("-r")
    local_nonpersistent_flags+=("--repository=")
    flags+=("--verbose")
    local_nonpersistent_flags+=("--verbose")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_step_pr()
{
    last_command="jx_step_pr"

    command_aliases=()

    commands=()
    commands+=("comment")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--batch-mode")
    flags+=("-b")
    local_nonpersistent_flags+=("--batch-mode")
    flags+=("--headless")
    local_nonpersistent_flags+=("--headless")
    flags+=("--install-dependencies")
    local_nonpersistent_flags+=("--install-dependencies")
    flags+=("--no-brew")
    local_nonpersistent_flags+=("--no-brew")
    flags+=("--verbose")
    local_nonpersistent_flags+=("--verbose")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_step_pre_build()
{
    last_command="jx_step_pre_build"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--image=")
    two_word_flags+=("-i")
    local_nonpersistent_flags+=("--image=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_step_pre()
{
    last_command="jx_step_pre"

    command_aliases=()

    commands=()
    commands+=("build")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()


    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_step_release()
{
    last_command="jx_step_release"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--application=")
    two_word_flags+=("-a")
    local_nonpersistent_flags+=("--application=")
    flags+=("--build=")
    two_word_flags+=("-b")
    local_nonpersistent_flags+=("--build=")
    flags+=("--docker-registry=")
    two_word_flags+=("-r")
    local_nonpersistent_flags+=("--docker-registry=")
    flags+=("--git-email=")
    two_word_flags+=("-e")
    local_nonpersistent_flags+=("--git-email=")
    flags+=("--git-username=")
    two_word_flags+=("-u")
    local_nonpersistent_flags+=("--git-username=")
    flags+=("--helm-repo-name=")
    local_nonpersistent_flags+=("--helm-repo-name=")
    flags+=("--helm-repo-url=")
    local_nonpersistent_flags+=("--helm-repo-url=")
    flags+=("--no-batch")
    local_nonpersistent_flags+=("--no-batch")
    flags+=("--organisation=")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--organisation=")
    flags+=("--pull-request-poll-time=")
    local_nonpersistent_flags+=("--pull-request-poll-time=")
    flags+=("--timeout=")
    two_word_flags+=("-t")
    local_nonpersistent_flags+=("--timeout=")
    flags+=("--xdg-config-home=")
    local_nonpersistent_flags+=("--xdg-config-home=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_step_report_activities()
{
    last_command="jx_step_report_activities"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--batch-mode")
    flags+=("-b")
    local_nonpersistent_flags+=("--batch-mode")
    flags+=("--headless")
    local_nonpersistent_flags+=("--headless")
    flags+=("--install-dependencies")
    local_nonpersistent_flags+=("--install-dependencies")
    flags+=("--no-brew")
    local_nonpersistent_flags+=("--no-brew")
    flags+=("--verbose")
    local_nonpersistent_flags+=("--verbose")
    flags+=("--watch")
    flags+=("-w")
    local_nonpersistent_flags+=("--watch")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_step_report_releases()
{
    last_command="jx_step_report_releases"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--batch-mode")
    flags+=("-b")
    local_nonpersistent_flags+=("--batch-mode")
    flags+=("--headless")
    local_nonpersistent_flags+=("--headless")
    flags+=("--install-dependencies")
    local_nonpersistent_flags+=("--install-dependencies")
    flags+=("--no-brew")
    local_nonpersistent_flags+=("--no-brew")
    flags+=("--verbose")
    local_nonpersistent_flags+=("--verbose")
    flags+=("--watch")
    flags+=("-w")
    local_nonpersistent_flags+=("--watch")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_step_report()
{
    last_command="jx_step_report"

    command_aliases=()

    commands=()
    commands+=("activities")
    commands+=("releases")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()


    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_step_split()
{
    last_command="jx_step_split"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--glob=")
    two_word_flags+=("-g")
    local_nonpersistent_flags+=("--glob=")
    flags+=("--kubernetes-folder=")
    local_nonpersistent_flags+=("--kubernetes-folder=")
    flags+=("--no-git")
    local_nonpersistent_flags+=("--no-git")
    flags+=("--organisation=")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--organisation=")
    flags+=("--output-dir=")
    two_word_flags+=("-d")
    local_nonpersistent_flags+=("--output-dir=")
    flags+=("--source-dir=")
    two_word_flags+=("-s")
    local_nonpersistent_flags+=("--source-dir=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_step_tag()
{
    last_command="jx_step_tag"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--charts-dir=")
    two_word_flags+=("-d")
    local_nonpersistent_flags+=("--charts-dir=")
    flags+=("--charts-value-repository=")
    two_word_flags+=("-r")
    local_nonpersistent_flags+=("--charts-value-repository=")
    flags+=("--version=")
    two_word_flags+=("-v")
    local_nonpersistent_flags+=("--version=")
    flags+=("--version-file=")
    local_nonpersistent_flags+=("--version-file=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_step_validate()
{
    last_command="jx_step_validate"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--dir=")
    two_word_flags+=("-d")
    local_nonpersistent_flags+=("--dir=")
    flags+=("--min-jx-version=")
    two_word_flags+=("-v")
    local_nonpersistent_flags+=("--min-jx-version=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_step_verify()
{
    last_command="jx_step_verify"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--after=")
    local_nonpersistent_flags+=("--after=")
    flags+=("--pods=")
    two_word_flags+=("-p")
    local_nonpersistent_flags+=("--pods=")
    flags+=("--restarts=")
    two_word_flags+=("-r")
    local_nonpersistent_flags+=("--restarts=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_step_wait()
{
    last_command="jx_step_wait"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--artifact=")
    two_word_flags+=("-a")
    local_nonpersistent_flags+=("--artifact=")
    flags+=("--artifact-url=")
    local_nonpersistent_flags+=("--artifact-url=")
    flags+=("--ext=")
    two_word_flags+=("-x")
    local_nonpersistent_flags+=("--ext=")
    flags+=("--group=")
    two_word_flags+=("-g")
    local_nonpersistent_flags+=("--group=")
    flags+=("--poll-time=")
    local_nonpersistent_flags+=("--poll-time=")
    flags+=("--repo=")
    two_word_flags+=("-r")
    local_nonpersistent_flags+=("--repo=")
    flags+=("--timeout=")
    two_word_flags+=("-t")
    local_nonpersistent_flags+=("--timeout=")
    flags+=("--version=")
    two_word_flags+=("-v")
    local_nonpersistent_flags+=("--version=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_step()
{
    last_command="jx_step"

    command_aliases=()

    commands=()
    commands+=("blog")
    commands+=("changelog")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("changes")
        aliashash["changes"]="changelog"
    fi
    commands+=("create")
    commands+=("envrolebinding")
    commands+=("git")
    commands+=("gpg")
    commands+=("helm")
    commands+=("link")
    commands+=("next-version")
    commands+=("nexus")
    commands+=("post")
    commands+=("pr")
    commands+=("pre")
    commands+=("release")
    commands+=("report")
    commands+=("split")
    commands+=("tag")
    commands+=("validate")
    commands+=("verify")
    commands+=("wait")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()


    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_stop_pipeline()
{
    last_command="jx_stop_pipeline"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--build=")
    two_word_flags+=("-b")
    local_nonpersistent_flags+=("--build=")
    flags+=("--filter=")
    two_word_flags+=("-f")
    local_nonpersistent_flags+=("--filter=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_stop()
{
    last_command="jx_stop"

    command_aliases=()

    commands=()
    commands+=("pipeline")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("build")
        aliashash["build"]="pipeline"
        command_aliases+=("pipe")
        aliashash["pipe"]="pipeline"
        command_aliases+=("pipeline")
        aliashash["pipeline"]="pipeline"
        command_aliases+=("run")
        aliashash["run"]="pipeline"
    fi

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()


    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_sync()
{
    last_command="jx_sync"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--daemon")
    local_nonpersistent_flags+=("--daemon")
    flags+=("--no-init")
    local_nonpersistent_flags+=("--no-init")
    flags+=("--single-mode")
    local_nonpersistent_flags+=("--single-mode")
    flags+=("--watch-only")
    local_nonpersistent_flags+=("--watch-only")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_team()
{
    last_command="jx_team"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--batch-mode")
    flags+=("-b")
    local_nonpersistent_flags+=("--batch-mode")
    flags+=("--headless")
    local_nonpersistent_flags+=("--headless")
    flags+=("--install-dependencies")
    local_nonpersistent_flags+=("--install-dependencies")
    flags+=("--no-brew")
    local_nonpersistent_flags+=("--no-brew")
    flags+=("--verbose")
    local_nonpersistent_flags+=("--verbose")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_uninstall()
{
    last_command="jx_uninstall"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--batch-mode")
    flags+=("-b")
    local_nonpersistent_flags+=("--batch-mode")
    flags+=("--headless")
    local_nonpersistent_flags+=("--headless")
    flags+=("--install-dependencies")
    local_nonpersistent_flags+=("--install-dependencies")
    flags+=("--namespace=")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--namespace=")
    flags+=("--no-brew")
    local_nonpersistent_flags+=("--no-brew")
    flags+=("--verbose")
    local_nonpersistent_flags+=("--verbose")
    flags+=("--yes")
    flags+=("-y")
    local_nonpersistent_flags+=("--yes")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_update_cluster_gke_terraform()
{
    last_command="jx_update_cluster_gke_terraform"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--batch-mode")
    flags+=("-b")
    local_nonpersistent_flags+=("--batch-mode")
    flags+=("--cluster-name=")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--cluster-name=")
    flags+=("--headless")
    local_nonpersistent_flags+=("--headless")
    flags+=("--install-dependencies")
    local_nonpersistent_flags+=("--install-dependencies")
    flags+=("--no-brew")
    local_nonpersistent_flags+=("--no-brew")
    flags+=("--service-account=")
    local_nonpersistent_flags+=("--service-account=")
    flags+=("--skip-login")
    local_nonpersistent_flags+=("--skip-login")
    flags+=("--verbose")
    local_nonpersistent_flags+=("--verbose")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_update_cluster_gke()
{
    last_command="jx_update_cluster_gke"

    command_aliases=()

    commands=()
    commands+=("terraform")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()


    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_update_cluster()
{
    last_command="jx_update_cluster"

    command_aliases=()

    commands=()
    commands+=("gke")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()


    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_update()
{
    last_command="jx_update"

    command_aliases=()

    commands=()
    commands+=("cluster")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()


    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_upgrade_cli()
{
    last_command="jx_upgrade_cli"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--version=")
    two_word_flags+=("-v")
    local_nonpersistent_flags+=("--version=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_upgrade_cluster()
{
    last_command="jx_upgrade_cluster"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--cluster-name=")
    two_word_flags+=("-c")
    local_nonpersistent_flags+=("--cluster-name=")
    flags+=("--version=")
    two_word_flags+=("-v")
    local_nonpersistent_flags+=("--version=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_upgrade_ingress()
{
    last_command="jx_upgrade_ingress"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--cluster")
    local_nonpersistent_flags+=("--cluster")
    flags+=("--namespaces=")
    local_nonpersistent_flags+=("--namespaces=")
    flags+=("--skip-certmanager")
    local_nonpersistent_flags+=("--skip-certmanager")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_upgrade_platform()
{
    last_command="jx_upgrade_platform"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--batch-mode")
    flags+=("-b")
    local_nonpersistent_flags+=("--batch-mode")
    flags+=("--chart=")
    two_word_flags+=("-c")
    local_nonpersistent_flags+=("--chart=")
    flags+=("--cloud-environment-repo=")
    local_nonpersistent_flags+=("--cloud-environment-repo=")
    flags+=("--headless")
    local_nonpersistent_flags+=("--headless")
    flags+=("--install-dependencies")
    local_nonpersistent_flags+=("--install-dependencies")
    flags+=("--local-cloud-environment")
    local_nonpersistent_flags+=("--local-cloud-environment")
    flags+=("--name=")
    two_word_flags+=("-n")
    local_nonpersistent_flags+=("--name=")
    flags+=("--namespace=")
    local_nonpersistent_flags+=("--namespace=")
    flags+=("--no-brew")
    local_nonpersistent_flags+=("--no-brew")
    flags+=("--set=")
    two_word_flags+=("-s")
    local_nonpersistent_flags+=("--set=")
    flags+=("--verbose")
    local_nonpersistent_flags+=("--verbose")
    flags+=("--version=")
    two_word_flags+=("-v")
    local_nonpersistent_flags+=("--version=")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_upgrade()
{
    last_command="jx_upgrade"

    command_aliases=()

    commands=()
    commands+=("cli")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("client")
        aliashash["client"]="cli"
        command_aliases+=("clients")
        aliashash["clients"]="cli"
    fi
    commands+=("cluster")
    commands+=("ingress")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("ing")
        aliashash["ing"]="ingress"
    fi
    commands+=("platform")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("token")
        aliashash["token"]="platform"
    fi

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()


    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_version()
{
    last_command="jx_version"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--batch-mode")
    flags+=("-b")
    local_nonpersistent_flags+=("--batch-mode")
    flags+=("--headless")
    local_nonpersistent_flags+=("--headless")
    flags+=("--helm-tls")
    local_nonpersistent_flags+=("--helm-tls")
    flags+=("--install-dependencies")
    local_nonpersistent_flags+=("--install-dependencies")
    flags+=("--no-brew")
    local_nonpersistent_flags+=("--no-brew")
    flags+=("--no-version-check")
    flags+=("-n")
    local_nonpersistent_flags+=("--no-version-check")
    flags+=("--verbose")
    local_nonpersistent_flags+=("--verbose")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_jx_root_command()
{
    last_command="jx"

    command_aliases=()

    commands=()
    commands+=("cloudbees")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("cb")
        aliashash["cb"]="cloudbees"
        command_aliases+=("cdx")
        aliashash["cdx"]="cloudbees"
        command_aliases+=("cloudbee")
        aliashash["cloudbee"]="cloudbees"
    fi
    commands+=("completion")
    commands+=("compliance")
    commands+=("console")
    commands+=("context")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("ctx")
        aliashash["ctx"]="context"
    fi
    commands+=("controller")
    commands+=("create")
    commands+=("delete")
    commands+=("edit")
    commands+=("environment")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("env")
        aliashash["env"]="environment"
    fi
    commands+=("gc")
    commands+=("get")
    commands+=("import")
    commands+=("init")
    commands+=("install")
    commands+=("logs")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("log")
        aliashash["log"]="logs"
    fi
    commands+=("namespace")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("ns")
        aliashash["ns"]="namespace"
    fi
    commands+=("open")
    commands+=("preview")
    commands+=("promote")
    commands+=("prompt")
    commands+=("repository")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("repo")
        aliashash["repo"]="repository"
    fi
    commands+=("rsh")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("log")
        aliashash["log"]="rsh"
    fi
    commands+=("shell")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("sh")
        aliashash["sh"]="shell"
    fi
    commands+=("start")
    commands+=("status")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("status")
        aliashash["status"]="status"
    fi
    commands+=("step")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("steps")
        aliashash["steps"]="step"
    fi
    commands+=("stop")
    commands+=("sync")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("log")
        aliashash["log"]="sync"
    fi
    commands+=("team")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("env")
        aliashash["env"]="team"
    fi
    commands+=("uninstall")
    commands+=("update")
    commands+=("upgrade")
    commands+=("version")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()


    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

__start_jx()
{
    local cur prev words cword
    declare -A flaghash 2>/dev/null || :
    declare -A aliashash 2>/dev/null || :
    if declare -F _init_completion >/dev/null 2>&1; then
        _init_completion -s || return
    else
        __jx_init_completion -n "=" || return
    fi

    local c=0
    local flags=()
    local two_word_flags=()
    local local_nonpersistent_flags=()
    local flags_with_completion=()
    local flags_completion=()
    local commands=("jx")
    local must_have_one_flag=()
    local must_have_one_noun=()
    local last_command
    local nouns=()

    __jx_handle_word
}

if [[ $(type -t compopt) = "builtin" ]]; then
    complete -o default -F __start_jx jx
else
    complete -o default -o nospace -F __start_jx jx
fi

# ex: ts=4 sw=4 et filetype=sh

BASH_COMPLETION_EOF
}
__jx_bash_source <(__jx_convert_bash_to_zsh)
_complete jx 2>/dev/null
