---
name: android-cli-toolchain
description: >
  Build native Java Android apps (API 21+) using AOSP CLI tools — no Gradle,
  no Android Studio. Supports hybrid WebView apps. Works on Termux, Debian/Ubuntu,
  and any Linux with Java.
---

# Android CLI Toolchain

## Overview

Build native Java Android apps (API 21+, target 30) using the AOSP command-line
toolchain. No Gradle, no Android Studio. Each app is a directory under the
monorepo at `projs/android/<appname>/` with its own `build.sh`.

## Stack

- **Language**: Java 11 (`javac --release 11`)
- **SDK**: `$HOME/android-sdk/platforms/android-30/android.jar`
- **Toolchain**: aapt2, d8 (dex), apksigner, rsvg-convert (icons)
- **Build**: `build.sh` scaffolded from skill templates
- **Keystore**: `$HOME/.android/debug.keystore` (auto-created)

## Quick Start

```bash
# 1. Setup (one-time, platform-specific)
#    Termux:     bash scripts/setup-termux.sh
#    Debian:     bash scripts/setup-debian.sh

# 2. Scaffold a project inside the monorepo
bash scripts/scaffold.sh projs/android/myapp com.example.myapp

# 3. Build and install
cd projs/android/myapp
bash build.sh install
```

## Directory Structure

```
projs/android/
 appname/
  AndroidManifest.xml
  ic_launcher.svg
  build.sh
  src/com/example/appname/MainActivity.java
  res/
   values/   (strings.xml, colors.xml, themes.xml)
   layout/   (activity_main.xml)
   drawable/ (shape drawables)
   menu/     (action bar menus)
   mipmap-*/ (auto-generated PNG icons)

.aicoder/autoload.md   — per-project persistent memory loaded on every session
```

## Build Pipeline (build.sh)

| Step | Command | Input → Output |
|------|---------|----------------|
| 1. Icons | `rsvg-convert` | ic_launcher.svg → mipmap-*/*.png |
| 2. Resources | `aapt2 compile` | XML → bin/compiled/*.flat |
| 3. R.java | `aapt2 link` | *.flat → gen/$PACKAGE/R.java |
| 4. Java | `javac --release 11` | .java + R.java → bin/classes/*.class |
| 5. DEX | `jar cf` + `d8` | *.class → classes.dex |
| 6. APK | `aapt2 link` | *.flat → bin/unsigned.apk |
| 7. DEX in APK | `zip -q` | classes.dex → unsigned.apk |
| 8. Sign | `apksigner sign` | unsigned.apk → app.apk |

## Critical Patterns

### Locale files and empty globs
The `build.sh` uses `shopt -s nullglob` before iterating over
`res/values-*/strings.xml` so the loop silently does nothing when no locale
resource directories exist.

### $1 clobber from `set --`
The icon generation loop uses `set -- $ICON_SIZES` to iterate over icon sizes.
This overwrites `$1`. The pattern is:

```bash
save_first="${1:-}"
set -- $ICON_SIZES
for d in $ICON_DIRS; do
  rsvg-convert -w "$1" -h "$1" ...
  shift
done
set -- "$save_first"
```

Without the save/restore, `bash build.sh install` silently skips the install
step because `$1` is consumed during iteration.

### Every resource and Java file must be listed
- `build.sh` must have an explicit `aapt2 compile` line for every layout,
  drawable, and menu file it creates.
- `build.sh` must have an explicit `javac` line for every `.java` file.
- The scaffold script automatically adds the compile line for
  `activity_main.xml`.

## Setup

### Termux
```bash
bash scripts/setup-termux.sh
```
Installs: aapt2, apksigner, d8, rsvg-convert, Java 21, Android SDK API 30.
`zipalign` is optional (build.sh doesn't need it).

### Debian / Ubuntu
```bash
bash scripts/setup-debian.sh
```
Uses `apt show` to check package availability per-binary, trying multiple
package names (e.g., `aapt2`, `android-sdk-build-tools`) to handle
cross-distro naming differences. Falls back gracefully if a package is
unavailable. Downloads `d8.jar` from the Termux repo and the Android SDK
platform JAR.

### Other Linux
Install Java 17+ and get `d8.jar` from the Termux repo as shown in
`setup-debian.sh`. The Android SDK JAR can be downloaded manually from
Google's repo.

## D8 Inner-classes Restriction

`d8` from the Termux repo **cannot merge inner classes across dex files**.
Inner classes (e.g., `MyActivity$1.class`, `MyActivity$MyInner.class`) must
be in the same dex file as their outer class. Since our pipeline produces a
single `classes.dex`, this is satisfied. Avoid multi-dex setups.

## Scaffold Script

```bash
bash scripts/scaffold.sh <dest-dir> <package-name>
```

Creates a full project from templates:
- `AndroidManifest.xml` with minSdk 21, target 30
- `build.sh` with package path substituted
- `src/$PACKAGE_PATH/${AppName}Activity.java` (minimal Activity)
- `res/layout/activity_main.xml` (centered text)
- `res/values/strings.xml`, `colors.xml`, `themes.xml`
- `ic_launcher.svg` (shield icon)
- Auto-inserts the `aapt2 compile` line for the layout

Also applies the `$1` save/restore pattern to the scaffolded `build.sh`
(since it's copied from the template which already has it).

## Files in This Skill

- `templates/` — starter files for new projects (AndroidManifest.xml,
  build.sh, ic_launcher.svg, res/values/*.xml)
- `scripts/` — setup scripts (setup-termux.sh, setup-debian.sh) and
  scaffold.sh
- `instructions/` — detailed guides on architecture, build pipeline, Java
  patterns, resources, theming, and hybrid apps
