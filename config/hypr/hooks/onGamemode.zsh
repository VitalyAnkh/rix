#!/usr/bin/env zsh
# Display notifications about gamemode's state.
#
# SYNOPSIS:
#   on-gamemode 1
#   on-gamemode 0
#
# DESCRIPTION:
#   Display a notification indicating the status of gamemode. This ought to be
#   triggered by gamemode's start/end hooks.
#
#   @see modules/apps/steam.nix.

case $1 in
  on)
    # systemctl start --user gamemoded.service
    echo "Started gamemode..."
    dms ipc toast warn "Gamemode started!"
    ;;
  off)
    echo "Stopped gamemode..."
    dms ipc toast info "Gamemode ended!"
    # { sleep 3; systemctl stop --user gamemoded.service; }
    ;;
esac
