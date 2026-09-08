#!/usr/bin/env zsh
# Toggle drawing on the screen.
#
# SYNOPSIS:
#   screendraw
#
# DESCRIPTION:
#   Temporarily launches gromit-mpx, enabling you to draw on the screen. Also
#   includes OSD indicators.
#
# DEPENDENCIES:
#   gromit-mpx

#
#   There
#           can only
#
#
#                        be
#
#                              one.
#
if pidof gromit-mpx >/dev/null; then
  pkill gromit-mpx
  exit
fi

# gromit-mpx lacks CLI options to configure it, but I insist on using it as a
# one-shot on-demand tool, so...
local inifile=$XDG_CONFIG_HOME/gromit-mpx.ini
cat >$inifile <<-EOF
  [General]
  ShowIntroOnStartup=false
EOF

local cfgfile=$XDG_CONFIG_HOME/gromit-mpx.cfg
cat >$cfgfile <<EOF
  "red Pen" = PEN (size=5 color="red");
  "blue Pen" = "red Pen" (color="blue");
  "yellow Pen" = "red Pen" (color="yellow");
  "green Marker" = PEN (size=6 color="green" arrowsize=1);
  "ortho line" = ORTHOGONAL (color="red" size=5 simplify=15 radius=20 minlen=50 snap=40);
  "Eraser" = ERASER (size = 75);

  "default" = SMOOTH (color="red" simplify=12 snap=30);
  "default"[SHIFT] = "ortho line";
  "default"[CONTROL] = "ortho line" (arrowsize=2);
  "default"[2] = RECT (color="yellow");
  "default"[SHIFT,2] = RECT (color="blue");
  "default"[CONTROL,2] = RECT (color="green");
  "default"[3] = "Eraser";
  "default"[SHIFT,3] = ERASER (size=5000);
EOF
trap "rm -f '$cfgfile' '$inifile'" EXIT

dms ipc toast dismiss draw  # debouncing
dms ipc toast warnWith "Screen draw ON" "" "" draw
hyprctl eval 'hl.config({ decoration = { dim_inactive = false } })'
# Wayland backend is unreliable on hyprland.
GDK_BACKEND=x11 hey.do gromit-mpx --active
hyprctl eval 'hl.config({ decoration = { dim_inactive = true } })'
dms ipc toast dismiss draw
dms ipc toast infoWith "Screen draw OFF" "" "" draw
