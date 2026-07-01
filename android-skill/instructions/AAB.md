# Android App Bundle (AAB) Generation

Standalone guide for producing AAB from the CLI toolchain.
Does NOT modify build.sh — AAB uses a separate pipeline after DEX generation.

## Prerequisites

- `bundletool.jar` in `.android/`
- `jarsigner` (from JDK)
- Standard APK pipeline up to DEX generation (classes.dex)

## Setup

Run `bash setup.sh` (one-time) to download android.jar, bundletool, and create debug keystore into `.android/`.

Verify:

```bash
java -jar .android/bundletool.jar version
```

## AAB Pipeline

After you have `classes.dex` (via `d8`), follow these steps instead of linking an APK.

### 1. Link proto-format resources

Produces proto-format `AndroidManifest.xml` and `resources.pb`.

```bash
aapt2 link --proto-format -o bin/module/proto_output \
  -I .android/platforms/android-34/android.jar \
  --manifest AndroidManifest.xml \
  bin/compiled/*.flat
```

This creates `bin/module/proto_output/AndroidManifest.xml` and `bin/module/proto_output/res/` (containing `resources.pb`).

### 2. Structure module directory

```bash
mkdir -p bin/module/dex
cp classes.dex bin/module/dex/
cp bin/module/proto_output/AndroidManifest.xml bin/module/manifest/
cp bin/module/proto_output/res/resources.pb bin/module/  # optional, only if you have resources
```

Final module structure:

```
bin/module/
  manifest/
    AndroidManifest.xml    # proto-format (from aapt2 link --proto-format)
  dex/
    classes.dex            # your dex file
  resources.pb             # proto resources (omit if no resources other than manifest)
```

### 3. Package as ZIP

```bash
cd bin/module
zip -qr module.zip manifest/ dex/ resources.pb 2>/dev/null || \
  zip -qr module.zip manifest/ dex/
cd ../..
```

Omit `resources.pb` from the zip if you have no compiled resources (icon-only apps etc.).

### 4. Build AAB with bundletool

```bash
java -jar .android/bundletool.jar build-bundle \
  --modules=bin/module/module.zip \
  --output=bin/app.aab
```

### 5. Sign the AAB

AABs use `jarsigner` (NOT `apksigner`). Same debug keystore works.

```bash
jarsigner -keystore .android/debug.keystore \
  -storepass android -keypass android \
  -signedjar bin/signed.aab \
  bin/app.aab debug
```

Rename to final:

```bash
mv bin/signed.aab app.aab
```

### Full pipeline (condensed)

For a typical app with resources:

```bash
ANDROID_JAR=.android/platforms/android-34/android.jar

# Proto link
aapt2 link --proto-format -o bin/proto \
  -I "$ANDROID_JAR" --manifest AndroidManifest.xml bin/compiled/*.flat

# Structure module
mkdir -p bin/module/dex bin/module/manifest
cp bin/dex/classes.dex bin/module/dex/
cp bin/proto/AndroidManifest.xml bin/module/manifest/
[ -f bin/proto/res/resources.pb ] && cp bin/proto/res/resources.pb bin/module/

# Zip
cd bin/module
zip -qr ../module.zip manifest/ dex/ resources.pb 2>/dev/null || \
  zip -qr ../module.zip manifest/ dex/
cd ../..

# Bundle
java -jar .android/bundletool.jar build-bundle \
  --modules=bin/module.zip --output=bin/app.aab

# Sign
jarsigner -keystore .android/debug.keystore \
  -storepass android -keypass android \
  -signedjar app.aab bin/app.aab debug
```

## Verification

Check the AAB contents:

```bash
unzip -l app.aab | head -30
```

Expected structure:

```
base/manifest/AndroidManifest.xml
base/dex/classes.dex
base/resources.pb        (if resources exist)
BundleConfig.pb
BundleMetadata.pb
```

## Release Signing

For Play Store, generate a release key (one-time):

```bash
keytool -genkey -v -keystore release.keystore \
  -alias release -keyalg RSA -keysize 2048 -validity 10000 \
  -storepass <password> -keypass <password> \
  -dname "CN=YourName, OU=YourOrg, O=YourOrg, L=City, ST=State, C=Country"
```

Sign with:

```bash
jarsigner -keystore release.keystore \
  -storepass <password> -keypass <password> \
  -signedjar app-signed.aab bin/app.aab release
```

## Notes

- `--min-api` flag with `d8` causes issues — omit it
- D8 (`R8 3.3.20-dev`) crashes on anonymous inner classes — use named top-level classes + lambdas only
- bundletool requires proto-format manifest/resources (from `--proto-format`), NOT the binary format used for APKs
- Do NOT include `.flat` files in the module ZIP — only `resources.pb`
- `android:versionCode` must be present in AndroidManifest.xml (bundletool validates it)
- All tools live in `.android/` (project-local) — no $HOME dependency
