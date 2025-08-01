#!/usr/bin/env bash

# Compresses videos for academic purposes (lectures, presentations).
# Optimizes for clear text and voice at a very low frame rate.

# Find the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Call the main compression script with academic-specific presets
"$SCRIPT_DIR/video_compress.sh" \
    --max-res 1080 \
    --framerate 3 \
    --video-bitrate 500k \
    --audio-bitrate 64k

