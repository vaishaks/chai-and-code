"""Chai & Code — Auto-DJ Engine

Reads playlist.json, shuffles tracks, and outputs continuous raw PCM audio
on stdout for piping into ffmpeg. Writes the current track name to
now_playing.txt so overlays or dashboards can display it.
"""

import json
import os
import random
import subprocess
import sys
import signal

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
TRACKS_DIR = os.path.join(SCRIPT_DIR, "tracks")
PLAYLIST_FILE = os.path.join(TRACKS_DIR, "playlist.json")
NOW_PLAYING_FILE = os.path.join(SCRIPT_DIR, "now_playing.txt")

running = True


def signal_handler(sig, frame):
    """Gracefully stop on SIGTERM/SIGINT."""
    global running
    running = False
    sys.exit(0)


signal.signal(signal.SIGTERM, signal_handler)
signal.signal(signal.SIGINT, signal_handler)


def load_playlist():
    """Load track metadata from playlist.json."""
    with open(PLAYLIST_FILE, "r") as f:
        return json.load(f)


def update_now_playing(track):
    """Write the current track info to now_playing.txt."""
    with open(NOW_PLAYING_FILE, "w") as f:
        f.write(f"{track['title']} — {track['artist']}")


def stream_tracks():
    """Endlessly shuffle and stream tracks as raw PCM to stdout.

    Each track is decoded to s16le/44100Hz/stereo via ffmpeg and written
    to stdout chunk-by-chunk. When the full playlist has played, it
    reshuffles and starts again.
    """
    global running
    playlist = load_playlist()

    while running:
        random.shuffle(playlist)
        for track in playlist:
            if not running:
                return

            filepath = os.path.join(TRACKS_DIR, track["filename"])
            if not os.path.exists(filepath):
                continue

            update_now_playing(track)
            sys.stderr.write(f"[DJ] Now playing: {track['title']} — {track['artist']}\n")
            sys.stderr.flush()

            # Decode to raw PCM and pipe to stdout
            proc = subprocess.Popen(
                [
                    "ffmpeg", "-y", "-i", filepath,
                    "-f", "s16le", "-acodec", "pcm_s16le",
                    "-ar", "44100", "-ac", "2",
                    "-loglevel", "error",
                    "pipe:1",
                ],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            )

            try:
                while running:
                    chunk = proc.stdout.read(4096)
                    if not chunk:
                        break
                    sys.stdout.buffer.write(chunk)
                    sys.stdout.buffer.flush()
            except (BrokenPipeError, IOError):
                running = False
                proc.kill()
                return
            finally:
                proc.wait()

        sys.stderr.write("[DJ] Playlist complete, reshuffling...\n")
        sys.stderr.flush()


if __name__ == "__main__":
    sys.stderr.write("[DJ] Chai & Code Auto-DJ starting...\n")
    sys.stderr.write(f"[DJ] Loaded {len(load_playlist())} tracks\n")
    sys.stderr.flush()

    update_now_playing({"title": "Starting up...", "artist": "Chai & Code"})
    stream_tracks()
