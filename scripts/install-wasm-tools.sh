#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "usage: $0 <Linux|macOS|Windows> <x86_64|aarch64>" >&2
  exit 2
fi

os="$1"
arch="$2"
version="1.243.0"

case "$os" in
  Linux) os_name="linux"; extension="tar.gz" ;;
  macOS) os_name="macos"; extension="tar.gz" ;;
  Windows) os_name="windows"; extension="zip" ;;
  *)
    echo "unsupported wasm-tools OS: $os" >&2
    exit 2
    ;;
esac

name="wasm-tools-${version}-${arch}-${os_name}"
filename="${name}.${extension}"
url="https://github.com/bytecodealliance/wasm-tools/releases/download/v${version}/${filename}"

curl --fail --location --retry 3 --output "$filename" "$url"
if [ "$extension" = "zip" ]; then
  unzip -q "$filename"
else
  tar -xzf "$filename"
fi
rm "$filename"

tool_dir="$PWD/$name"
if [ -n "${GITHUB_PATH:-}" ]; then
  echo "$tool_dir" >> "$GITHUB_PATH"
else
  echo "$tool_dir"
fi
