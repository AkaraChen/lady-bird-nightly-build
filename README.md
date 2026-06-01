# Ladybird nightly packages

This repository contains a GitHub Actions workflow that builds nightly installable packages from
`https://github.com/LadybirdBrowser/ladybird`.

The workflow resolves one upstream Ladybird commit, builds all package jobs from that exact commit,
uploads the per-platform artifacts, and publishes them on a `nightly-YYYYMMDD` GitHub Release.

Current package targets:

- Linux amd64: `.deb` plus a portable `.tar.gz`
- Linux arm64: `.deb` plus a portable `.tar.gz`
- macOS x86_64: `.dmg` plus a portable `.zip`
- macOS arm64: `.dmg` plus a portable `.zip`
- Windows x64: NSIS `.exe` installer plus a portable `.zip`

The workflow also supports manual runs with a custom upstream branch, tag, or full commit SHA.
