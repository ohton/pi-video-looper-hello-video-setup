#!/bin/bash

# Create m3u files for each directory in the given folder hierarchy
# - m3u file name  : <folder_name>.m3u
# - m3u location   : parent directory of the folder (same level as the folder)
# - m3u contents   : relative paths (from the m3u location) to all .h264 files
#                    found recursively inside the folder
#
# Usage: create_m3u.sh <target_directory>

set -euo pipefail

TARGET_DIR="${1:-.}"
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: '$TARGET_DIR' is not a directory" >&2
    exit 1
fi

find "$TARGET_DIR" -type d | sort | while IFS= read -r dir; do
    parent_dir="$(dirname "$dir")"
    folder_name="$(basename "$dir")"
    m3u_file="$parent_dir/$folder_name.m3u"

    # Skip if there are no .h264 files in this directory tree
    if ! find "$dir" -type f -name "*.h264" | grep -q .; then
        continue
    fi

    find "$dir" -type f -name "*.h264" | sort | while IFS= read -r file; do
        # Relative path from parent_dir (= same location as the m3u file)
        echo "${file#$parent_dir/}"
    done > "$m3u_file"

    echo "Created: $m3u_file"
done
