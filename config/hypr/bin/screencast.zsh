#!/usr/bin/env zsh
# Record a region of the screen to clipboard.
#
# SYNOPSIS:
#   screencast [webm|mp4|gif] [X,Y WxH] [DELAY]
#
# DESCRIPTION:
#   Prompts the user to select a region, window, or monitor to begin recording
#   with wf-recorder. Produces a webm by default, but can also produce mp4' or
#   gifs
#
# DEPENDENCIES:
#   wf-recorder, ffmpeg, gifsicle*
#
#   * Is auto-installed with cached-nix-shell when needed.

main() {
  hey.requires wf-recorder ffmpeg

  local prefix=$(hey path runtime screencast)
  local livefile=$prefix.live
  local file
  local -a opts=( --audio-backend pipewire )
  if [[ -f "$livefile" ]]; then
    pkill -SIGINT wf-recorder
    rm -f "$livefile"
    return
  fi
  case "${1:-webm}" in
    webm)
      file="$prefix.webm"
      # Optimized for short (sub-30s) recordings of text/code. Use mp4 for
      # gaming-quality recordings.
      opts+=( \
        -c libvpx-vp9 -x yuv444p -r 30 \
        -p crf=24 -p cpu-used=0 -p deadline=good \
        -p row-mt=1 -p tile-columns=2 -p b=0 -p g=240 \
      )
      ;;
    mp4)
      file="$prefix.mp4"
      # Optimized for high-motion (sub-30s) recordings of high-motion content,
      # like games or video.
      opts+=( \
        --audio -c libx264 -r 60 -B 60 -b 5 \
        -p preset=slow -p tune=animation -p crf=18 \
        -p g=300 -p keyint_min=60 -p aq-mode=3 \
        -p profile=high -p level=4.2 \
      )
      ;;
    gif)
      file="$prefix.gif"
      # Not optimized at all. There really is little reason to use gif over
      # webm, but I keep it here for posterity. Ideally, it should be encoded to
      # some other raw format and post-processed to gif with ffmpeg, but I can't
      # be assed to do that here, since I never use this.
      opts+=( --codec gif )
      ;;
    *) hey.abort "Unknown format: $1" ;;
  esac
  rm -f "$file"
  touch "$livefile"
  trap "rm -f '$livefile'" EXIT SIGINT SIGTERM
  local geom="$(hey .slurp ${2:-region})"
  [[ -z "$geom" ]] && exit 1

  local delay="$3"
  if [[ -n "$delay" ]] && (( delay > 0 )); then
    for i in {$delay..1}; do
      hey .play-sound blip &
      dms ipc toast dismiss countdown  # debounce
      dms ipc toast warnWith "Recording starting in... $i" "" "" countdown
      sleep 1
    done
    dms ipc toast dismiss countdown
  fi
  if wf-recorder -g "$geom" ${opts[@]} --file="$file"; then
    sleep 0.1
    if [[ $1 == gif ]]; then
      dms ipc toast warn "Optimizing gif. This may take a while..."
      hey.do -! gifsicle --optimize=3 "$file"
    fi
    echo "file://$file" | wl-copy -t text/uri-list
    hey .play-sound success &
    dms ipc toast info "Recording complete. Copied to clipboard!"
  fi
}

main $@
