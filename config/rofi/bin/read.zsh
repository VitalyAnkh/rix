#!/usr/bin/env zsh
# Read input using Rofi.
#
# SYNOPSIS:
#   read [-P PLACEHOLDER] [-I ICON] [--password]
#
# OPTIONS:
#   -P PLACEHOLDER
#     Show PLACEHOLDER in the empty input field.
#   -I ICON
#     Show ICON (a path to an image) beside the input field.
#   --password
#     Mask what is typed.

zparseopts -E -D -F -- P:=placeholder I:=icon -password=secret || exit 1
hey.do rofi \
  -dmenu -lines 1 \
  -theme-str 'mainbox{children:[inputbar,message];}' \
  ${icon[2]:+-theme-str "icon{filename:\"${icon[2]}\";}"} \
  ${placeholder[2]:+-theme-str "entry{placeholder:\"${placeholder:1}\";}"} \
  ${secret:+-password}
