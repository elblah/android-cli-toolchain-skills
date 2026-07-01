#!/usr/bin/env bash
set -e

APP="$(cd "$(dirname "$0")" && pwd)"
BIN="$APP/bin"
GEN="$APP/gen"
ANDROID_API=34
ANDROID_JAR="$HOME/android-sdk/platforms/android-$ANDROID_API/android.jar"

if [ ! -f "$ANDROID_JAR" ]; then
  mkdir -p "$(dirname "$ANDROID_JAR")"
  echo "== Downloading android-$ANDROID_API platform (one-time)..."
  wget -q https://dl.google.com/android/repository/platform-34-ext7_r03.zip -O /tmp/android-sdk.zip
  unzip -q /tmp/android-sdk.zip android-34/android.jar -d /tmp/android-sdk-out
  cp /tmp/android-sdk-out/android-34/android.jar "$ANDROID_JAR"
  rm -rf /tmp/android-sdk.zip /tmp/android-sdk-out
fi
PACKAGE="com/myapp"

if [ "${1:-}" = "clean" ]; then
  rm -rf "$BIN" "$GEN" "$APP/app.apk"
  echo "Cleaned."
  exit 0
fi

rm -rf "$BIN" "$GEN"
mkdir -p "$BIN/compiled" "$BIN/classes" "$BIN/dex" "$GEN"

echo "== Icon..."
ICON_DIRS="mipmap-mdpi mipmap-hdpi mipmap-xhdpi mipmap-xxhdpi mipmap-xxxhdpi"
ICON_SIZES="48 72 96 144 192"
for d in $ICON_DIRS; do mkdir -p "$APP/res/$d"; done
if ! command -v rsvg-convert &>/dev/null; then
  echo "rsvg-convert not found. Run 'bash scripts/setup-termux.sh' or install librsvg." >&2
  exit 1
fi
save_first="${1:-}"
set -- $ICON_SIZES
for d in $ICON_DIRS; do
  rsvg-convert -w "$1" -h "$1" "$APP/ic_launcher.svg" -o "$APP/res/$d/ic_launcher.png"
  shift
done
set -- "$save_first"

echo "== Compiling resources..."
aapt2 compile -o "$BIN/compiled" "$APP/res/values/strings.xml"
shopt -s nullglob
for f in "$APP"/res/values-*/strings.xml; do
  aapt2 compile -o "$BIN/compiled" "$f"
done
shopt -u nullglob
aapt2 compile -o "$BIN/compiled" "$APP/res/values/colors.xml"
aapt2 compile -o "$BIN/compiled" "$APP/res/values/themes.xml"
for d in $ICON_DIRS; do
  aapt2 compile -o "$BIN/compiled" "$APP/res/$d/ic_launcher.png"
done
# Add explicit aapt2 compile lines for each layout, drawable, menu file

echo "== Generating R.java..."
aapt2 link -o /dev/null \
  -I "$ANDROID_JAR" \
  --manifest "$APP/AndroidManifest.xml" \
  --java "$GEN" \
  $BIN/compiled/*.flat

echo "== Compiling Java..."
javac --release 11 -J-Xmx256m -d "$BIN/classes" -classpath "$ANDROID_JAR" \
  "$GEN/$PACKAGE/R.java" \
  "$APP/src/$PACKAGE/MainActivity.java"
# Add explicit javac lines for each Java source file

echo "== Converting to DEX..."
cd "$BIN/classes" && jar cf "$BIN/input.jar" .
cd "$APP"
d8 --lib "$ANDROID_JAR" --output "$BIN/dex" "$BIN/input.jar"

echo "== Linking APK..."
aapt2 link -o "$BIN/unsigned.apk" \
  -I "$ANDROID_JAR" \
  --manifest "$APP/AndroidManifest.xml" \
  $BIN/compiled/*.flat
# Add -A assets/ for hybrid WebView apps

echo "== Adding dex..."
cd "$BIN/dex" && zip -q "$BIN/unsigned.apk" classes.dex
cd "$APP"

echo "== Signing..."
KEYSTORE="$HOME/.android/debug.keystore"
mkdir -p "$HOME/.android"
if [ ! -f "$KEYSTORE" ]; then
  keytool -genkey -v -keystore "$KEYSTORE" \
    -alias debug -keyalg RSA -keysize 2048 -validity 10000 \
    -storepass android -keypass android -dname "CN=Debug" 2>/dev/null
fi
apksigner sign --ks "$KEYSTORE" --ks-pass pass:android \
  --ks-key-alias debug --key-pass pass:android \
  --out "$APP/app.apk" "$BIN/unsigned.apk"

echo ""
echo "APK: $APP/app.apk"
ls -lh "$APP/app.apk"

if [ "${1:-}" = "install" ]; then
  if [ -d /data/data/com.termux ]; then
    cp "$APP/app.apk" /storage/emulated/0/Download/"$(basename "$APP").apk"
    echo ""
    echo "APK copied to /storage/emulated/0/Download/$(basename "$APP").apk"
    termux-open /storage/emulated/0/Download/"$(basename "$APP").apk"
  elif command -v adb &>/dev/null; then
    adb install "$APP/app.apk"
    echo ""
    echo "APK installed via adb"
  else
    echo ""
    echo "APK ready at $APP/app.apk — install via adb or copy to device"
  fi
fi
