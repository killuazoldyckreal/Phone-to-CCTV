#!/data/data/com.termux/files/usr/bin/bash

DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_DIR="$DIR/logs"
LOG="$LOG_DIR/bridge.log"

mkdir -p "$LOG_DIR"


CAM_URL="http://127.0.0.1:4444/video/h264"
MTX_URL="rtsp://publisher:PUB_CHANGE_ME@127.0.0.1:8554/live"

command -v termux-wake-lock >/dev/null 2>&1 && termux-wake-lock

trap 'echo "[$(date "+%Y-%m-%d %H:%M:%S")] Bridge stopping..." >> "$LOG"; exit 0' TERM INT

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Bridge starting..." >> "$LOG"

while true; do
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting FFmpeg bridge..." >> "$LOG"
  ffmpeg -nostdin -loglevel warning \
    -reconnect 1 -reconnect_streamed 1 -reconnect_delay_max 2 \
    -i "$CAM_URL" \
    -c copy -an \
    -f rtsp -rtsp_transport tcp \
    "$MTX_URL"
    
  EXIT_CODE=$?
  
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] FFmpeg exited with code $EXIT_CODE. Retrying in 5 seconds..." >> "$LOG"
  sleep 5
done
