#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 4 ]; then
  echo "usage: $0 <install-dir> <dist-dir> <x86_64|arm64> <upstream-sha>" >&2
  exit 2
fi

install_dir="$1"
dist_dir="$2"
arch="$3"
upstream_sha="$4"

app_path="$install_dir/bundle/Ladybird.app"
if [ ! -d "$app_path" ]; then
  app_path="$(find "$install_dir" -maxdepth 4 -type d -name 'Ladybird.app' -print -quit)"
fi

if [ -z "$app_path" ] || [ ! -d "$app_path" ]; then
  echo "could not find Ladybird.app under $install_dir" >&2
  exit 1
fi

mkdir -p "$dist_dir"
asset_base="Ladybird-nightly-macos-${arch}"

codesign --force --deep --sign - "$app_path"

ditto -c -k --sequesterRsrc --keepParent "$app_path" "$dist_dir/${asset_base}.zip"

dmg_root="$(mktemp -d)"
trap 'rm -rf "$dmg_root"' EXIT

cp -R "$app_path" "$dmg_root/Ladybird.app"
ln -s /Applications "$dmg_root/Applications"
cat > "$dmg_root/BUILD.txt" <<EOF
Ladybird nightly build
Upstream commit: $upstream_sha
Architecture: $arch
EOF

hdiutil create \
  -volname "Ladybird Nightly" \
  -srcfolder "$dmg_root" \
  -ov \
  -format UDZO \
  "$dist_dir/${asset_base}.dmg"
