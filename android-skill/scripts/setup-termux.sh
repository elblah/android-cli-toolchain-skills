#!/usr/bin/env bash
set -e

# Setup Termux environment for building Android APKs
# One-time setup. Re-run if tools are missing.

echo "== Installing packages..."
pkg install -y d8 aapt aapt2 apksigner librsvg openjdk-21 2>&1 | tail -3

echo "== Setting up Android SDK platform (API 34)..."
ANDROID_SDK="$HOME/android-sdk"
ANDROID_JAR="$ANDROID_SDK/platforms/android-34/android.jar"

if [ ! -f "$ANDROID_JAR" ]; then
  mkdir -p "$ANDROID_SDK/platforms/android-34"
  echo "   Downloading android-34 platform..."
  wget -q https://dl.google.com/android/repository/platform-34-ext7_r03.zip -O /tmp/platform-34.zip
  unzip -q /tmp/platform-34.zip android-34/android.jar -d /tmp/platform-34
  cp /tmp/platform-34/android-34/android.jar "$ANDROID_JAR"
  rm -rf /tmp/platform-34.zip /tmp/platform-34
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
