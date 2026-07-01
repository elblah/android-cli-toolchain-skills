# Gradle Build (Alternative Path)

For publishing (Play Store AAB) or when you need the full Android build system.
Not the default — the fast CLI path (`build.sh`) is preferred for development.

## When to Use

| Use case | Build path |
|----------|-----------|
| Development, quick iteration | `bash build.sh` (CLI, fast) |
| Play Store release (AAB) | `bash build-gradle.sh aab` |
| Need Gradle plugins or AGP features | `bash build-gradle.sh` |
| CI/CD requiring Gradle | `bash build-gradle.sh` |

## Prerequisites

- **Java 21** (same as CLI toolchain)
- **16GB+ free space** on external storage (`EXT_DIR`) — Gradle + SDK are ~1.5GB
- `wget`, `unzip`, `zip` available

## How It Works

`build-gradle.sh` is a standalone script that:

1. Downloads Gradle 8.5 to `$EXT_DIR/gradle-8.5/` (one-time)
2. Downloads Android command-line tools + SDK to `$EXT_DIR/android-sdk/` (one-time)
3. Writes `local.properties` pointing at the SDK
4. Runs `assembleRelease` (APK) or `bundleRelease` (AAB)

### External Storage (`EXT_DIR`)

Gradle + SDK are large and live outside the project on external storage.

In the default bwrap sandbox, `/mnt/shared` is available and the script defaults to it.
When running outside sandbox (`SANDBOX=0`), set `EXT_DIR` to a writable path:

```bash
EXT_DIR=/path/to/storage bash build-gradle.sh

# Or set once in the environment:
export EXT_DIR=/path/to/storage
bash build-gradle.sh
```

On device (phone/TV box), use a writable volume:

```bash
export EXT_DIR=/storage/emulated/0  # phone internal storage
bash build-gradle.sh
```

## Platform Notes

What changes per environment:

| Environment | Java | aapt2 | EXT_DIR default |
|------------|------|-------|-----------------|
| RPi3 (bwrap sandbox) | `/usr/lib/jvm/java-21-openjdk-arm64` | Debian pkg → `/usr/lib/android-sdk/build-tools/debian/aapt2` | `/mnt/shared` |
| TV box (Termux) | `$PREFIX/lib/jvm/java-21-openjdk/` | Need ARM64 binary — download from Google's Maven manually or use AGP fallback (see aapt2 quirk) | `/storage/emulated/0` |
| Phone (Termux) | Same as TV box | Same as TV box | `/storage/emulated/0` |

On Termux (TV box / phone), the script's defaults won't match. Set env vars before running:

```bash
export JAVA_HOME=$PREFIX/lib/jvm/java-21-openjdk
export EXT_DIR=/storage/emulated/0
# aapt2: download ARM64 binary and set AAPT2_OVERRIDE in gradle.properties
```

See the aapt2 quirk section below for ARM64 workaround across all platforms.

### Build Outputs

| Target | Output |
|--------|--------|
| `apk` (default) | `build/outputs/apk/release/app-release-unsigned.apk` |
| `aab` | `build/outputs/bundle/release/app-release.aab` |

APK is unsigned — sign with `apksigner`. AAB is signed with the debug
keystore via `jarsigner` (see `instructions/AAB.md` for release signing).

## Java Setup

Java 21 is required. On Debian/ARM64 the JDK is at `/usr/lib/jvm/java-21-openjdk-arm64` and needs `LD_LIBRARY_PATH` set:

```bash
# Adjust path to match your JDK location
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-arm64
export PATH=$JAVA_HOME/bin:$PATH
export LD_LIBRARY_PATH=$JAVA_HOME/lib:$LD_LIBRARY_PATH
```

The script sets these automatically with sensible defaults.

## Memory

RPi3 has limited RAM. The script limits Gradle to 512MB heap:

```bash
export GRADLE_OPTS="-Xmx512m -Dorg.gradle.jvmargs=-Xmx512m"
```

Gradle daemon is disabled (`--no-daemon`) to avoid background memory usage.

## AGP8 Quirk: Package vs Namespace

Android Gradle Plugin 8.x requires `namespace` in `build.gradle` and **no**
`package` attribute in `AndroidManifest.xml`. Having both causes:

```
ERROR: The 'package' attribute is not allowed in the AndroidManifest.xml
when using the 'namespace' attribute in build.gradle.
```

