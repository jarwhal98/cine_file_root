#!/usr/bin/env zsh
set -euo pipefail

# Generate iOS AppIcon PNGs from a 1024x1024 source using macOS `sips`.
# Usage:
#   Scripts/generate_app_icons.sh [path/to/source-1024.png]
# If no argument is provided, defaults to:
#   CineFile/CineFile/Assets.xcassets/AppIcon.appiconset/source-1024.png

ROOT_DIR="$(cd "$(dirname "$0")"/.. && pwd)"
APPICONSET="$ROOT_DIR/CineFile/CineFile/Assets.xcassets/AppIcon.appiconset"
SRC_IMAGE="${1:-$APPICONSET/source-1024.png}"

if ! command -v sips >/dev/null 2>&1; then
  echo "Error: 'sips' not found. This script requires macOS 'sips'." >&2
  exit 1
fi

if [ ! -f "$SRC_IMAGE" ]; then
  echo "Error: Source image not found: $SRC_IMAGE" >&2
  echo "Provide a 1024x1024 PNG named 'source-1024.png' in the AppIcon set, or pass a path as an argument." >&2
  exit 1
fi

echo "Generating App Icons from: $SRC_IMAGE"

# Map of filename -> size(px)
typeset -A ICONS
ICONS=(
  # iPhone
  icon-iphone-20@2x.png   40
  icon-iphone-20@3x.png   60
  icon-iphone-29@2x.png   58
  icon-iphone-29@3x.png   87
  icon-iphone-40@2x.png   80
  icon-iphone-40@3x.png   120
  icon-iphone-60@2x.png   120
  icon-iphone-60@3x.png   180

  # iPad
  icon-ipad-20.png        20
  icon-ipad-20@2x.png     40
  icon-ipad-29.png        29
  icon-ipad-29@2x.png     58
  icon-ipad-40.png        40
  icon-ipad-40@2x.png     80
  icon-ipad-76.png        76
  icon-ipad-76@2x.png     152
  icon-ipad-83.5@2x.png   167

  # App Store
  icon-marketing-1024.png 1024
)

for filename size in ${(kv)ICONS}; do
  dest="$APPICONSET/$filename"
  echo " - $filename (${size}px)"
  sips -s format png -Z "$size" "$SRC_IMAGE" --out "$dest" >/dev/null
done

echo "Done. Generated icons in: $APPICONSET"
