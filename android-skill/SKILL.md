---
name: android-cli-toolchain
description: >
  Build native Java Android apps (API 21+) using AOSP CLI tools — no Gradle,
  no Android Studio. Supports hybrid WebView apps. Works on Termux, Debian/Ubuntu,
  and any Linux with Java. Two build paths: plain javac (no deps) or Maven hybrid
  (for projects needing Maven Central libraries).
---

# Android CLI Toolchain

## Overview

Build native Java Android apps (API 21+, target 30) using the AOSP command-line
toolchain. No Gradle, no Android Studio. Each app is a directory with its own
`build.sh`.

Two build paths:

| Path | When to use | Compiler | Dependencies |
|------|-------------|----------|--------------|
| **Plain** | Simple apps, no external Java deps | `javac --release 11` | Android SDK only (from local jar) |
| **Maven hybrid** | Apps needing Maven Central libs | `mvn compile` (via `pom.xml`) | Pulled from Maven Central |

Both paths share the same aapt2/d8/apksigner packaging pipeline. Pick the
simpler one that fits.

## Stack

- **Language**: Java 11 (`javac --release 11` or `mvn compile` target 11)
- **SDK**: `$HOME/android-sdk/platforms/android-30/android.jar`
- **Toolchain**: aapt2, d8 (dex), apksigner, rsvg-convert (icons)
- **Build**: `build.sh` + optionally `pom.xml`
- **Keystore**: `$HOME/.android/debug.keystore` (auto-created)

## Quick Start

### Plain path (no dependencies)

```bash
bash scripts/scaffold.sh myapp com.example.myapp
cd myapp
bash build.sh install
```

### Maven hybrid path (with dependencies)

Scaffold a plain project, then add `pom.xml` and switch the build script
to use `mvn compile` instead of `javac`. See the Maven section below.

## Directory Structure

```
myapp/
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

## Maven Hybrid Build

Use when your app needs Java libraries from Maven Central. Maven handles
compilation and dependency resolution; the aapt2/d8/apksigner pipeline
still handles packaging.

### Prerequisites

```bash
pkg install maven  # Termux
apt install maven   # Debian
```

### Project structure (Maven standard layout)

```
appname/
 pom.xml
 build.sh (calls mvn compile instead of javac)
 src/main/
  AndroidManifest.xml
  java/com/example/appname/ (Java sources + generated R.java)
  res/... (standard Android resources)
 ic_launcher.svg
```

### pom.xml

```xml
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>
  <groupId>com.example</groupId>
  <artifactId>appname</artifactId>
  <version>1.0</version>
  <packaging>jar</packaging>
  <properties>
    <maven.compiler.source>11</maven.compiler.source>
    <maven.compiler.target>11</maven.compiler.target>
  </properties>
  <dependencies>
    <dependency>
      <groupId>android</groupId>
      <artifactId>android</artifactId>
      <version>30</version>
      <scope>system</scope>
      <systemPath>${user.home}/android-sdk/platforms/android-30/android.jar</systemPath>
    </dependency>
    <!-- Add Maven Central dependencies here -->
  </dependencies>
</project>
```

### Build pipeline difference

In the build script, replace the Java compilation step:

- **Plain path**: `javac --release 11 -d bin/classes -classpath ...`
- **Maven path**: Copy generated R.java into `src/main/java/`, then `mvn -q compile`

The rest of the pipeline (aapt2 compile, aapt2 link for R.java, d8, aapt2 link for APK,
zip dex, sign) is identical.

### build.sh (Maven version)

```bash
# After aapt2 link generates R.java into $GEN:
cp -r "$GEN/"* "$JAVA_SRC/"

# Then:
mvn -q compile -f "$APP/pom.xml"

# DEX uses target/classes instead of bin/classes:
cd "$APP/target/classes" && jar cf "$BIN/input.jar" .
cd "$APP"
d8 --lib "$ANDROID_JAR" --output "$BIN/dex" "$BIN/input.jar"
```

### Adding dependencies

To use a library from Maven Central, add it to `pom.xml` under `<dependencies>`.
Maven automatically downloads transitives. No manual jar management needed.

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
`zipalign` is optional (build.sh doesn't need it). For Maven hybrid builds,
also install Maven: `pkg install maven`.

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
Install Java 17+ and get `d8.jar` as shown in `setup-debian.sh`.
The Android SDK JAR can be downloaded manually from Google's repo.

## D8 Inner-classes Restriction

`d8` **cannot merge inner classes across dex files**.
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
