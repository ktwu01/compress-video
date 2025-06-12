#!/usr/bin/env bash

# 通用视频压缩脚本（支持 MOV/MP4/MKV），适合 Zoom/答辩视频
# General-purpose video compression script for MOV/MP4/MKV, optimized for Zoom/lecture footage

# 默认设置（可通过参数自定义）
# Default values (can be customized via flags)
INPUT_DIR="."
OUTPUT_DIR="./compressed"
BITRATE="1000k"    # 视频码率 Video bitrate
SCALE="1280:720"   # 缩放尺寸 Resize scale
REMOVE_AUDIO=false # 是否移除音频 Remove audio (default: false)

# 打印使用说明 Usage
usage() {
  echo "Usage: $0 [-i input_dir] [-o output_dir] [-b bitrate] [-s scale] [-n remove_audio]"
  echo "Example: $0 -i ./videos -o ./out -b 800k -s 1280:720 -n true"
  exit 1
}

# 解析命令行参数 Parse CLI arguments
while getopts "i:o:b:s:n:" opt; do
  case $opt in
    i) INPUT_DIR="$OPTARG" ;;
    o) OUTPUT_DIR="$OPTARG" ;;
    b) BITRATE="$OPTARG" ;;
    s) SCALE="$OPTARG" ;;
    n) REMOVE_AUDIO="$OPTARG" ;;
    *) usage ;;
  esac
done

# 检查 ffmpeg 是否安装 Check for ffmpeg
command -v ffmpeg >/dev/null || { echo "❌ ffmpeg not found."; exit 1; }

# 创建输出目录 Create output folder
mkdir -p "$OUTPUT_DIR"

# 查找视频并压缩 Process video files
find "$INPUT_DIR" -type f \( -iname "*.mp4" -o -iname "*.mov" -o -iname "*.mkv" \) | while read -r file; do
  name=$(basename "$file")
  name_no_ext="${name%.*}"
  out="$OUTPUT_DIR/${name_no_ext}_compressed.mp4"

  echo "🔄 Compressing: $file → $out"

  # 组装 ffmpeg 命令 Build ffmpeg command
  if [ "$REMOVE_AUDIO" = "true" ]; then
    ffmpeg -i "$file" -vcodec h264 -b:v "$BITRATE" -s "$SCALE" -an -y "$out"
  else
    ffmpeg -i "$file" -vcodec h264 -b:v "$BITRATE" -s "$SCALE" -acodec aac -b:a 64k -y "$out"
  fi

  echo "✅ Done: $out"
done

echo "🎉 All videos processed. Output saved to: $OUTPUT_DIR"
