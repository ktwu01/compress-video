#!/usr/bin/env bash

# Universal Video Compression Script
#
# This script intelligently compresses videos by scaling them while preserving the
# original aspect ratio. It serves as the core engine for other specialized
# compression scripts in this project.

# --- Default Settings ---
INPUT_DIR="."
OUTPUT_DIR="./compressed"
MAX_RES=""           # Max resolution (longest side), e.g., 1080, 720
VIDEO_BITRATE="1000k"
AUDIO_BITRATE="64k"
FRAMERATE=""         # Frame rate, e.g., 3, 15, 24
CODEC="h264"         # Codec: h264 (default), h265
NO_AUDIO=false       # Set to true to remove audio

usage() {
  echo "Usage: $0 [options]"
  echo ""
  echo "A flexible video compression script that preserves aspect ratio."
  echo ""
  echo "Options:"
  echo "  -i, --input-dir      Input directory (default: .)"
  echo "  -o, --output-dir     Output directory (default: ./compressed)"
  echo "  -r, --max-res        Max resolution for the longest side (e.g., 1080)"
  echo "  -b, --video-bitrate  Video bitrate (e.g., 500k, 1000k)"
  echo "  -f, --framerate      Video frame rate (e.g., 3, 15, 24)"
  echo "  -a, --audio-bitrate  Audio bitrate (e.g., 32k, 64k)"
  echo "  -x, --codec          Video codec (h264 or h265; default: h264)"
  echo "  -n, --no-audio       Remove audio track (true or false)"
  echo "  -h, --help           Display this help message"
  exit 1
}

# --- Argument Parsing ---
while [[ "$#" -gt 0 ]]; do
  case $1 in
    -i|--input-dir) INPUT_DIR="$2"; shift ;;
    -o|--output-dir) OUTPUT_DIR="$2"; shift ;;
    -r|--max-res) MAX_RES="$2"; shift ;;
    -b|--video-bitrate) VIDEO_BITRATE="$2"; shift ;;
    -f|--framerate) FRAMERATE="$2"; shift ;;
    -a|--audio-bitrate) AUDIO_BITRATE="$2"; shift ;;
    -x|--codec) CODEC="$2"; shift ;;
    -n|--no-audio) NO_AUDIO="$2"; shift ;;
    -h|--help) usage ;;
    *) echo "Unknown parameter passed: $1"; usage ;;
  esac
  shift
done

# --- Pre-flight Checks ---
command -v ffmpeg >/dev/null || { echo "❌ ffmpeg not found. Please install it first."; exit 1; }
command -v ffprobe >/dev/null || { echo "❌ ffprobe not found. It is part of ffmpeg."; exit 1; }

mkdir -p "$OUTPUT_DIR"

# --- Codec Selection ---
if [ "$CODEC" = "h264" ]; then
  VCODEC="libx264"
elif [ "$CODEC" = "h265" ]; then
  VCODEC="libx265"
else
  echo "❌ Unsupported codec: $CODEC. Use 'h264' or 'h265'."
  exit 1
fi

# --- Main Processing Loop ---
find "$INPUT_DIR" -type f \( -iname "*.mp4" -o -iname "*.mov" -o -iname "*.mkv" \) -print0 | while IFS= read -r -d '' file; do
  base=$(basename "$file")
  name="${base%.*}"
  out="$OUTPUT_DIR/${name}_compressed.mp4"

  echo "🔄 Processing: $file"

  # --- Build ffmpeg command ---
  FFMPEG_CMD=("ffmpeg" "-i" "$file" "-y")

  # Video Codec
  FFMPEG_CMD+=("-vcodec" "$VCODEC" "-b:v" "$VIDEO_BITRATE")

  # Smart Scaling Logic
  if [[ -n "$MAX_RES" ]]; then
    dimensions=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 "$file")
    width=$(echo "$dimensions" | cut -d'x' -f1)
    height=$(echo "$dimensions" | cut -d'x' -f2)

    # Only scale down, never scale up
    if (( width > MAX_RES || height > MAX_RES )); then
      if (( width > height )); then
        FFMPEG_CMD+=("-vf" "scale=$MAX_RES:-2")
        echo "    Scaling to ${MAX_RES}px width (aspect ratio preserved)."
      else
        FFMPEG_CMD+=("-vf" "scale=-2:$MAX_RES")
        echo "    Scaling to ${MAX_RES}px height (aspect ratio preserved)."
      fi
    else
      echo "    Video is already within max resolution. No scaling."
    fi
  fi

  # Frame Rate
  if [[ -n "$FRAMERATE" ]]; then
    FFMPEG_CMD+=("-r" "$FRAMERATE")
  fi

  # Audio Handling
  if [ "$NO_AUDIO" = "true" ]; then
    FFMPEG_CMD+=("-an")
  else
    FFMPEG_CMD+=("-acodec" "aac" "-b:a" "$AUDIO_BITRATE")
  fi

  FFMPEG_CMD+=("$out")

  # Execute command
  "${FFMPEG_CMD[@]}" >/dev/null 2>&1 && echo "✅ Compressed successfully: $out" || echo "❌ Failed to compress: $file"

done

echo "🎉 All videos processed. Output saved to: $OUTPUT_DIR"