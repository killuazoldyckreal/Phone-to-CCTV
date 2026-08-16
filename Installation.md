# Phone to CCTV

Turn an Android phone into a LAN CCTV camera using:

**Android IP Camera → FFmpeg Bridge → MediaMTX → WebRTC/HLS → Browser Viewer**

## Folder Structure

```text
~/Phone-to-CCTV/
│
├── start.sh
├── stop.sh
├── status.sh
│
├── bridge.sh
│
├── logs/                  # Created automatically
├── .pids/                 # Created automatically
│
├── mediamtx/
│   ├── mediamtx
│   └── mediamtx.yml
│
└── viewer/
    ├── server.js
    ├── viewer.html
    └── hls.min.js
```

---

# Requirements

## 1. Termux

- Install the Termux app from [F-Droid](https://f-droid.org/en/packages/com.termux/#suggested) or [Github](https://github.com/termux/termux-app/releases/latest).

Install the required packages in Termux:

```bash
pkg update && pkg upgrade
pkg install ffmpeg nodejs git util-linux
```

Clone the repo
```bash
cd ~ && git clone https://github.com/killuazoldyckreal/Phone-to-CCTV.git
```

Make sure the following files are executable:

```bash
cd ~/Phone-to-CCTV

chmod +x start.sh
chmod +x stop.sh
chmod +x status.sh
chmod +x bridge.sh
chmod +x mediamtx/mediamtx
```

---

## 2. Android IP Camera

- Install the Android IP Camera app from [F-Droid](https://f-droid.org/en/packages/com.github.digitallyrefined.androidipcamera/#latest) or [Github](https://github.com/DigitallyRefined/android-ip-camera/releases/latest).
- Keep screen off while streaming: On
- The camera stream should be available at:

```text
http://127.0.0.1:4444/video/h264
```

The exact URL must match the `CAM_URL` configured inside `bridge.sh`.

---

# Configure MediaMTX Authentication

Before starting the system, change the default passwords.

Edit:

```text
~/Phone-to-CCTV/mediamtx/mediamtx.yml
```

Then make sure the publishing credentials in `bridge.sh` match the MediaMTX configuration.

For example:

```bash
MTX_URL="rtsp://publisher:PUB_CHANGE_ME@127.0.0.1:8554/live"
```

The username(here 'publisher') and password(here 'PUB_CHANGE_ME') must match the publisher credentials configured in `mediamtx.yml`.

Viewer credentials must also match the credentials used when logging into `viewer.html`.

---

# Start the CCTV System

Start everything with:

```bash
cd ~/Phone-to-CCTV
./start.sh
```

This automatically starts:

1. MediaMTX
2. FFmpeg camera bridge
3. Node.js viewer server

The script also attempts to acquire a Termux wakelock to help keep the system running while the screen is off.

After starting, check the status with:

```bash
./status.sh
```

Example:

```text
========================================
         PHONE TO CCTV STATUS
========================================

mediamtx:    RUNNING (PID 12345)
bridge:      RUNNING (PID 12346)
viewer:      RUNNING (PID 12347)
```

---

# Open the Viewer

Go to the phone ip provided by the start.sh:

```text
http://PHONE-IP:8080/
```

Example:

```text
http://192.168.1.25:8080/
```

Log in using the viewer username and password present in:

```text
mediamtx/mediamtx.yml
```

The viewer first attempts to play the stream using **WebRTC** for low latency.

If WebRTC fails, it automatically falls back to **HLS**.

---

# Check System Status

Run:

```bash
cd ~/Phone-to-CCTV
./status.sh
```

This checks:

* MediaMTX
* FFmpeg bridge
* Viewer server

It also displays matching running processes and the locations of the log files.

Logs are stored in:

```text
~/Phone-to-CCTV/logs/
```

Available logs:

```text
logs/mediamtx.log
logs/bridge.log
logs/viewer.log
```

To watch a log in real time:

```bash
tail -f logs/bridge.log
```

or:

```bash
tail -f logs/mediamtx.log
```

---

# Stop the CCTV System

Stop all services cleanly with:

```bash
cd ~/Phone-to-CCTV
./stop.sh
```

The script stops:

1. Viewer server
2. Camera bridge
3. MediaMTX

It also releases the Termux wakelock if available.

---

# Optional Configurations and Quick Tips

## Start Automatically After Opening Termux

If you want to quickly start the system whenever needed:

```bash
cd ~/Phone-to-CCTV && ./start.sh
```

You can also create a shortcup shell alias:

```bash
echo 'alias cctv="cd ~/Phone-to-CCTV && ./start.sh"' >> ~/.bashrc
```

Reload the shell:

```bash
source ~/.bashrc
```

Then simply run:

```bash
cctv
```

To stop:

```bash
cd ~/Phone-to-CCTV && ./stop.sh
```

---

## Direct Stream URLs

These URLs can be used for testing.

Replace `PHONE-IP` with your phone's local IP address.

### RTSP

For VLC or FFplay:

```text
rtsp://viewer:VIEW_PASSWORD@PHONE-IP:8554/live
```

Example:

```bash
ffplay -fflags nobuffer -flags low_delay \
rtsp://viewer:VIEW_PASSWORD@PHONE-IP:8554/live
```

### HLS

```text
http://PHONE-IP:8888/live/index.m3u8
```

### WebRTC Test Page

```text
http://PHONE-IP:8889/live
```

### Browser Viewer

```text
http://PHONE-IP:8080/
```

---

# Troubleshooting

## Reminder
- **Multicast:** MediaMTX doesn't multicast RTSP by default on Android's Wi-Fi stack in a phone-as-AP scenario; if 25–50 viewers saturate the LAN, the practical fix is usually a dedicated 5GHz AP/router rather than multicast, since most consumer Wi-Fi APs handle multicast poorly. Revisit only if a real router is in the loop.
> [!NOTE]
> **Thermal/power:** the encode happens once (hardware H.264 in the camera app) and the bridge only stream-copies, so CPU load shouldn't scale with viewer count — MediaMTX fans out the same encoded packets. If temps still climb, drop to 720p@20fps or 1.5 Mbps first before touching the resolution roadmap for 1080p.

## Camera is not streaming

Check that the Android IP Camera app is running.

Then test the local stream:

```bash
ffplay http://127.0.0.1:4444/video/h264
```

Check the bridge log:

```bash
tail -f ~/Phone-to-CCTV/logs/bridge.log
```

---

## Viewer does not open

Check whether the Node.js server is running:

```bash
cd ~/Phone-to-CCTV
./status.sh
```

If it is stopped, restart the complete system:

```bash
./stop.sh
./start.sh
```

Check the viewer log:

```bash
tail -f logs/viewer.log
```

---

## MediaMTX is not running

Check:

```bash
tail -f ~/Phone-to-CCTV/logs/mediamtx.log
```

Make sure the binary is executable:

```bash
chmod +x ~/Phone-to-CCTV/mediamtx/mediamtx
```

You can also test it manually:

```bash
cd ~/Phone-to-CCTV/mediamtx
./mediamtx mediamtx.yml
```

---

## Phone stops the server in the background

> [!TIP]
> Disable battery optimization for:
>
> * Termux
> * Android IP Camera

Also make sure Termux wakelock is active.

The system can manually acquire one with:

```bash
termux-wake-lock
```

Release it with:

```bash
termux-wake-unlock
```
