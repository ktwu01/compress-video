#!/bin/bash

# File paths
INPUT="input.mov"
OUTPUT="output_compressed.mp4"

# Check if ffmpeg is installed
if ! command -v ffmpeg &>/dev/null; then
    echo "Error: ffmpeg is not installed."
    exit 1
fi

# Compress using H.265
ffmpeg -i "$INPUT" \
-vcodec libx265 -crf 28 -preset slow \
-r 15 \
-acodec aac -b:a 64k \
-y "$OUTPUT"

echo "✅ Compression complete: $OUTPUT"
