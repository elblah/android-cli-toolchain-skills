#!/usr/bin/env bash
set -e

# Setup Termux environment for building Android APKs
# One-time setup. Re-run if tools are missing.

echo "== Installing packages..."
pkg install -y d8 aapt aapt2 apksigner librsvg openjdk-21 2>&1 | tail -3

echo "== Setting up Android SDK platform (API 30)..."
ANDROID_SDK="$HOME/android-sdk"
ANDROID_JAR="$ANDROID_SDK/platforms/android-30/android.jar"

if [ ! -f "$ANDROID_JAR" ]; then
  mkdir -p "$ANDROID_SDK/platforms/android-30"
  echo "   Downloading android-30 platform..."
  wget -q https://dl.google.com/android/repository/platform-30_r03.zip -O /tmp/platform-30.zip
  unzip -q /tmp/platform-30.zip -d /tmp/platform-30
  cp /tmp/platform-30/*/android.jar "$ANDROID_JAR"
  rm -rf /tmp/platform-30.zip /tmp/platform-30
  echo "   android.jar installed"
else
  echo "   android.jar already present"
fi

echo "== Creating debug keystore (if missing)..."
KEYSTORE="$HOME/.android/debug.keystore"
mkdir -p "$HOME/.android"
if [ ! -f "$KEYSTORE" ]; then
  keytool -genkey -v -keystore "$KEYSTORE" \
    -alias debug -keyalg RSA -keysize 2048 -validity 10000 \
    -storepass android -keypass android -dname "CN=Debug" 2>/dev/null
  echo "   debug keystore created"
else
  echo "   debug keystore exists"
fi

echo ""
echo "== Verification == "
for cmd in aapt2 d8 apksigner rsvg-convert java; do
  if command -v "$cmd" > /dev/null 2>&1; then
    echo "   OK  $cmd"
  else
    echo "   MISSING  $cmd"
  fi
done
# zipalign is optional (not used by build.sh)
if command -v zipalign > /dev/null 2>&1; then
  echo "   OK  zipalign"
fi
if [ -f "$ANDROID_JAR" ]; then
  echo "   OK  android.jar ($ANDROID_JAR)"
else
  echo "   MISSING  android.jar"
fi
echo ""
echo "Setup complete. Run 'bash build.sh' to build the APK."
