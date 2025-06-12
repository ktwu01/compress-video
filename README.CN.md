# compress-video 中文说明

[![English](https://img.shields.io/badge/lang-English-blue.svg)](README.md) [![中文](https://img.shields.io/badge/lang-中文-brown.svg)](README.CN.md) ![cc-by-nc-nd](https://img.shields.io/badge/License-CC%20BY--NC--ND%204.0-lightgrey.svg) [![GitHub stars](https://img.shields.io/github/stars/ktwu01/compress-video)](https://github.com/ktwu01/compress-video) [![GitHub forks](https://img.shields.io/github/forks/ktwu01/compress-video)](https://github.com/ktwu01/compress-video/fork)

> 🎓 本项目用于高效压缩大型视频文件，特别适用于 PhD 答辩、Zoom 录屏、在线课程等以静态画面为主的视频场景。可将 2GB 视频压缩至 200~500MB，同时保证语音清晰、画面可辨。

---

## 📦 项目简介

该工具基于 [`ffmpeg`](https://ffmpeg.org/)，提供：

- 简洁易用的单文件脚本（`compress_phd_defense.sh`）
- 灵活可定制的批量压缩脚本（`compress_video.sh`）

支持 macOS 和 Linux 平台，推荐使用 Homebrew 安装 ffmpeg。

---

## 📥 安装 ffmpeg

```bash
brew install ffmpeg
````

---

## 🚀 快速开始

### 1. 使用 `compress_phd_defense.sh` （快速压缩）

适用于单个视频压缩，参数固定，适合新手。

```bash
chmod +x compress_phd_defense.sh
./compress_phd_defense.sh
```

会自动将 `input.mov` 压缩为 `output_compressed.mp4`。

---

### 2. 使用 `compress_video.sh` （批量处理 + 自定义）

适用于批量处理目录下所有视频，支持自定义码率、尺寸、是否保留音频等参数。

示例：

```bash
chmod +x compress_video.sh

# 压缩目录 ./zoom 中的所有视频，输出至 ./done，保留音频
./compress_video.sh -i ./zoom -o ./done -b 900k -s 1280:720

# 极限压缩，移除音频
./compress_video.sh -i ./raw -o ./tiny -b 600k -s 1280:720 -n true
```

参数说明：

| 参数   | 含义                           |
| ---- | ---------------------------- |
| `-i` | 输入目录（默认当前目录）                 |
| `-o` | 输出目录（默认 `./compressed`）      |
| `-b` | 视频码率，如 `800k`, `1000k`（越低越小） |
| `-s` | 分辨率，如 `1280:720`, `854:480`  |
| `-n` | 是否移除音频，设置为 `true` 可进一步压缩     |

---

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

## 🧪 压缩效果参考

[参考来源](https://gist.github.com/lukehedger/277d136f68b028e22bed/)

| 原始大小         | 参数              | 压缩后   | 效果   |
| ------------ | --------------- | ----- | ---- |
| 2.0GB（720p）  | `-b 1000k` + 音频 | 350MB | 保持清晰 |
| 2.0GB（720p）  | `-b 700k` + 去音频 | 180MB | 可接受  |
| 1.0GB（1080p） | `-b 600k` + 去音频 | 90MB  | 用于归档 |

---

## 🔎 使用建议

* 视频中如主要为 PPT 与语音解说，推荐关闭音频、降低帧率（如脚本中默认的 `15fps`）以获得最佳压缩比。
* 输出为 `.mp4` 格式，兼容主流平台（Google Drive, YouTube, 腾讯文档）。

---

## 🤝 欢迎贡献

你可以帮助：

* 改进默认参数
* 添加图形界面（如 macOS Automator 支持）
* 提交新的压缩预设方案（例如面向录播课程、电影、监控等不同类型视频）
