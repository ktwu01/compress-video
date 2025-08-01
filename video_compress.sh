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
  FFMPEG_CMD=("ffmpeg" "-nostdin" "-i" "$file" "-y")

  # Video Codec
  FFMPEG_CMD+=("-vcodec" "$VCODEC" "-b:v" "$VIDEO_BITRATE")

  # Smart Scaling Logic
  scale_info=""
  if [[ -n "$MAX_RES" ]]; then
    dimensions=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 "$file")
    if [[ -z "$dimensions" ]]; then
      echo "❌ Could not get video dimensions for $file. Skipping scaling."
    else
      width=$(echo "$dimensions" | cut -d'x' -f1)
      height=$(echo "$dimensions" | cut -d'x' -f2)

      # Validate width and height are numbers
      if ! [[ "$width" =~ ^[0-9]+$ ]] || ! [[ "$height" =~ ^[0-9]+$ ]]; then
        echo "❌ Invalid dimensions ($width x $height) for $file. Skipping scaling."
      else
        # Only scale down, never scale up
        if (( width > MAX_RES || height > MAX_RES )); then
          if (( width > height )); then
            FFMPEG_CMD+=("-vf" "scale=$MAX_RES:-2")
            scale_info="Scaling to ${MAX_RES}px width (aspect ratio preserved)."
          else
            FFMPEG_CMD+=("-vf" "scale=-2:$MAX_RES")
            scale_info="Scaling to ${MAX_RES}px height (aspect ratio preserved)."
          fi
        else
          scale_info="Video is already within max resolution. No scaling."
        fi
      fi
    fi
    [[ -n "$scale_info" ]] && echo "    $scale_info"
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

  # --- Progress Bar Setup ---
  progress_file=$(mktemp)
  FFMPEG_CMD+=("-progress" "$progress_file" "-nostats" "$out")

  # --- Execute and Monitor ---
  "${FFMPEG_CMD[@]}" &
  pid=$!

  # Wait a moment for the progress file to be created
  sleep 1

  # --- Get Video Duration ---
  duration_in_seconds=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$file")
  if [[ -z "$duration_in_seconds" ]] || ! [[ "$duration_in_seconds" =~ ^[0-9]+(\.[0-9]+)?$ ]] || (( $(echo "$duration_in_seconds < 1" | bc -l) )); then
    echo "⚠️ Could not get valid video duration or duration is less than 1s for $file. Skipping progress bar."
    total_duration_ms=0
  else
    total_duration_ms=${duration_in_seconds%.*}000000
  fi

  while kill -0 $pid 2>/dev/null; do
    if [[ "$total_duration_ms" -gt 0 ]]; then
      progress_time_us=$(grep "out_time_us=" "$progress_file" | tail -n1 | cut -d'=' -f2 || echo 0)
      speed=$(grep "speed=" "$progress_file" | tail -n1 | cut -d'=' -f2 | sed 's/x//' || echo 1)

      # Validate progress_time_us is a valid number
      if [[ "$progress_time_us" == "N/A" ]] || ! [[ "$progress_time_us" =~ ^[0-9]+$ ]]; then
        progress_time_us=0
      fi

      if [[ -n "$progress_time_us" && "$progress_time_us" -gt 0 ]]; then
        percent=$(( progress_time_us * 100 / total_duration_ms ))
        percent=$(( percent > 100 ? 100 : percent ))

        # Calculate ETA (handle N/A and invalid speed values)
        if [[ "$speed" == "N/A" ]] || ! [[ "$speed" =~ ^[0-9]*\.?[0-9]+$ ]] || (( $(echo "$speed <= 0" | bc -l 2>/dev/null || echo 1) )); then
          eta="--:--:--"
        else
          remaining_seconds=$(awk -v total="$duration_in_seconds" -v current="$((progress_time_us / 1000000))" -v spd="$speed" 'BEGIN { if (spd > 0) { print (total - current) / spd } else { print 0 } }')
          eta=$(date -u -r ${remaining_seconds%.*} +%H:%M:%S 2>/dev/null || echo "--:--:--")
        fi

        # Draw progress bar
        bar_length=30
        completed_length=$(( bar_length * percent / 100 ))
        remaining_length=$(( bar_length - completed_length ))
        bar=$(printf "%${completed_length}s" "" | tr ' ' '█')
        empty=$(printf "%${remaining_length}s" "")

        printf "\r    [%s%s] %d%% | ETA: %s" "$bar" "$empty" "$percent" "$eta"
      fi
    fi
    sleep 0.5
  done

  wait $pid
  exit_code=$?

  # Clean up progress bar line
  printf "\r%80s\r" ""

  if [ $exit_code -eq 0 ]; then
    echo "✅ Compressed successfully: $out"
    # macOS specific notification
    if [[ "$(uname)" == "Darwin" ]]; then
      osascript -e "display notification \"Finished compressing ${base}\" with title \"Compression Complete\""
      afplay /System/Library/Sounds/Glass.aiff >/dev/null 2>&1
    fi
  else
    echo "❌ Failed to compress: $file"
  fi

  rm "$progress_file"
done

echo "🎉 All videos processed. Output saved to: $OUTPUT_DIR"