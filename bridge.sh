#!/data/data/com.termux/files/usr/bin/bash
#
# Bridges Android IP Camera's raw H.264 HTTPS output into MediaMTX over RTSP.
# No re-encoding (-c copy) -> near-zero extra CPU/battery cost.
#
# Prereqs:
#   - Android IP Camera app running, H.264 mode, port 4444 (default)
#   - MediaMTX running locally with mediamtx.yml from this bundle
#
# Usage: ./bridge.sh

set -u

CAM_URL="http://127.0.0.1:4444/video/h264"
MTX_URL="rtsp://publisher:PUB_CHANGE_ME@127.0.0.1:8554/live"
LOG="$HOME/bridge.log"

# Keep the CPU awake while Termux is backgrounded/screen off.
command -v termux-wake-lock >/dev/null 2>&1 && termux-wake-lock

echo "$(date) : bridge starting" >> "$LOG"

while true; do
  ffmpeg -nostdin -loglevel warning \
    -reconnect 1 -reconnect_streamed 1 -reconnect_delay_max 2 \
    -i "$CAM_URL" \
    -c copy -an \
    -f rtsp -rtsp_transport tcp \
    "$MTX_URL" >> "$LOG" 2>&1

  echo "$(date) : ffmpeg exited (camera app down / network drop?), retrying in 2s" >> "$LOG"
  sleep 2
done
