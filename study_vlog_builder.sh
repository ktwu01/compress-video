#!/usr/bin/env bash
# Study vlog builder:
#   * reads MP4 sources from INPUT_DIR without modifying them,
#   * converts them to 720x1080 outputs under OUTPUT_DIR,
#   * adds a cover text on the first frame plus a mosaic on the bottom 40%.

set -euo pipefail

# Input folder contains originals; we only read from it.
INPUT_DIR="/Users/kw35262/Documents/TODOcapcut/Study-DJI"
# INPUT_DIR="Study-test"
OUTPUT_DIR="Study-vlogs"
FONT_FILE="/System/Library/Fonts/Supplemental/Arial Bold.ttf"

command -v ffmpeg >/dev/null || {
  echo "ffmpeg is required but not installed." >&2
  exit 1
}

mkdir -p "$OUTPUT_DIR"

if [[ ! -d "$INPUT_DIR" ]]; then
  echo "Input directory '$INPUT_DIR' was not found." >&2
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

  text_filters="scale=720:1080:force_original_aspect_ratio=decrease,pad=720:1080:(720-iw)/2:(1080-ih)/2"
  text_filters+=",split=2[base][mosaic_tmp];"
  text_filters+="[mosaic_tmp]crop=iw:ih*0.4:0:ih-ih*0.4,scale=iw/12:ih/12:flags=neighbor,scale=iw*12:ih*12:flags=neighbor[mosaic];"
  text_filters+="[base][mosaic]overlay=0:H-h[with_mosaic];"
  text_filters+="[with_mosaic]drawtext=fontfile=${FONT_FILE}:text='Study Vlog':x=(w-text_w)/2:y=(h-text_h)/2-50:fontsize=94:fontcolor=white:box=1:boxcolor=black@0.55:boxborderw=40:enable='eq(n,0)'"
  text_filters+=",drawtext=fontfile=${FONT_FILE}:text='${overlay_date}':x=(w-text_w)/2:y=(h-text_h)/2+60:fontsize=78:fontcolor=white:box=1:boxcolor=black@0.55:boxborderw=40:enable='eq(n,0)'"

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
