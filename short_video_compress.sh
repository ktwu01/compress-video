#!/usr/bin/env bash

# Compresses videos for sharing (e.g., social media).
# Optimizes for small file size with acceptable quality.

# Find the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Call the main compression script with short-video-specific presets
"$SCRIPT_DIR/video_compress.sh" \
    --max-res 720 \
    --framerate 15 \
    --video-bitrate 500k \
    --audio-bitrate 32k