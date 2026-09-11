#!/usr/bin/env zsh
# On 'hey reload'.
#
# SYNOPSIS:
#   hey reload
#
# SYNOPSIS:
#   Triggered by 'hey reload'

# There is no easy way to tell DMS to "regenerate user matugent templates"
# without a convoluted `dms matugen generate` call or manually toggling the "Run
# User Templates" option in the settings UI (`dms ipc call settings set
# runUserMatugenTemplates` doesn't work either). Re-setting the wallpaper does
# work, though, and DMS is smart enough to not do too much work if the wallpaper
# hasn't really changed.
if [[ $(dms ipc call settings get runUserMatugenTemplates) == "true" ]]; then
  wallpaper=$(dms ipc call wallpaper get)
  if [[ $wallpaper == /* ]]; then
    echo "Hyprland: regenerating matugen templates"
    hey.do dms ipc call wallpaper set "$wallpaper"
  else
    # per-monitor wallpapers answer with an ERROR here, and need getFor/setFor
    hey.warn "Skipping matugen templates: $wallpaper"
  fi
fi

# I'm using this instead of exec= lines in hyprland.conf so I can ensure these
# aren't run at startup and sequentially (i.e. predictable order, since
# Hyprland's exec= calls are parallelized).
for i in $(hyprctl instances -j | jq -r '.[].instance'); do
  echo "Hyprland: reloading instance $i"
  hey.do hyprctl -i ''${i//*\//} reload config-only
done
