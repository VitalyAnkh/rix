#!/usr/bin/env zsh
# Plays a notification sound.
#
# SYNOPSIS:
#   play-sound [-v VOLUME] [-w] NAME
#   play-sound ls
#
# DESCRIPTION:
#   NAME is the basename of an .ogg, .wav or .mp3 file in `hey path assets
#   sounds`.
#
# OPTIONS:
#   -v VOLUME
#     Play at VOLUME rather than the default.
#   -w
#     Block until the sound is done playing.
#
# ARGUMENTS:
#   1 NAME
#     ls    -- List the available sounds instead of playing one.

if (( $# == 0 )); then
  hey.error "Name of sound required"
  exit 2
fi

local dir=$(hey path assets sounds)
if [[ "$1" == "ls" ]]; then
  ls -l "$dir"
else
  hey.requires play
  zparseopts -E -D -F -- v:=volume w=wait || exit 1
  local file=$(echo "$dir"/$1.{ogg,wav,mp3}(-.N[1]))
  if [[ -z $file ]]; then
    hey.error "Unrecognized sound: $1"
    exit 1
  fi
  if [[ $wait ]]; then
    hey.do play -q $volume $file
  else
    hey.do play -q $volume $file &
  fi
fi
