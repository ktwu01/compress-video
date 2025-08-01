# Flexible Video Compression Scripts

This project provides a set of powerful and flexible `bash` scripts for video compression, built around `ffmpeg`. The main goal is to offer smart, scenario-based compression that preserves aspect ratios and simplifies common use cases.

The core of this project is a universal `video_compress.sh` script. Other scripts are simply shortcuts that call the main script with pre-configured parameters for specific needs.

## Core Features

- **Smart Scaling**: Automatically detects video dimensions and scales it down to a maximum resolution (e.g., 1080p or 720p) **while preserving the original aspect ratio**. No more stretched or distorted videos.
- **Modular Design**: A single, powerful `video_compress.sh` script serves as the engine. Specific-use scripts like `academic_compress.sh` and `short_video_compress.sh` act as simple, easy-to-use wrappers.
- **Highly Customizable**: The main script is fully configurable via command-line flags, allowing you to control bitrate, frame rate, resolution, audio quality, and codecs.
- **Batch Processing**: All scripts automatically find and process all `MP4`, `MOV`, and `MKV` files in the current directory.

---

## Quick Start: Scenario-Based Scripts

Choose the script that best fits your needs. All compressed videos are saved to the `./compressed` directory.

### 1. Academic & Lecture Video Compression

**Use Case:** Compressing recordings of PhD defenses, Zoom meetings, or lectures where on-screen text and spoken audio must be clear, but high frame-rate motion is not important.

This mode aggressively reduces file size by lowering the frame rate, which is highly effective for presentation-style videos.

**Script:** `./academic_compress.sh`

**Compression Logic:**
- **Resolution**: Preserves aspect ratio, scaling down to a maximum of **1080p** on the longest side.
- **Frame Rate**: **3 fps** (Drastically reduces size, sufficient for slides).
- **Video Bitrate**: `500k` (Optimized for clarity at low frame rates).
- **Audio Bitrate**: `64k` (Ensures clear, understandable voice).

**Usage:**
```bash
./academic_compress.sh
```

### 2. Short Video Compression

**Use Case:** Compressing short video clips for social media or sharing, where small file size is the top priority and some quality loss is acceptable.

**Script:** `./short_video_compress.sh`

**Compression Logic:**
- **Resolution**: Preserves aspect ratio, scaling down to a maximum of **720p** on the longest side.
- **Frame Rate**: **15 fps** (Reduces size while maintaining basic fluidity).
- **Video Bitrate**: `500k` (Agressive compression for smaller files).
- **Audio Bitrate**: `32k` (Sufficient for basic audio).

**Usage:**
```bash
./short_video_compress.sh
```

---

## Advanced Usage: The Universal `video_compress.sh`

If you need more control, you can call the main script directly with your own parameters. This allows you to fine-tune every aspect of the compression.

### How It Works

The script calculates the new dimensions while maintaining the aspect ratio. For example, with `--max-res 1080`:
- A `1920x1200` video becomes `1080x675`.
- A `1080x1920` (vertical) video becomes `607x1080`.
- A `1280x720` video remains `1280x720` as it does not exceed the max resolution.

### Available Parameters

- `-i, --input-dir`: Directory containing videos to process (default: `.`).
- `-o, --output-dir`: Directory to save compressed files (default: `./compressed`).
- `-r, --max-res`: Maximum resolution for the longest side (e.g., `1080`, `720`).
- `-b, --video-bitrate`: Video bitrate (e.g., `500k`, `1000k`).
- `-f, --framerate`: Video frame rate (e.g., `3`, `15`, `24`).
- `-a, --audio-bitrate`: Audio bitrate (e.g., `32k`, `64k`).
- `-x, --codec`: Video codec (`h264` or `h265`, default: `h264`).
- `-n, --no-audio`: Set to `true` to remove the audio track.

### Example

Compress all videos in the `~/videos` directory to a max resolution of 1080p, using the H.265 codec for higher efficiency:

```bash
./video_compress.sh -i ~/videos -o ./output_folder -r 1080 -x h265
```

## Requirements

- **ffmpeg**: Must be installed and available in your system's PATH.

You can install it via Homebrew on macOS:
```bash
brew install ffmpeg
```
or via a package manager on Linux:
```bash
sudo apt update && sudo apt install ffmpeg
```