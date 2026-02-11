#!/usr/bin/env zsh
# Splits up a flac file into multiple from a *.cue file.
#
# SYNOPSIS:
#   hey .flac split *.cue *.flac

local cuefile="$1"
local flacfile="$2"
set -e

# Split + tag
shnsplit -f "$cuefile" -o flac "$flacfile"
[[ -f split-track00.flac ]] && rm -f split-track00.flac
cuetag.sh "$cuefile" split-track*.flac

# Rename tracks
local totaldiscs=$(metaflac --show-tag=TOTALDISCS split-track01.flac | sed 's/.*=//')
for f in split-track*.flac; do
  local track=$(metaflac --show-tag=TRACKNUMBER "$f" | sed 's/.*=//')
  local title=$(metaflac --show-tag=TITLE "$f" | sed 's/.*=//')
  local bitdepth=$(metaflac --show-bps "$f")
  local bitrate=$(metaflac --show-sample-rate "$f")
  local quality=$(printf "[%d-%d]" "$bitdepth" "$(( bitrate / 1000 ))")
  if (( totaldiscs > 1 )); then
    local disc=$(metaflac --show-tag=DISCNUMBER "$f" | sed 's/.*=//')
    track=$(printf "%d-%02d" "$disc" "$track")
  else
    track=$(printf "%02d" "$track")
  fi
  mv -v -- "$f" "$track ${title//\//-} $quality.flac"
done
