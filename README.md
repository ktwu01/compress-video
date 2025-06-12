# compress-video

[![English](https://img.shields.io/badge/lang-English-blue.svg)](README.md) [![中文](https://img.shields.io/badge/lang-中文-brown.svg)](README.CN.md) ![cc-by-nc-nd](https://img.shields.io/badge/License-CC%20BY--NC--ND%204.0-lightgrey.svg) [![GitHub stars](https://img.shields.io/github/stars/ktwu01/compress-video)](https://github.com/ktwu01/compress-video) [![GitHub forks](https://img.shields.io/github/forks/ktwu01/compress-video)](https://github.com/ktwu01/compress-video/fork)


> 🧠 Compress large lecture or Zoom recordings (e.g., PhD defenses) from 2GB → 200~500MB with acceptable quality using `ffmpeg`.

---

## 💻 Environment

Tested on: **M4 MacBook** with [Homebrew](https://brew.sh/) and `ffmpeg` installed.

Install ffmpeg if needed:

```bash
brew install ffmpeg
````

---

## 🎯 Typical Use Case

> Compressing a 1-hour 720p Zoom recording (2GB) of a PhD defense, mostly static slides + voice.

**Expected output size:**

* Good quality: **300–500MB**
* Minimum acceptable: **<200MB**, using lower bitrate, framerate, and optionally removing audio

### 📊 Compression Factors

| Factor       | Explanation                                           |
| ------------ | ----------------------------------------------------- |
| Resolution   | 720p (1280×720) is already optimal                    |
| Frame rate   | Drop from 30fps → 15fps or 10fps                      |
| Codec        | H.265 (HEVC) is more efficient than H.264             |
| Audio        | Use AAC @ 64kbps or remove entirely                   |
| Content type | Static slides and talking head = high compressibility |

---

## ✅ Script 1: `compress_phd_defense.sh` (Simple Use)

### How to Use

```bash
chmod +x compress_phd_defense.sh
./compress_phd_defense.sh
```

---

## ✅ Script 2: `compress_video.sh` (Generalized Batch Tool)

Supports batch processing, adjustable parameters, and optional audio removal.

### 🔧 Features

* Compress `.mp4`, `.mov`, `.mkv` in a folder
* Adjustable bitrate, resolution, audio settings
* Optional `--remove-audio` mode
* Outputs compressed videos to `./compressed` folder by default

---

### 📦 Run with custom options

```bash
chmod +x compress_video.sh

# Example: keep audio, downscale to 720p, reduce bitrate
./compress_video.sh -i ./raw -o ./done -b 900k -s 1280:720

# Example: remove audio for max compression
./compress_video.sh -i ./zoom -o ./tiny -b 600k -s 1280:720 -n true
```

默认执行以下命令时：

```bash
./compress_video.sh
```

**输出的是 H.264 编码版本（兼容性最强）**，生成的文件名形如：

```
<原视频名>_compressed_h264.mp4
```

---

### ✅ 默认行为总结：

| 项目   | 默认值                                 |
| ---- | ----------------------------------- |
| 视频编码 | `libx264`（即 H.264）                  |
| 输出目录 | `./compressed/`                     |
| 视频码率 | `1000k`                             |
| 分辨率  | `1280x720`                          |
| 音频处理 | 保留音频（AAC 64kbps）                    |
| 适配平台 | ✅ 微信、QQ、Apple Photos、QuickTime 等都兼容 |

---

### 若希望输出更小但兼容性较差的视频：

你需要手动指定：

```bash
./compress_video.sh -x h265
```

这样会输出：

```
<原视频名>_compressed_h265.mp4
```


## 📚 Reference

Gists and experiments from the [community](https://gist.github.com/lukehedger/277d136f68b028e22bed/):

| Command                    | Result                       |
| -------------------------- | ---------------------------- |
| `-vcodec h264 -acodec mp2` | 3.6GB → 556MB, great quality |
| `-s 1280x720 -acodec copy` | 3.6GB → 62MB, good enough    |
| `-b:v 1000k -acodec mp3`   | 3.6GB → 30MB, poor quality   |
| `-b:v 700k -an`            | Best for silent slide decks  |

---

## 🤝 Contributing

Feel free to fork or open an issue/PR to improve presets, automation, or UI wrappers (e.g., Automator on macOS).
