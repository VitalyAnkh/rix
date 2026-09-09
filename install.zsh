#!/usr/bin/env zsh
# Deploy and install this nixos system.
#
# SYNOPSIS:
#   install.zsh [--root DIR] [--flake DIR] [--host NAME] [--user NAME]
#
# OPTIONS:
#   --root DIR
#     Where the target system is mounted. Default: /mnt
#   --flake DIR
#     Where to put this flake, and install from, as the installer sees it.
#     Must live under --root. Default: $root/etc/dotfiles
#   --host NAME
#     Which config under hosts/ to install. Default: $HOST
#   --user NAME
#     Primary user of the new system. Default: hlissner
#
# EXIT CODES:
#   1  not running as root, or a command failed
#   2  bad or missing argument

function _usage() {
  >&2 sed -n '2,/^$/{/^#/!d; s/^# \?//; p}' "$ZSH_SCRIPT"
}

function _escape() {
  local str=${1//\\/\\\\}
  print -rn -- "${str//\"/\\\"}"
}

function main() {
  local -a args
  local arg
  for arg in "$@"; do
    if [[ $arg == --*=* ]]; then
      args+=( "${arg%%=*}" "${arg#*=}" )
    else
      args+=( "$arg" )
    fi
  done
  set -- "${args[@]}"
  local -a argv0=( "$@" )

  local -a o_flake o_user o_host o_root o_help
  zparseopts -D -F -- -flake:=o_flake -user:=o_user -host:=o_host \
                      -root:=o_root h=o_help -help=o_help || { _usage; exit 2 }
  (( $#o_help )) && { _usage; exit 0 }

  local root="${o_root[2]:-/mnt}"
  local flake="${o_flake[2]:-$root/etc/dotfiles}"
  local host="${o_host[2]:-$HOST}"
  local user="${o_user[2]:-hlissner}"

  # nixos-install needs root. In the installer the autologin user is `nixos`,
  # which has passwordless sudo, so this is the check that was wanted.
  if (( EUID != 0 )); then
    >&2 echo "Error: must be run as root (try: sudo $ZSH_SCRIPT $argv0)"
    exit 1
  elif [[ -z "$host" ]]; then
    >&2 echo "Error: no --host set"
    exit 2
  elif [[ "$flake" != "$root"/* ]]; then
    >&2 echo "Error: --flake ($flake) must be under $root"
    exit 2
  fi

  if [[ ! -d "$flake" ]]; then
    local url=https://github.com/hlissner/dotfiles
    [[ "$user" == hlissner ]] && url="git@github.com:hlissner/dotfiles.git"
    rm -rf "$flake"
    git clone --recursive "$url" "$flake"
  fi

  chown -R "${user}:users" "$flake" 2>/dev/null \
    || >&2 echo "Warning: could not chown $flake to $user; fix it after first boot"

  if [[ ! -d "$flake/hosts/$host" ]]; then
    >&2 echo "Error: no config for host '$host' (looked in $flake/hosts/)"
    exit 2
  fi

  export HEYENV="{\"user\":\"$(_escape "$user")\",\"host\":\"$(_escape "$host")\",\"path\":\"$(_escape "${flake#$root}")\"}"
  nixos-install \
      --impure \
      --show-trace \
      --root "$root" \
      --flake "${flake}#${host}"
}

set -e
main "$@"
