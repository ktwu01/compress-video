# 推荐：兼容微信 / Apple 系统的通用版本
./compress_video.sh -i ./raw -o ./done -b 1000k -s 1280:720 -x h264

# 极限压缩版本（需兼容性注意）
./compress_video.sh -i ./raw -o ./tiny -b 600k -s 1280:720 -x h265 -n true
