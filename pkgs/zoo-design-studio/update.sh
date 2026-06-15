#!/usr/bin/env bash
# Bump default.nix to the latest Zoo Design Studio release. The new version
# takes effect on the next rebuild (nixos-rebuild / home-manager switch).
set -euo pipefail
cd "$(dirname "$0")"

latest=$(curl -fsSL https://api.github.com/repos/KittyCAD/modeling-app/releases/latest \
  | grep -oP '"tag_name":\s*"v\K[^"]+')
current=$(grep -oP 'version = "\K[^"]+' default.nix)

if [[ "$latest" == "$current" ]]; then
  echo "Already at latest version ($current)"
  exit 0
fi

echo "Updating $current -> $latest"
url="https://github.com/KittyCAD/modeling-app/releases/download/v${latest}/Zoo.Design.Studio-${latest}-x86_64-linux.AppImage"
hash=$(nix store prefetch-file --json "$url" | grep -oP '"hash":"\K[^"]+')

sed -i "s|version = \"$current\";|version = \"$latest\";|" default.nix
sed -i "s|hash = \"sha256-[^\"]*\";|hash = \"$hash\";|" default.nix

echo "Bumped to $latest — rebuild to apply"
