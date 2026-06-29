#!/usr/bin/env bash
set -e

# Setup Debian/Ubuntu environment for building Android APKs
# This installs all tools needed by build.sh

echo "== Checking system packages..."
PKGS=""
# Map binary -> package
check_bin() {
  command -v "$1" >/dev/null 2>&1 || echo "$2"
}
PKGS="$PKGS $(check_bin aapt2 aapt)"
PKGS="$PKGS $(check_bin apksigner apksigner)"
PKGS="$PKGS $(check_bin zipalign android-sdk-build-tools)"
PKGS="$PKGS $(check_bin rsvg-convert librsvg2-bin)"
PKGS="$PKGS $(check_bin java openjdk-21-jdk-headless)"
PKGS="$PKGS $(check_bin wget wget)"
PKGS="$PKGS $(check_bin unzip unzip)"
PKGS="$PKGS $(check_bin zip zip)"
PKGS="$(echo "$PKGS" | xargs)"  # trim whitespace

if [ -n "$PKGS" ]; then
  echo "   Installing:$PKGS"
  sudo apt update -qq
  sudo apt install -y $PKGS
else
  echo "   All packages present"
fi

echo "== Setting up d8 (DEX compiler)..."
D8_JAR="/usr/local/share/java/d8.jar"
D8_BIN="/usr/local/bin/d8"
R8_BIN="/usr/local/bin/r8"
ANDROID_SDK="$HOME/android-sdk"
ANDROID_JAR="$ANDROID_SDK/platforms/android-30/android.jar"

if [ ! -f "$D8_JAR" ]; then
  sudo mkdir -p /usr/local/share/java
  echo "   Downloading d8.jar from Termux repo..."
  wget -q https://packages.termux.dev/apt/termux-main/pool/main/d/d8/d8_33.0.1-1_all.deb -O /tmp/d8.deb
  mkdir -p /tmp/d8_extract
  cd /tmp/d8_extract
  ar x /tmp/d8.deb
  tar xf data.tar.xz
  sudo cp data/data/com.termux/files/usr/share/java/d8.jar "$D8_JAR"
  sudo chmod 644 "$D8_JAR"
  rm -rf /tmp/d8.deb /tmp/d8_extract
  echo "   d8.jar installed"
else
  echo "   d8.jar already present"
fi

if [ ! -f "$D8_BIN" ]; then
  sudo tee "$D8_BIN" > /dev/null << 'SCRIPT'
#!/bin/sh
exec java -cp /usr/local/share/java/d8.jar com.android.tools.r8.D8 "$@"
SCRIPT
  sudo chmod +x "$D8_BIN"
  echo "   d8 wrapper created"
fi

if [ ! -f "$R8_BIN" ]; then
  sudo tee "$R8_BIN" > /dev/null << 'SCRIPT'
#!/bin/sh
exec java -cp /usr/local/share/java/d8.jar com.android.tools.r8.R8 "$@"
SCRIPT
  sudo chmod +x "$R8_BIN"
  echo "   r8 wrapper created"
fi

echo "== Setting up Android SDK platform (API 30)..."
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
for cmd in aapt2 d8 apksigner zipalign rsvg-convert java; do
  if command -v "$cmd" > /dev/null 2>&1; then
    echo "   OK  $cmd"
  else
    echo "   MISSING  $cmd"
  fi
done
if [ -f "$ANDROID_JAR" ]; then
  echo "   OK  android.jar ($ANDROID_JAR)"
else
  echo "   MISSING  android.jar"
fi
echo ""
echo "Setup complete. Run 'bash build.sh' to build the APK."
