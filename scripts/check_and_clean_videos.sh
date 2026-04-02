#!/bin/bash

# Video file checker and cleaner for hello_video
# Validates H.264 files and handles high-resolution ones

set -euo pipefail

if [ $# -lt 1 ]; then
    echo "Usage: $0 <video_directory> [action]"
    echo ""
    echo "Actions:"
    echo "  check      - Check all files for errors (default)"
    echo "  list       - List high-resolution files (width > 1920px)"
    echo "  move       - Move high-resolution files to skipped_high_res/"
    echo ""
    echo "Examples:"
    echo "  $0 /path/to/videos check"
    echo "  $0 /path/to/videos list"
    echo "  $0 /path/to/videos move"
    exit 1
fi

VIDEOS_DIR="$1"
ACTION="${2:-check}"

if [ ! -d "$VIDEOS_DIR" ]; then
    echo "Error: Directory not found: $VIDEOS_DIR"
    exit 1
fi

echo "Processing videos in: $VIDEOS_DIR"
echo ""

case "$ACTION" in
    check)
        echo "=== Checking all H.264 files for format errors ==="
        find "$VIDEOS_DIR" -type f -name '*.h264' ! -name '._*' -exec sh -c 'echo "Checking: $1"; ffmpeg -v error -i "$1" -f null - 2>&1 || echo "ERROR in $1"' _ {} \;
        ;;
    
    list)
        echo "=== High resolution files (width > 1920px) ==="
        find "$VIDEOS_DIR" -type f -name '*.h264' ! -name '._*' -exec sh -c 'width=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=p=0 "$1" 2>/dev/null); if [ "$width" -gt 1920 ]; then echo "WARNING: $1 (width=$width px)"; fi' _ {} \;
        ;;
    
    move)
        echo "=== Moving high resolution files to skipped_high_res/ ==="
        mkdir -p "$VIDEOS_DIR/skipped_high_res"
        find "$VIDEOS_DIR" -type f -name '*.h264' ! -name '._*' -exec sh -c 'width=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=p=0 "$1" 2>/dev/null); if [ "$width" -gt 1920 ]; then echo "Moving: $1 (width=$width px)"; mv "$1" "$2/skipped_high_res/"; fi' _ {} "$VIDEOS_DIR" \;
        echo "Done. Check $VIDEOS_DIR/skipped_high_res/ for moved files."
        echo "To delete, use: rm -r $VIDEOS_DIR/skipped_high_res/*"
        ;;
    
    *)
        echo "Unknown action: $ACTION"
        exit 1
        ;;
esac
