# LAN Camera Stream — Redmi Note 6 Pro

Pipeline: **Android IP Camera app** (hardware H.264 encode) → **ffmpeg bridge** (stream-copy, no re-encode) → **MediaMTX** (relay) → browser viewers (WebRTC, HLS fallback).

## 1. Install & configure Android IP Camera
- Install from F-Droid: `com.github.digitallyrefined.androidipcamera`
- In app settings: camera = rear, resolution = 1280×720, frame rate = 30, encoder = H.264, bitrate ≈ 2 Mbps, audio = off, "keep screen off while streaming" = on.
- Confirm it's serving at `https://<phone-ip>:4444/video/h264` (self-signed cert — that's expected).

## 2. Install MediaMTX in Termux
```bash
pkg install -y wget tar
LATEST=$(curl -s https://api.github.com/repos/bluenviron/mediamtx/releases/latest | grep tag_name | cut -d '"' -f4)
wget https://github.com/bluenviron/mediamtx/releases/download/${LATEST}/mediamtx_${LATEST}_linux_arm64.tar.gz
mkdir -p ~/mediamtx && tar xzf mediamtx_${LATEST}_linux_arm64.tar.gz -C ~/mediamtx
cp mediamtx.yml ~/mediamtx/       # from this bundle — edit the two passwords first
cd ~/mediamtx && ./mediamtx mediamtx.yml
```

## 3. Start the bridge (in a second Termux session)
```bash
cp bridge.sh ~/ && chmod +x ~/bridge.sh
# edit PUB_CHANGE_ME in both bridge.sh and mediamtx.yml to match
~/bridge.sh
```
Logs land in `~/bridge.log`. It auto-restarts ffmpeg if the camera app or Wi-Fi drops.

## 4. Serve the viewer page (third Termux session)
```bash
cp server.js viewer.html ~/viewer/ 2>/dev/null || (mkdir -p ~/viewer && cp server.js viewer.html ~/viewer/)
cd ~/viewer
npm install hls.js && cp node_modules/hls.js/dist/hls.min.js .   # one-time, needs internet
node server.js
```
Viewers open `http://<phone-ip>:8080/` and log in with the `viewer` / `VIEW_CHANGE_ME` credentials set in `mediamtx.yml`.

## 5. Keep it alive
- Termux → long-press notification → enable "Acquire wakelock", or the sessions running `bridge.sh` will call `termux-wake-lock` automatically.
- Disable battery optimization for Termux in Android settings, or the OS will kill the sessions when the screen is off.
- Enable "limit to 80% charge" in MIUI battery settings if running 24/7 on charger (see Android IP Camera's own warning about swelling batteries).

## Direct stream URLs (for testing without the viewer page)
| Protocol | URL |
|---|---|
| RTSP (VLC, ffplay) | `rtsp://viewer:VIEW_CHANGE_ME@<phone-ip>:8554/live` |
| HLS | `http://<phone-ip>:8888/live/index.m3u8` |
| WebRTC (MediaMTX's own test page) | `http://<phone-ip>:8889/live` |

## Roadmap test commands

**Latency check:**
```bash
ffplay -fflags nobuffer -flags low_delay rtsp://viewer:VIEW_CHANGE_ME@<phone-ip>:8554/live
```

**Viewer / reader count (MediaMTX API):**
```bash
curl -s http://<phone-ip>:9997/v3/paths/get/live | python3 -m json.tool
```

**CPU / RAM / thermal on the phone (in Termux):**
```bash
top -n 1 | head -20
cat /sys/class/thermal/thermal_zone*/temp   # values are millidegrees C
```

**Simulate N viewers from a PC** (repeat with more concurrent processes to hit 5 → 10 → 25 → 50):
```bash
for i in $(seq 1 10); do
  ffplay -loglevel quiet rtsp://viewer:VIEW_CHANGE_ME@<phone-ip>:8554/live &
done
```

**Dropped frames / bitrate:** watch `~/bridge.log` (ffmpeg prints frame= / bitrate= periodically) or check the MediaMTX API path stats above (`bytesReceived`, `readers`).

## Notes on the roadmap items
- **Step 8 (multicast):** MediaMTX doesn't multicast RTSP by default on Android's Wi-Fi stack in a phone-as-AP scenario; if 25–50 viewers saturate the LAN, the practical fix is usually a dedicated 5GHz AP/router rather than multicast, since most consumer Wi-Fi APs handle multicast poorly. Revisit only if a real router is in the loop.
- **Step 9 (thermal/power):** the encode happens once (hardware H.264 in the camera app) and the bridge only stream-copies, so CPU load shouldn't scale with viewer count — MediaMTX fans out the same encoded packets. If temps still climb, drop to 720p@20fps or 1.5 Mbps first before touching the resolution roadmap for 1080p.
