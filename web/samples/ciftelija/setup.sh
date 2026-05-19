#!/usr/bin/env bash
# Usage: bash setup.sh /path/to/extracted/Cifteli
# Finds WAV files in the Decent Sampler çifteli library and renames them
# to the convention expected by the Teli web app.

set -e

SRC="${1:-.}"

if [ ! -d "$SRC" ]; then
  echo "Usage: $0 /path/to/extracted/Cifteli"
  exit 1
fi

DEST="$(cd "$(dirname "$0")" && pwd)"

# MIDI note number → target filename mapping
declare -A MAP
MAP[47]="B3"
MAP[64]="E4"
MAP[65]="F4"
MAP[67]="G4"
MAP[68]="Ab4"
MAP[70]="Bb4"
MAP[71]="B4"
MAP[72]="C5"
MAP[76]="E5"

echo "Scanning $SRC for WAV/FLAC files..."

copy_if_match() {
  local file="$1"
  local base
  base="$(basename "$file" | sed 's/\.[^.]*$//')"   # strip extension

  # Try matching by MIDI number in filename (e.g. _047_ or _64_)
  for midi in "${!MAP[@]}"; do
    if echo "$base" | grep -qE "(^|[^0-9])0*${midi}([^0-9]|$)"; then
      local target="${MAP[$midi]}.mp3"
      echo "  $file → $DEST/$target"
      if command -v ffmpeg &>/dev/null; then
        ffmpeg -y -i "$file" -ab 192k "$DEST/$target" 2>/dev/null
      else
        cp "$file" "$DEST/${MAP[$midi]}.${file##*.}"
        echo "  (copied as-is; install ffmpeg to convert to mp3)"
      fi
      return
    fi
  done
}

find "$SRC" -type f \( -iname "*.wav" -o -iname "*.flac" -o -iname "*.mp3" \) | while read -r f; do
  copy_if_match "$f"
done

echo ""
echo "Done. Files in $DEST:"
ls "$DEST"/*.mp3 "$DEST"/*.wav "$DEST"/*.ogg 2>/dev/null || echo "(none found)"
