#!/usr/bin/env bash
# Generate a blurred copy of an image, suitable for use as a niri/swaybg background.
# Pulls magick (ImageMagick 7+) from runtimeInputs.

set -euo pipefail

if [ "$#" -lt 1 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
  cat >&2 <<EOF
Usage: blur-wallpaper <input> [output] [sigma]
  input:  source image
  output: defaults to <input-stem>-blur.<input-ext> next to <input>
  sigma:  gaussian blur strength (default 20; higher = blurrier)
EOF
  exit 1
fi

input="$1"
stem="${input%.*}"
ext="${input##*.}"
output="${2:-${stem}-blur.${ext}}"
sigma="${3:-20}"

magick "$input" -blur "0x${sigma}" "$output"
echo "wrote $output"
