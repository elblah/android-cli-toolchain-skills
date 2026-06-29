# Android Resources

## Resource Directory Structure

```
res/
 values/
  strings.xml     — All translatable strings
  colors.xml      — Color definitions (referenced by name, never hardcoded)
  themes.xml      — App theme and dialog theme
 layout/
  activity_*.xml          — Per-activity layouts
  fragment_*.xml          — Fragment layouts (if used)
  list_item_*.xml         — List/Adapter item layouts
  dialog_*.xml            — Custom dialog layouts (optional)
 drawable/
  *.xml                   — Shape drawables, vector drawables, selectors
 mipmap-mdpi/             — 48×48 launcher icon
 mipmap-hdpi/             — 72×72
 mipmap-xhdpi/            — 96×96
 mipmap-xxhdpi/           — 144×144
 mipmap-xxxhdpi/          — 192×192
 menu/
  *.xml                   — Options menu and context menu definitions
```

## Values Files

### strings.xml

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">MyApp</string>
    <string name="hello">Hello</string>
    <!-- Format strings with %s, %d placeholders -->
    <string name="item_count">%d items</string>
</resources>
```

**Locale variants**: Create `res/values-XX/strings.xml` for each locale
(e.g., `values-pt`, `values-es`, `values-fr`).
Each locale file must contain all the same string resources.

Every locale's `strings.xml` must be compiled individually in `build.sh`.

### colors.xml

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="bg_dark">#FF0F0F1A</color>
    <color name="bg_surface">#FF1E1B2E</color>
    <color name="primary">#FF7C3AED</color>
    <color name="accent">#FF06B6D4</color>
    <color name="text_primary">#FFE2E8F0</color>
    <color name="text_secondary">#FF94A3B8</color>
</resources>
```

### themes.xml

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="Theme.MyApp" parent="@android:style/Theme.Material.Light.NoActionBar">
        <item name="android:windowBackground">@color/bg_dark</item>
        <item name="android:statusBarColor">@color/bg_dark</item>
        <item name="android:navigationBarColor">@color/bg_dark</item>
        <item name="android:alertDialogTheme">@style/Theme.MyApp.Dialog</item>
    </style>

    <style name="Theme.MyApp.Dialog" parent="@android:style/Theme.Material.Light.Dialog.Alert">
        <item name="android:windowBackground">@color/bg_surface</item>
        <item name="android:textColor">@color/text_primary</item>
        <item name="android:textColorPrimary">@color/text_primary</item>
        <item name="android:textColorSecondary">@color/text_secondary</item>
        <item name="android:colorAccent">@color/accent</item>
    </style>
</resources>
```

## Drawables

### Shape Drawables (bubbles, backgrounds)

```xml
<!-- Rounded rectangle with solid fill -->
<shape xmlns:android="http://schemas.android.com/apk/res/android"
    android:shape="rectangle">
    <solid android:color="@color/bg_surface" />
    <corners android:radius="12dp" />
</shape>
```

### Vector Drawables (icons)

```xml
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
    <path
        android:pathData="M12,2L2,7l10,5 10,-5zM2,17l10,5 10,-5M2,12l10,5 10,-5"
        android:strokeWidth="2"
        android:strokeColor="?android:attr/colorControlNormal" />
</vector>
```

Use `?android:attr/colorControlNormal` for stroke/fill color to inherit
the theme's primary text color. This works in both light and dark ActionMode
bars and headers.

### Selector Drawables

```xml
<selector xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:state_activated="true" android:drawable="@drawable/background_selected" />
    <item android:drawable="@drawable/background_default" />
</selector>
```

## Layouts

### Activity Layout

```xml
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical">

    <include layout="@layout/some_common_element" />

    <ListView
        android:id="@+id/list"
        android:layout_width="match_parent"
        android:layout_height="0dp"
        android:layout_weight="1"
        android:divider="@null"
        android:dividerHeight="0dp" />

    <TextView
        android:id="@+id/empty_view"
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        android:gravity="center"
        android:text="@string/empty_state" />

</LinearLayout>
```

### List Item Layout

```xml
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    android:orientation="vertical"
    android:padding="12dp">

    <TextView
        android:id="@+id/primary_text"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:textSize="16sp"
        android:textColor="@color/text_primary" />

    <TextView
        android:id="@+id/secondary_text"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:textSize="14sp"
        android:textColor="@color/text_secondary" />

</LinearLayout>
```

### Menu Layout

```xml
<?xml version="1.0" encoding="utf-8"?>
<menu xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:id="@+id/action_delete"
        android:title="Delete"
        android:icon="@drawable/ic_delete"
        android:showAsAction="ifRoom" />
    <item android:id="@+id/action_copy"
        android:title="Copy"
        android:showAsAction="never" />
</menu>
```

**Note**: System icons like `@android:drawable/ic_menu_copy` and
`@android:drawable/ic_menu_share` are private framework resources and
cannot be used. Create custom vector drawables instead.

## Key Rules

1. Every resource file must be compiled with `aapt2 compile` explicitly
2. Every layout XML file must have an ID on interactive elements
3. Never hardcode colors in layouts — always reference `@color/xxx`
4. Never hardcode strings — always reference `@string/xxx`
5. Use `android:textIsSelectable="true"` instead of `android:autoLink`
   to avoid accidental URL opening (no internet permission needed)
