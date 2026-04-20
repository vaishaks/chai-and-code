#!/bin/bash
# Chai & Code — Track Downloader
# Downloads all 72 royalty-free lo-fi tracks from their original sources.
#
# Usage: bash download_tracks.sh
#
# Sources:
#   - HoliznaCC0 (CC0 Public Domain) via Free Music Archive
#   - Pixabay Music (Royalty-free, no attribution required)
#
# Requirements: curl, jq

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TRACKS_DIR="${SCRIPT_DIR}/tracks"
PLAYLIST="${TRACKS_DIR}/playlist.json"

mkdir -p "$TRACKS_DIR"

if [ ! -f "$PLAYLIST" ]; then
    echo "Error: tracks/playlist.json not found"
    exit 1
fi

TOTAL=$(jq length "$PLAYLIST")
echo "=== Chai & Code Track Downloader ==="
echo "Downloading $TOTAL tracks..."
echo ""

DOWNLOADED=0
SKIPPED=0
FAILED=0

download_pixabay() {
    local filename="$1"
    local dest="${TRACKS_DIR}/${filename}"

    if [ -f "$dest" ]; then
        return 1  # skip
    fi

    # Extract Pixabay ID from filename (last number before .mp3)
    local pbid
    pbid=$(echo "$filename" | grep -oP '\d{6}(?=\.mp3$)')

    if [ -z "$pbid" ]; then
        return 2  # no ID found
    fi

    # Pixabay CDN URL pattern
    local url="https://cdn.pixabay.com/download/audio/2024/${filename}?filename=${filename}"

    # Pixabay doesn't allow direct CDN downloads without auth.
    # Use the Pixabay website to download manually, or use their API.
    echo "  ⚠  Pixabay track — download manually from:"
    echo "     https://pixabay.com/music/search/?order=ec&pagi=1&search_query=lofi"
    echo "     Save as: ${filename}"
    return 2
}

download_fma() {
    local filename="$1"
    local dest="${TRACKS_DIR}/${filename}"

    if [ -f "$dest" ]; then
        return 1  # skip
    fi

    # HoliznaCC0 track name: strip prefix and extension
    local slug
    slug=$(echo "$filename" | sed 's/^holiznacc0-//' | sed 's/\.mp3$//')

    # FMA direct download URL
    local url="https://freemusicarchive.org/track/download/${slug}/"

    if curl -fsSL -o "$dest" "$url" 2>/dev/null; then
        # Verify it's actually an MP3 (not an HTML error page)
        local ftype
        ftype=$(file -b --mime-type "$dest" 2>/dev/null)
        if [[ "$ftype" == audio/* ]]; then
            return 0
        else
            rm -f "$dest"
            return 2
        fi
    else
        rm -f "$dest"
        return 2
    fi
}

# Process each track
for i in $(seq 0 $((TOTAL - 1))); do
    filename=$(jq -r ".[$i].filename" "$PLAYLIST")
    title=$(jq -r ".[$i].title" "$PLAYLIST")
    artist=$(jq -r ".[$i].artist" "$PLAYLIST")

    printf "[%d/%d] %s — %s ... " "$((i + 1))" "$TOTAL" "$title" "$artist"

    if [ -f "${TRACKS_DIR}/${filename}" ]; then
        echo "✓ exists"
        SKIPPED=$((SKIPPED + 1))
        continue
    fi

    if [[ "$filename" == holiznacc0-* ]]; then
        if download_fma "$filename"; then
            echo "✓ downloaded"
            DOWNLOADED=$((DOWNLOADED + 1))
        else
            echo "✗ failed (try manually from FMA)"
            FAILED=$((FAILED + 1))
        fi
    else
        echo "✗ Pixabay — manual download needed"
        FAILED=$((FAILED + 1))
    fi
done

echo ""
echo "=== Summary ==="
echo "Downloaded: $DOWNLOADED"
echo "Already existed: $SKIPPED"
echo "Need manual download: $FAILED"
echo ""

if [ "$FAILED" -gt 0 ]; then
    echo "For Pixabay tracks, download from: https://pixabay.com/music/search/?order=ec&search_query=lofi"
    echo "For FMA tracks, download from: https://freemusicarchive.org/music/holiznacc0"
    echo "Save files to: ${TRACKS_DIR}/"
fi

echo ""
echo "Total tracks in playlist: $TOTAL"
echo "Tracks on disk: $(ls "$TRACKS_DIR"/*.mp3 2>/dev/null | wc -l)"
