# Build Pipeline

## Toolchain

All tools are installed via platform-specific setup:

- **Termux**: `bash scripts/setup-termux.sh` (one-time)
- **Debian/Linux**: `bash scripts/setup-debian.sh` (one-time)

Tools:
- `aapt2` — Android Asset Packaging Tool v2
- `d8` — DEX compiler (part of R8)
- `apksigner` — APK signing tool
- `zipalign` — Zip alignment (optional, apksigner handles it)
- `rsvg-convert` — SVG to PNG conversion (from `librsvg`)
- `javac` — Java compiler (`--release 11`)
- `keytool` — Keystore generation
- `jar` — For packaging compiled classes

## SDK Location

```
$HOME/android-sdk/platforms/android-30/android.jar
```

Setup scripts download the Android API 30 platform JAR automatically.
If doing it manually: download `platform-30_r03.zip` from Google's
Android repository and extract `android.jar` to the path above.

## Summary

```
SVG → PNG icons (rsvg-convert)
XML resources → *.flat (aapt2 compile)
*.flat → R.java + unsigned APK (aapt2 link)
Java + R.java → *.class (javac)
*.class → input.jar (jar cf)
input.jar → classes.dex (d8)
classes.dex → unsigned APK (zip -q)
unsigned APK → signed APK (apksigner)
```

## Step-by-Step

### 1. Icon generation

```bash
rsvg-convert -w 48 -h 48 ic_launcher.svg -o res/mipmap-mdpi/ic_launcher.png
rsvg-convert -w 72 -h 72 ic_launcher.svg -o res/mipmap-hdpi/ic_launcher.png
rsvg-convert -w 96 -h 96 ic_launcher.svg -o res/mipmap-xhdpi/ic_launcher.png
rsvg-convert -w 144 -h 144 ic_launcher.svg -o res/mipmap-xxhdpi/ic_launcher.png
rsvg-convert -w 192 -h 192 ic_launcher.svg -o res/mipmap-xxxhdpi/ic_launcher.png
```

### 2. Resource compilation

```bash
aapt2 compile -o bin/compiled res/values/strings.xml
aapt2 compile -o bin/compiled res/values/colors.xml
aapt2 compile -o bin/compiled res/values/themes.xml
# ... repeat for every resource file, including:
# - res/drawable/*.xml
# - res/layout/*.xml
# - res/menu/*.xml
# - res/mipmap-*/*.png
```

**Locale files** must be compiled individually:

```bash
aapt2 compile -o bin/compiled res/values/strings.xml
for f in res/values-*/strings.xml; do
  aapt2 compile -o bin/compiled "$f"
done
```

### 3. Generate R.java

```bash
aapt2 link -o /dev/null \
  -I $HOME/android-sdk/platforms/android-30/android.jar \
  --manifest AndroidManifest.xml \
  --java gen/ \
  bin/compiled/*.flat
```

This creates `gen/com/myapp/R.java`.

### 4. Compile Java

All Java source files and R.java must be listed explicitly:

```bash
javac --release 11 -J-Xmx256m -d bin/classes \
  -classpath $HOME/android-sdk/platforms/android-30/android.jar \
  gen/com/myapp/R.java \
  src/com/myapp/*.java
```

### 5. Convert to DEX

```bash
cd bin/classes && jar cf bin/input.jar .
cd $APP
d8 --lib $HOME/android-sdk/platforms/android-30/android.jar \
  --output bin/dex bin/input.jar
```

### 6. Link unsigned APK

```bash
aapt2 link -o bin/unsigned.apk \
  -I $HOME/android-sdk/platforms/android-30/android.jar \
  --manifest AndroidManifest.xml \
  bin/compiled/*.flat
```

For hybrid apps with assets:

```bash
aapt2 link -o bin/unsigned.apk \
  -I $HOME/android-sdk/platforms/android-30/android.jar \
  --manifest AndroidManifest.xml \
  -A assets/ \
  bin/compiled/*.flat
```

### 7. Add DEX to APK

```bash
cd bin/dex && zip -q bin/unsigned.apk classes.dex
```

### 8. Sign

```bash
KEYSTORE=$HOME/.android/debug.keystore
mkdir -p $HOME/.android
if [ ! -f "$KEYSTORE" ]; then
  keytool -genkey -v -keystore "$KEYSTORE" \
    -alias debug -keyalg RSA -keysize 2048 -validity 10000 \
    -storepass android -keypass android -dname "CN=Debug" 2>/dev/null
fi
apksigner sign --ks "$KEYSTORE" --ks-pass pass:android \
  --ks-key-alias debug --key-pass pass:android \
  --out app.apk bin/unsigned.apk
```

### 9. Install

```bash
# On a connected device:
adb install -r app.apk

# Or copy the APK and install manually
```

## Build Script Targets

- `bash build.sh` — Build APK
- `bash build.sh clean` — Remove `bin/`, `gen/`, `app.apk`
- `bash build.sh install` — Build + copy to Downloads + open
