#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 5 ]; then
  echo "usage: $0 <install-dir> <dist-dir> <amd64|arm64> <version> <upstream-sha>" >&2
  exit 2
fi

install_dir="$1"
dist_dir="$2"
deb_arch="$3"
version="$4"
upstream_sha="$5"

if [ ! -d "$install_dir" ]; then
  echo "install directory does not exist: $install_dir" >&2
  exit 1
fi

asset_base="Ladybird-nightly-linux-${deb_arch}"
package_root="$(mktemp -d)"
trap 'rm -rf "$package_root"' EXIT

mkdir -p "$dist_dir"
mkdir -p "$package_root/DEBIAN"
mkdir -p "$package_root/opt/ladybird-nightly"
mkdir -p "$package_root/usr/bin"

cp -a "$install_dir/." "$package_root/opt/ladybird-nightly/"

if [ -x "$package_root/opt/ladybird-nightly/bin/Ladybird" ]; then
  ln -s /opt/ladybird-nightly/bin/Ladybird "$package_root/usr/bin/ladybird-nightly"
elif [ -x "$package_root/opt/ladybird-nightly/bin/ladybird" ]; then
  ln -s /opt/ladybird-nightly/bin/ladybird "$package_root/usr/bin/ladybird-nightly"
else
  echo "could not find Ladybird executable under $install_dir/bin" >&2
  exit 1
fi

installed_size="$(du -sk "$package_root/opt/ladybird-nightly" | awk '{print $1}')"
cat > "$package_root/DEBIAN/control" <<EOF
Package: ladybird-nightly
Version: $version
Section: web
Priority: optional
Architecture: $deb_arch
Installed-Size: $installed_size
Maintainer: Ladybird Nightly Builder <noreply@github.com>
Homepage: https://github.com/LadybirdBrowser/ladybird
Description: Nightly Ladybird browser build
 Built from Ladybird upstream commit $upstream_sha.
EOF

dpkg-deb --build --root-owner-group "$package_root" "$dist_dir/${asset_base}.deb"
tar -C "$install_dir" -czf "$dist_dir/${asset_base}.tar.gz" .
