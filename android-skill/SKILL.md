---
name: android-cli-toolchain
description: >
  Build native Java Android apps (API 21+) using AOSP CLI tools — no Gradle,
  no Android Studio. Supports hybrid WebView apps. Works on Termux, Debian/Ubuntu,
  and any Linux with Java.
---

# Android CLI Toolchain

## Overview

This skill enables building native Java Android apps (API 21+) using the AOSP
command-line toolchain — no Gradle, no Android Studio, no IDE required.
Also supports hybrid WebView apps with bundled HTML/JS assets.

Works on **Termux**, **Debian** / **Ubuntu**, and any Linux with Java.

## Stack

- **Language**: Java 11 (`javac --release 11`)
- **SDK**: `~/android-sdk/platforms/android-30/android.jar`
- **Toolchain**: aapt2, d8, apksigner, zipalign, rsvg-convert
- **Build**: Custom `build.sh` per project (see `templates/`)
- **Keystore**: `~/.android/debug.keystore` (auto-created if missing)

## Setup

Install the toolchain for your environment:

### Termux (Android)
```
pkg install d8 aapt apksigner zipalign librsvg openjdk-21
```

### Debian / Ubuntu (Linux)
```bash
bash scripts/setup-debian.sh
```
One-time setup. Installs all packages (aapt2, apksigner, zipalign, rsvg-convert,
Java 21) and pulls d8 (DEX compiler) from the Termux repo. Only re-run if
tools are missing (the AI will detect and call this automatically).

### Other Linux
Install Java 21+, then get d8.jar from the Termux repo or AOSP prebuilts,
or try `scripts/setup-debian.sh` if on a Debian-based system.

## Directory Structure

This skill contains:
- `templates/`      — File templates for scaffolding a new project
- `instructions/`   — Detailed guides (architecture, build, java, resources)
- `scripts/`        — Helper scripts (scaffold, setup-debian.sh)

## How to Use

1. Run setup for your platform (see above)
2. Read `instructions/ARCHITECTURE.md` for project structure
3. Read `instructions/BUILD.md` for the build pipeline
4. Read `instructions/JAVA.md` for Java patterns and the D8 bug
5. Read `instructions/RESOURCES.md` for resource organization
6. Read `instructions/THEMING.md` for dark theme patterns
7. Read `instructions/HYBRID.md` for WebView/hybrid app patterns
8. Use `templates/` as the starting point for any new project

## Quick Start

```
mkdir myapp && cd myapp
cp -r ../android-skill/templates/* .
# Edit AndroidManifest.xml, layouts, and Java sources
bash build.sh install
```
