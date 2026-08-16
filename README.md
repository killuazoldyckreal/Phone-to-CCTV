# Phone to CCTV

Turn an Android phone into a low-latency CCTV camera for your local network.

**Phone to CCTV** uses an Android IP Camera app for video capture, FFmpeg to bridge the camera stream, MediaMTX to distribute it, and a browser-based viewer for watching the live feed.

## Features

* 📱 Uses an Android phone as the CCTV camera
* 🎥 H.264 video streaming
* ⚡ WebRTC playback for low latency
* 📺 Automatic HLS fallback
* 🔄 Automatic FFmpeg reconnection if the camera stream drops
* 🚀 Start the complete system with a single command
* 🛑 Stop all services cleanly
* 📊 Check the status of every service
* 📝 Separate logs for MediaMTX, FFmpeg, and the viewer server
* 🔋 Termux wakelock support for long-running operation
* 🌐 Browser-based viewer accessible from devices on the same LAN
* 🔐 Viewer authentication through MediaMTX

## Architecture

```text
Android Phone Camera
        │
        │ H.264 Stream
        ▼
┌─────────────────┐
│ Android IP      │
│ Camera App      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│     FFmpeg      │
│  Stream Bridge  │
│                 │
│   No Re-encode  │
└────────┬────────┘
         │
         │ RTSP
         ▼
┌─────────────────┐
│    MediaMTX     │
│                 │
│ Stream Relay    │
└──────┬─────┬────┘
       │     │
       │     │
       ▼     ▼
    WebRTC   HLS
       │     │
       └──┬──┘
          ▼
┌─────────────────┐
│ Browser Viewer  │
└─────────────────┘
```

The video is encoded by the Android IP Camera app. FFmpeg copies the H.264 stream without re-encoding, reducing additional CPU usage.

MediaMTX then distributes the same stream to browser viewers using WebRTC or HLS.

## Quick Start

After completing the installation and configuration:

```bash
cd ~/Phone-to-CCTV
./start.sh
```

This starts:

* MediaMTX
* FFmpeg camera bridge
* Browser viewer server

Check the system:

```bash
./status.sh
```

Stop everything:

```bash
./stop.sh
```

## Viewing the Camera

Open the following address from another device connected to the same local network:

```text
http://PHONE-IP:8080/
```

For example:

```text
http://192.168.1.25:8080/
```

The viewer attempts to connect using **WebRTC** for low latency.

If WebRTC is unavailable, it automatically falls back to **HLS**.

## Service Management

### Start

```bash
./start.sh
```

Starts all required services in the background.

### Status

```bash
./status.sh
```

Displays the status and PID of:

* MediaMTX
* FFmpeg bridge
* Viewer server

### Stop

```bash
./stop.sh
```

Stops all running services and releases the Termux wakelock.

## Logs

Logs are stored in:

```text
logs/
```

Available logs:

```text
logs/mediamtx.log
logs/bridge.log
logs/viewer.log
```

Watch a log in real time:

```bash
tail -f logs/bridge.log
```

## Stream Endpoints

Replace `PHONE-IP` with the Android phone's local IP address.

| Protocol        | URL                                              |
| --------------- | ------------------------------------------------ |
| Browser Viewer  | `http://PHONE-IP:8080/`                          |
| RTSP            | `rtsp://viewer:VIEW_PASSWORD@PHONE-IP:8554/live` |
| HLS             | `http://PHONE-IP:8888/live/index.m3u8`           |
| MediaMTX WebRTC | `http://PHONE-IP:8889/live`                      |

## Documentation

For complete installation, dependency setup, Android IP Camera configuration, MediaMTX configuration, authentication setup, and troubleshooting, see:

```text
INSTALLATION.md
```

## How It Works

1. The Android IP Camera app captures video and encodes it as H.264.
2. `bridge.sh` uses FFmpeg to copy the stream into MediaMTX.
3. MediaMTX receives the stream at the `live` path.
4. MediaMTX makes the stream available through RTSP, WebRTC, and HLS.
5. `server.js` serves the browser viewer.
6. `viewer.html` attempts WebRTC playback first.
7. If WebRTC fails, the viewer falls back to HLS.

## License

This project is intended for personal and local-network CCTV usage.
