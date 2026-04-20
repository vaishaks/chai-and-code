# ☕ Chai & Code

Lo-fi beats to code & chill — a 24/7 YouTube live radio stream.

## What is this?

A self-hosted lo-fi music live stream built with Python and ffmpeg. Features an auto-DJ that shuffles royalty-free lo-fi tracks, pipes audio into ffmpeg alongside a looping video, and streams to YouTube via RTMP.

## Architecture

```
dj_engine.py (shuffles playlist, decodes MP3 → raw PCM on stdout)
     │
     │ pipe (s16le, 44100Hz, stereo)
     │
ffmpeg (muxes video loop + piped audio → RTMP)
     │
     └──→ YouTube Live
```

## Setup

1. **Download music** — Run the download script to fetch all 72 royalty-free tracks:
   ```bash
   bash download_tracks.sh
   ```
   HoliznaCC0 tracks (CC0) are downloaded automatically from Free Music Archive. Pixabay tracks need manual download — the script prints direct links for each. You can also add your own tracks to `tracks/` and update `tracks/playlist.json`.

2. **Set your stream key** — Copy `.env.example` to `.env` and add your YouTube RTMP URL:
   ```
   RTMP_URL=rtmp://a.rtmp.youtube.com/live2/YOUR_STREAM_KEY
   ```

3. **Add your video loop** — Place a looping video at `video/branded_loop.mp4` (1920×1080 recommended).

4. **Start streaming:**
   ```bash
   bash stream.sh
   ```

5. **Auto-restart on crash** (optional):
   ```bash
   nohup bash watchdog.sh > logs/watchdog.log 2>&1 &
   ```

## Requirements

- Python 3.8+
- ffmpeg with libx264 and aac support
- A YouTube account with live streaming enabled

## File Structure

```
├── stream.sh            # Main stream launcher
├── watchdog.sh          # Auto-restart watchdog
├── dj_engine.py         # Auto-DJ engine
├── download_tracks.sh   # Music downloader
├── tracks/
│   ├── playlist.json    # Track metadata + source URLs
│   └── *.mp3            # Music files (not included)
├── video/
│   └── branded_loop.mp4 # Video loop
├── artwork/             # Source artwork
└── logs/                # Runtime logs
```

## How it works

- **`dj_engine.py`** loads `tracks/playlist.json`, shuffles the playlist, and decodes each track to raw PCM audio piped to stdout. It writes the current track to `now_playing.txt`.
- **`stream.sh`** launches the DJ engine piped into ffmpeg, which loops the video and encodes everything to RTMP.
- **`watchdog.sh`** polls every 30 seconds and restarts the stream if either process dies.

## Music

Tracks are not included in this repo. Run `bash download_tracks.sh` to fetch them. Each track in `tracks/playlist.json` includes source URLs and license info. The stream uses royalty-free music from:
- [HoliznaCC0](https://freemusicarchive.org/music/holiznacc0) (CC0 Public Domain)
- [Pixabay Music](https://pixabay.com/music/) (Royalty-free)

## License

MIT
