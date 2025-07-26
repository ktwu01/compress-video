#!/usr/bin/env bash

# Script to compress Zoom recordings, balancing quality and file size.
# Optimized for screen sharing and talking head footage.

INPUT_DIR="."
OUTPUT_DIR="./compressed"
SCALE="1280:720"     # Resize scale
FRAMERATE="12"       # Target frame rate
CRF="20"             # Constant Rate Factor (quality, lower is better, 18-28 is a good range)
AUDIO_BITRATE="96k"  # Audio bitrate for clear voice
REMOVE_AUDIO=false   # Whether to remove audio

# Function to handle script interruption
cleanup() {
  echo -e "\n⚠️  Script interrupted by user. Cleaning up..."
  exit 0
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM

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

# Function to check if video has audio
has_audio() {
  local video_file="$1"
  ffprobe -v quiet -select_streams a -show_entries stream=codec_type -of csv=p=0 "$video_file" | grep -q "audio"
  return $?
}

# Function to sanitize filename for safe use in ffmpeg
sanitize_filename() {
  local filename="$1"
  # Replace spaces and special characters with underscores
  echo "$filename" | sed 's/[^a-zA-Z0-9._-]/_/g'
}

# Function to get video duration in seconds
get_video_duration() {
  local video_file="$1"
  ffprobe -v quiet -show_entries format=duration -of csv=p=0 "$video_file" | head -1
}

find "$INPUT_DIR" -type f \( -iname "*.mp4" -o -iname "*.mov" -o -iname "*.mkv" \) | while read -r file; do
  base=$(basename "$file")
  name="${base%.*}"
  
  # Create a sanitized output filename to avoid FFmpeg parsing issues
  sanitized_name=$(sanitize_filename "$name")
  out="$OUTPUT_DIR/${sanitized_name}_compressed_zoom.mp4"

  echo "🔄 Compressing Zoom Recording: $file → $out"
  
  # Get video duration for progress calculation
  duration=$(get_video_duration "$file")
  if [ -n "$duration" ] && [ "$duration" != "N/A" ]; then
    echo "📊 Video duration: ${duration}s"
  fi

  # Check if video has audio and determine ffmpeg command
  if [ "$REMOVE_AUDIO" = "true" ] || ! has_audio "$file"; then
    echo "📹 Processing video without audio..."
    # Use -nostdin to disable interactive prompts and show progress
    ffmpeg -nostdin -i "$file" -vcodec "$VCODEC" -preset "$PRESET" -crf "$CRF" -r "$FRAMERATE" -vf "scale=$SCALE" -an -y "$out" 2>&1 | while IFS= read -r line; do
      if [[ $line =~ frame=[0-9]+ ]]; then
        echo -ne "\r   Progress: $line"
      fi
    done
    echo ""  # New line after progress
    ffmpeg_exit_code=${PIPESTATUS[0]}
  else
    echo "🎵 Processing video with audio..."
    # Use -nostdin to disable interactive prompts and show progress
    ffmpeg -nostdin -i "$file" -vcodec "$VCODEC" -preset "$PRESET" -crf "$CRF" -r "$FRAMERATE" -vf "scale=$SCALE" -acodec aac -b:a "$AUDIO_BITRATE" -y "$out" 2>&1 | while IFS= read -r line; do
      if [[ $line =~ frame=[0-9]+ ]]; then
        echo -ne "\r   Progress: $line"
      fi
    done
    echo ""  # New line after progress
    ffmpeg_exit_code=${PIPESTATUS[0]}
  fi

  # Check if ffmpeg completed successfully (exit code 0) or was interrupted (exit code 130)
  if [ $ffmpeg_exit_code -eq 0 ]; then
    echo "✅ Done: $out"
  elif [ $ffmpeg_exit_code -eq 130 ]; then
    echo "⚠️  Compression interrupted by user"
    exit 0
  else
    echo "❌ Failed to compress: $file (exit code: $ffmpeg_exit_code)"
  fi
done

echo "🎉 All videos processed. Output saved to: $OUTPUT_DIR"