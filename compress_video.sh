#!/usr/bin/env bash

# 通用视频压缩脚本（支持 MOV/MP4/MKV），适合 Zoom/答辩视频
# General-purpose video compression script for MOV/MP4/MKV, optimized for Zoom/lecture footage

INPUT_DIR="."
OUTPUT_DIR="./compressed"
BITRATE="1000k"      # 视频码率 Video bitrate
SCALE="1280:720"     # 缩放尺寸 Resize scale
REMOVE_AUDIO=false   # 是否移除音频 Remove audio
CODEC="h264"         # 编码格式: h264 (兼容性高), h265 (压缩更小)

usage() {
  echo "Usage: $0 [-i input_dir] [-o output_dir] [-b bitrate] [-s scale] [-n remove_audio] [-x codec]"
  echo "Example: $0 -i ./videos -o ./out -b 800k -s 1280:720 -x h265 -n true"
  echo "Codec options: h264 (default), h265"
  exit 1
}

while getopts "i:o:b:s:n:x:" opt; do
  case $opt in
    i) INPUT_DIR="$OPTARG" ;;
    o) OUTPUT_DIR="$OPTARG" ;;
    b) BITRATE="$OPTARG" ;;
    s) SCALE="$OPTARG" ;;
    n) REMOVE_AUDIO="$OPTARG" ;;
    x) CODEC="$OPTARG" ;;
    *) usage ;;
  esac
done

command -v ffmpeg >/dev/null || { echo "❌ ffmpeg not found."; exit 1; }

mkdir -p "$OUTPUT_DIR"

# 根据编码器选择 ffmpeg 参数
if [ "$CODEC" = "h264" ]; then
  VCODEC="libx264"
elif [ "$CODEC" = "h265" ]; then
  VCODEC="libx265"
else
  echo "❌ Unsupported codec: $CODEC. Use 'h264' or 'h265'."
  exit 1
fi

find "$INPUT_DIR" -type f \( -iname "*.mp4" -o -iname "*.mov" -o -iname "*.mkv" \) | while read -r file; do
  base=$(basename "$file")
  name="${base%.*}"
  out="$OUTPUT_DIR/${name}_compressed_${CODEC}.mp4"

  echo "🔄 Compressing: $file → $out"

  if [ "$REMOVE_AUDIO" = "true" ]; then
    ffmpeg -i "$file" -vcodec "$VCODEC" -b:v "$BITRATE" -s "$SCALE" -an -y "$out"
  else
    ffmpeg -i "$file" -vcodec "$VCODEC" -b:v "$BITRATE" -s "$SCALE" -acodec aac -b:a 64k -y "$out"
  fi

  echo "✅ Done: $out"
done

echo "🎉 All videos processed. Output saved to: $OUTPUT_DIR"
