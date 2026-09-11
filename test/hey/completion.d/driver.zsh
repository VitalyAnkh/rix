#!/usr/bin/env zsh
# A simulation of config/zsh/completions/_hey for testing purposes.
#
# SYNOPSIS:
#   driver.zsh CASE [WORD...]

emulate -L zsh
# What compinit's _comp_setup guarantees for any real completion.
setopt extendedglob nullglob bareglobqual rcexpandparam unset
setopt no_globsubst no_shwordsplit
local -a reply  # _comp_setup declares this; see the note in _hey's header.

_arguments() { local a; for a in "$@"; do [[ $a == (-C|-A|-\*) ]] && continue; print -r -- "ARG $a"; done }
_describe()  { local t=$2 n=$4 x=$6
               print -r -- "DESC[$t] ${(j: :)${(P)n}}"
               [[ -n $x ]] && print -r -- "DESC[$t] ${(j: :)${(P)x}}"
               return 0 }
_wanted()    { local t=$1; shift 4; print -r -- "WANT[$t] ${(j: :)@}" }
_alternative() { print -r -- "ALT ${(j: :)@}" }
_default()   { print -r -- "DEFAULT" }
_files()     { print -r -- "FILES" }
_command_names() { print -r -- "COMMANDS ${(j: :)@}" }
compadd()    { print -r -- "ADD ${(j: :)@}" }
compset()    { local p=$2; [[ $PREFIX == $p* ]] && { PREFIX=${PREFIX#$p}; return 0 }; return 1 }

local root=${0:A:h:h:h:h}
source $root/config/zsh/completions/_hey >/dev/null 2>&1

local case=$1; shift
local -a _hey_reply
local _hey_root=$root
local _hey_host=testhost
local _hey_wm=testwm
local _hey_datadir=$root/test/hey/completion.d/data
local -a _hey_bindirs=( $root/test/hey/completion.d/bin )
local -a _hey_cfgdirs=( alpha beta )
local -a _hey_hookareas=( alpha beta host )

words=( "$@" ); CURRENT=$(( $#words + 1 )); PREFIX=""; SUFFIX=""; line=( "$@" )
case $case in
  (dispatch) __hey_dispatch ;;
  (menu) PREFIX=${1-}; __hey_commands ;;
  (areas) PREFIX=${1-}; __hey_hook_areas ;;
  # __hey_hook_arg reads the positional that _arguments already consumed out of
  # $line, and $CURRENT as *:: leaves it: 1 for the first of the rest arguments.
  (hookarg)
    __hey_hooks() { print -r -- "HOOKS ${(j: :)@}" }
    line=( ${1-} ); CURRENT=${2:-1}
    __hey_hook_arg
    ;;
  # Record what __hey_scriptdir reconstructs for `hey help --dump`, rather than
  # running hey.
  (reconstruct)
    __hey_dump() { print -r -- "DUMP ${(j: :)@}"; return 1 }
    __hey_dispatch
    ;;
  # Every path must degrade rather than error if hey is unavailable
  (nohey)
    __hey_scan() { return 1 }
    __hey_dump() { return 1 }
    __hey_dispatch
    ;;
  (*) print -r -- "unknown case: $case"; return 2 ;;
esac
