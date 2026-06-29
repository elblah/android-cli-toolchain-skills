# Android CLI Toolchain

Lightweight Android development toolchain — build native Java APKs using
AOSP command-line tools. No Gradle, no Android Studio, no IDE required.

## Skills

### [android-skill](./android-skill/)

Build native Java Android apps (API 21+) with aapt2, d8, apksigner, and
`build.sh`. Supports hybrid WebView apps with bundled HTML/JS assets.

Works on:
- **Termux** — `pkg install d8 aapt apksigner zipalign librsvg openjdk-21`
- **Debian/Ubuntu** — `bash android-skill/scripts/setup-debian.sh`
- Any Linux with Java 21+

## Structure

```
android-cli-toolchain/
  README.md              ← this file
  android-skill/         ← the skill
    SKILL.md             ← skill definition for aicoder
    templates/           ← project scaffolding templates
    instructions/        ← detailed guides
    scripts/             ← setup, scaffold helpers
```
