#!/usr/bin/env bash
# Bump default.nix to the latest Zoo Design Studio release. The new version
# takes effect on the next rebuild (nixos-rebuild / home-manager switch).
set -euo pipefail
cd "$(dirname "$0")"

# jq, not grep: the grep patterns depended on exact JSON byte layout.
# Shape-check both network-derived values before they go anywhere near
# default.nix — they are interpolated into sed below.
latest=$(curl -fsSL https://api.github.com/repos/KittyCAD/modeling-app/releases/latest \
  | jq -er '.tag_name | ltrimstr("v")')
if [[ ! $latest =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "unexpected tag_name shape from GitHub API: $latest" >&2
  exit 1
fi
current=$(grep -oP 'version = "\K[^"]+' default.nix)

if [[ "$latest" == "$current" ]]; then
  echo "Already at latest version ($current)"
  exit 0
fi

echo "Updating $current -> $latest"
url="https://github.com/KittyCAD/modeling-app/releases/download/v${latest}/Zoo.Design.Studio-${latest}-x86_64-linux.AppImage"
hash=$(nix store prefetch-file --json "$url" | jq -er '.hash')
if [[ ! $hash =~ ^sha256-[A-Za-z0-9+/]+=*$ ]]; then
  echo "unexpected hash shape from nix prefetch: $hash" >&2
  exit 1
fi

sed -i "s|version = \"$current\";|version = \"$latest\";|" default.nix
sed -i "s|hash = \"sha256-[^\"]*\";|hash = \"$hash\";|" default.nix

echo "Bumped to $latest — rebuild to apply"