The `build-gradle.sh` script strips `package` from the manifest before
running Gradle and restores it after — so the CLI build (`build.sh`) is
unaffected.

## AGP8 Quirk: android:exported Required

Activities with `<intent-filter>` targeting SDK 31+ must have
`android:exported` explicitly set. AGP's manifest merger enforces this;
`aapt2` CLI does not. Error:

```
Manifest merger failed : android:exported needs to be explicitly specified
for element <activity#com.example.MyActivity>.
```

Fix: add `android:exported="true"` (or `"false"` if not exposed) to every
activity that has an intent filter.

```xml
<activity android:name=".MainActivity" android:exported="true">
    <intent-filter>
        <action android:name="android.intent.action.MAIN" />
        <category android:name="android.intent.category.LAUNCHER" />
    </intent-filter>
</activity>
```

## AGP8 Quirk: aapt2 Binary Architecture

AGP downloads `aapt2` from Maven (x86_64 binary). On ARM64 (RPi3):

```
AAPT2 aapt2-8.2.2-10154469-linux Daemon #0: Unexpected error output:
x86_64-binfmt-P: Could not open '/lib64/ld-linux-x86-64.so.2'
```

**Fix**: Override with a native ARM64 `aapt2` in `gradle.properties`:

```properties
android.aapt2FromMavenOverride=/path/to/aarch64/aapt2
```

On Debian/RPi3: comes from `google-android-build-tools-installer` package at `/usr/lib/android-sdk/build-tools/debian/aapt2`.

On Termux (TV box / phone): download the ARM64 `aapt2` from Google's Maven or build from source. Place it somewhere and point `AAPT2_OVERRIDE` at it.

The script auto-creates `gradle.properties` with a default path. Edit `AAPT2_OVERRIDE` in `build-gradle.sh` or override in environment.

## Project Setup

### build.gradle

```groovy
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath 'com.android.tools.build:gradle:8.2.2'
    }
}

apply plugin: 'com.android.application'

android {
    namespace 'com.yourapp'
    compileSdk 34
    defaultConfig {
        applicationId 'com.yourapp'
        minSdk 21
        targetSdk 34
        versionCode 1
        versionName '1.0'
    }
    buildTypes {
        release {
            minifyEnabled false
        }
    }
    sourceSets {
        main {
            manifest.srcFile 'AndroidManifest.xml'
            java.srcDirs = ['src']
            // Exclude hand-written R.java — AGP generates its own
            java.exclude '**/R.java'
            res.srcDirs = ['res']
        }
    }
}
```

### settings.gradle

```groovy
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}
rootProject.name = 'yourapp'
```

### build-gradle.sh

Reference script in the project root. Key sections:

**Java setup:**
```bash
export JAVA_HOME="${JAVA_HOME:-/usr/lib/jvm/java-21-openjdk-arm64}"
export PATH="$JAVA_HOME/bin:$PATH"
export LD_LIBRARY_PATH="$JAVA_HOME/lib:${LD_LIBRARY_PATH:-}"
```

**Gradle + SDK download** (one-time to `$EXT_DIR`):
```bash
GRADLE_VERSION="8.5"
GRADLE_DIR="$EXT_DIR/gradle-$GRADLE_VERSION"
GRADLE_BIN="$GRADLE_DIR/bin/gradle"
export GRADLE_USER_HOME="$EXT_DIR/.gradle"

export ANDROID_HOME="$EXT_DIR/android-sdk"
```

**gradle.properties** (auto-created with aapt2 override):
```bash
AAPT2_OVERRIDE="/usr/lib/android-sdk/build-tools/debian/aapt2"
cat > "$APP/gradle.properties" << EOF
android.aapt2FromMavenOverride=$AAPT2_OVERRIDE
org.gradle.jvmargs=-Xmx512m
EOF
```

**Manifest fix** (strip `package` for AGP8):
```bash
if grep -q 'package=' "$MANIFEST"; then
  cp "$MANIFEST" "$MANIFEST_BAK"
  sed -i 's| package="[^"]*"||' "$MANIFEST"
fi
trap cleanup EXIT  # restore after build
```

## Adding to Existing App

1. Copy `build.gradle` and `settings.gradle` to the app dir
2. Copy `build-gradle.sh` to the app dir
3. Set `namespace` in `build.gradle` to match your app's package
4. Run `bash build-gradle.sh` — it auto-creates `local.properties` and `gradle.properties`
5. For AAB: `bash build-gradle.sh aab`
