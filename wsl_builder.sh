#!/usr/bin/env bash
# Study vlog builder (WSL Version):
#   * reads MP4 sources from INPUT_DIR (Windows path mounted in WSL)
#   * converts them to 720x1080 outputs under OUTPUT_DIR
#   * adds a cover text on the first frame plus a mosaic on the bottom 40%.
# Create a default Unix user account: ktwu01
# New password: (8bits)
# To run a command as administrator (user "root"), use "sudo <command>".
# See "man sudo_root" for details.


set -euo pipefail

# --- CONFIGURATION ---

# Windows User Path Mapping
# Current Windows Path: C:\Users\hp\Documents\dev\compress-video
# WSL Path: /mnt/c/Users/hp/Documents/dev/compress-video

# Input folder contains originals
# Adjust this if your source videos are elsewhere. 
# Example: If they are in a "Study-DJI" folder inside the current project:
INPUT_DIR="/mnt/c/Users/hp/Downloads/Study-DJI"

# Output folder
OUTPUT_DIR="/mnt/c/Users/hp/Downloads/Study-Vlogs"

# Font File
# We use the Windows Arial font, accessible via /mnt/c/
FONT_FILE="/mnt/c/Windows/Fonts/arialbd.ttf"

# ---------------------

command -v ffmpeg >/dev/null || {
  echo "ffmpeg is required but not installed in WSL." >&2
  echo "Run: sudo apt update && sudo apt install ffmpeg" >&2
  exit 1
}

mkdir -p "$OUTPUT_DIR"

if [[ ! -d "$INPUT_DIR" ]]; then
  echo "Input directory '$INPUT_DIR' was not found." >&2
  echo "Please create it or update the INPUT_DIR variable in the script." >&2
  exit 1
fi

files=()
while IFS= read -r file; do
  files+=("$file")
done < <(find "$INPUT_DIR" -maxdepth 1 -type f -iname "*.mp4" | sort)

if [[ ${#files[@]} -eq 0 ]]; then
  echo "No MP4 files found in '$INPUT_DIR'." >&2
  exit 1
fi

current_date=""
current_count=0

for src in "${files[@]}"; do
  base_name="$(basename "$src")"
  trimmed="${base_name%.*}"
  # Logic: Extract date from filename (e.g. ..._2023100101_...)
  metadata_chunk="${trimmed#*_}"

  if [[ "$metadata_chunk" =~ ^([0-9]{8})([0-9]+)_ ]]; then
    shoot_date="${BASH_REMATCH[1]}"
  else
    echo "Skipping '$src' (unexpected filename pattern)" >&2
    continue
  fi

  if [[ "$shoot_date" != "$current_date" ]]; then
    current_date="$shoot_date"
    current_count=1
  else
    ((current_count++))
  fi

  printf -v outfile "Studying_Vlog_%s_%02d.mp4" "$shoot_date" "$current_count"
  dest="$OUTPUT_DIR/$outfile"

  overlay_date="${shoot_date} #$(printf '%02d' "$current_count")"
  echo "Processing '$src' -> '$dest' with title date '${overlay_date}'"

  # Verify font exists
  if [[ ! -f "$FONT_FILE" ]]; then
     # Fallback for some Windows installations where arialbd.ttf might be named differently or capitalized
     if [[ -f "/mnt/c/Windows/Fonts/Arial.ttf" ]]; then
        FONT_FILE="/mnt/c/Windows/Fonts/Arial.ttf"
     elif [[ -f "/mnt/c/Windows/Fonts/arial.ttf" ]]; then
        FONT_FILE="/mnt/c/Windows/Fonts/arial.ttf"
     else
        echo "Warning: Font file not found at $FONT_FILE. Text overlay might fail."
     fi
  fi

  text_filters="scale=720:1080:force_original_aspect_ratio=decrease,pad=720:1080:(720-iw)/2:(1080-ih)/2"
  text_filters+=",split=2[base][mosaic_tmp];"
  text_filters+="[mosaic_tmp]crop=iw:ih*0.4:0:ih-ih*0.4,scale=iw/12:ih/12:flags=neighbor,scale=iw*12:ih*12:flags=neighbor[mosaic];"
  text_filters+="[base][mosaic]overlay=0:H-h[with_mosaic];"
  
  # Note: Escape single quotes in drawtext if necessary. Here we use strict quoting.
  # We must handle the path to fontfile carefully in ffmpeg filters.
  # ffmpeg inside WSL might complain about Windows paths if not handled, 
  # but standard /mnt/c/... paths usually work fine.
  
  text_filters+="[with_mosaic]drawtext=fontfile='${FONT_FILE}':text='Study Vlog':x=(w-text_w)/2:y=(h-text_h)/2-50:fontsize=94:fontcolor=white:box=1:boxcolor=black@0.55:boxborderw=40:enable='eq(n,0)'"
  text_filters+=",drawtext=fontfile='${FONT_FILE}':text='${overlay_date}':x=(w-text_w)/2:y=(h-text_h)/2+60:fontsize=78:fontcolor=white:box=1:boxcolor=black@0.55:boxborderw=40:enable='eq(n,0)'"

  ffmpeg \
    -hide_banner -loglevel error \
    -y \
    -i "$src" \
    -vf "$text_filters" \
    -c:v libx264 -preset medium -crf 20 \
    -c:a aac -b:a 160k \
    "$dest"
done

echo "All videos written to '$OUTPUT_DIR'."

