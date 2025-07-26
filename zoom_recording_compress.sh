#!/usr/bin/env bash

# Script to compress Zoom recordings, balancing quality and file size.
# Optimized for screen sharing and talking head footage.

# Exit immediately if a command exits with a non-zero status.
# Treat unset variables as an error when substituting.
# Pipelines return the exit status of the last command to fail.
set -euo pipefail

INPUT_DIR="."
OUTPUT_DIR="./compressed"
SCALE="1280:720"     # Resize scale
FRAMERATE="12"       # Target frame rate
CRF="24"             # Constant Rate Factor (quality, lower is better, 18-28 is a good range)
AUDIO_BITRATE="96k"  # Audio bitrate for clear voice
REMOVE_AUDIO=false   # Whether to remove audio

usage() {
  echo "Usage: $0 [-i input_dir] [-o output_dir] [-s scale] [-r framerate] [-q crf] [-a audio_bitrate] [-n remove_audio]"
  echo "Example: $0 -i ./recordings -o ./out -s 1280:720 -r 12 -q 24 -a 96k"
  exit 1
}

while getopts "i:o:s:r:q:a:n:" opt; do
  case $opt in
    i) INPUT_DIR="$OPTARG" ;;
    o) OUTPUT_DIR="$OPTARG" ;;
    s) SCALE="$OPTARG" ;;
    r) FRAMERATE="$OPTARG" ;;
    q) CRF="$OPTARG" ;;
    a) AUDIO_BITRATE="$OPTARG" ;;
    n) REMOVE_AUDIO="$OPTARG" ;;
    *) usage ;;
  esac
done

command -v ffmpeg >/dev/null || { echo "❌ ffmpeg not found."; exit 1; }

mkdir -p "$OUTPUT_DIR"

VCODEC="libx264"
PRESET="slow" # Slower preset for better compression

# Use a more robust method to find and read filenames
find "$INPUT_DIR" -type f \( -iname "*.mp4" -o -iname "*.mov" -o -iname "*.mkv" \) -print0 | while IFS= read -r -d '' file; do
  base=$(basename "$file")
  name="${base%.*}"
  out="$OUTPUT_DIR/${name}_compressed_zoom.mp4"

  echo "🔄 Compressing Zoom Recording: $file → $out"

  # --- DEBUGGING ---
  # Print the exact ffmpeg command before executing it
  echo "--- DEBUG COMMAND ---"
  set -x

  if [ "$REMOVE_AUDIO" = "true" ]; then
    ffmpeg -i "$file" -vcodec "$VCODEC" -preset "$PRESET" -crf "$CRF" -r "$FRAMERATE" -vf "scale=$SCALE" -an -y "$out"
  else
    ffmpeg -i "$file" -vcodec "$VCODEC" -preset "$PRESET" -crf "$CRF" -r "$FRAMERATE" -vf "scale=$SCALE" -acodec aac -b:a "$AUDIO_BITRATE" -y "$out"
  fi

  # Disable command tracing
  set +x
  echo "--- END DEBUG ---"
  # --- END DEBUGGING ---

  if [ $? -eq 0 ]; then
    echo "✅ Done: $out"
  else
    echo "❌ Failed to compress: $file"
  fi
done

echo "🎉 All videos processed. Output saved to: $OUTPUT_DIR"
