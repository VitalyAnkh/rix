#!/usr/bin/env zsh
# Capture (and edit) a screenshot to clibpoard.
#
# SYNOPSIS:
#   screen-capture [-e] [-o|--optimize] [-f FILE] [region|window|output]
#
# DESCRIPTION:
#   Captures a screenshot, optionally piping it through swappy, then optimizing
#   it with pngquant, before writing it to the clipboard (or to FILE). Also
#   notifies you once it's complete (with the screenshot as the notification
#   icon).
#
# OPTIONS:
#   -o, --optimize
#     Run pngquant on resulting png.
#   -s, --swappy
#     After capturing the image, invoke swappy on it (for quick editing).
#   -f FILE
#     Write the resulting file to FILE rather than to the clipboard.

main() {
  hey.requires hyprshot ${swappy:+swappy}
  if pidof -s hyprshot >/dev/null; then
    hey.error "Hyprshot already running. Aborting..."
    exit 0
  fi

  zparseopts -E -D -F -- {s,-swappy}=swappy f:=dest c:=countdown {o,-optimize}=optimize || return 1
  local file="${dest[2]:-$(hey path runtime screencapture.png)}"
  hey.do hyprshot --silent --mode "${1:-region}" -o "$(dirname $file)" -f "$(basename $file)"

  # It seems hyprshot exits before it's done writing the file...
  local timer=0.0
  while [[ ! -s "$file" ]]; do
    if (( timer >= 3.0 )); then
      echo "File not created at $file" >&2
      return 1
    fi
    sleep 0.1
    timer+=0.1
  done

  [[ $dest ]] || trap "rm -f '$file'" EXIT
  if [[ $swappy ]]; then
    hey.do swappy -f "$file" -o "$file" || return 1

    # Provide some feedback that the process is progressing as intended.
    hey .play-sound blip
  fi
  if [[ $optimize ]]; then
    hey.do -o pngquant -f --ext .png --quality 90-95 "$file"
  fi
  wl-copy --type image/png <"$file"
  hey.do notify-send \
    -a hey.screenshot \
    -i $file \
    -h string:x-canonical-private-synchronous:osd \
    -h string:category:preview \
    "Sent screenshot to ${dest[2]:-clipboard}"
  hey .play-sound blip
}

main $@
