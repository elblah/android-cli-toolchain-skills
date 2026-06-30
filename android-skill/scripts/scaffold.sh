#!/usr/bin/env bash
# Scaffold a new Android project from the skill templates
# Usage: bash scaffold.sh /path/to/new-project com.myapp.MyActivity

set -e

DEST="${1:-}"
PACKAGE="${2:-com.myapp}"

if [ -z "$DEST" ] || [ -z "$PACKAGE" ]; then
  echo "Usage: bash scaffold.sh <dest-dir> <package-name>"
  echo "Example: bash scaffold.sh ~/myproject com.example.app"
  exit 1
fi

SKILL_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMPLATES="$SKILL_DIR/templates"

# Extract app name from package
APP_NAME="${PACKAGE##*.}"
MAIN_CLASS="${APP_NAME^}Activity"

# Convert package to path
PACKAGE_PATH="$(echo "$PACKAGE" | tr '.' '/')"

echo "Scaffolding $APP_NAME ($PACKAGE) at $DEST..."

mkdir -p "$DEST"
mkdir -p "$DEST/src/$PACKAGE_PATH"
mkdir -p "$DEST/res/values"
mkdir -p "$DEST/res/layout"
mkdir -p "$DEST/res/drawable"
mkdir -p "$DEST/res/menu"

# Copy templates
cp "$TEMPLATES/AndroidManifest.xml" "$DEST/"
cp "$TEMPLATES/ic_launcher.svg" "$DEST/"
cp "$TEMPLATES/build.sh" "$DEST/"
cp "$TEMPLATES/res/values/colors.xml" "$DEST/res/values/"
cp "$TEMPLATES/res/values/strings.xml" "$DEST/res/values/"
cp "$TEMPLATES/res/values/themes.xml" "$DEST/res/values/"

# Replace placeholders in manifest
sed -i "s|package=\"com.myapp\"|package=\"$PACKAGE\"|g" "$DEST/AndroidManifest.xml"
sed -i "s|\.MainActivity|.$MAIN_CLASS|g" "$DEST/AndroidManifest.xml"

# Replace PACKAGE variable in build.sh
sed -i "s|PACKAGE=\"com/myapp\"|PACKAGE=\"$PACKAGE_PATH\"|g" "$DEST/build.sh"
sed -i "s|src/com/myapp/MainActivity.java|src/$PACKAGE_PATH/${MAIN_CLASS}.java|g" "$DEST/build.sh"

# Create basic layout
cat > "$DEST/res/layout/activity_main.xml" << 'EOFXML'
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    android:gravity="center">

    <TextView
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="@string/app_name"
        android:textSize="24sp"
        android:textColor="@color/text_primary" />

</LinearLayout>
EOFXML

# Create stub activity
cat > "$DEST/src/$PACKAGE_PATH/${MAIN_CLASS}.java" << EOFJAVA
package $PACKAGE;

import android.app.Activity;
import android.os.Bundle;

public class $MAIN_CLASS extends Activity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
    }
}
EOFJAVA

# Create values directory placeholder
mkdir -p "$DEST/res/values"

echo "Done! Project scaffolded at $DEST"
echo ""
echo "Next steps:"
echo "  cd $DEST"
echo "  # Edit src/$PACKAGE_PATH/${MAIN_CLASS}.java"
echo "  # Create layouts, drawables, etc."
echo "  bash build.sh install"
