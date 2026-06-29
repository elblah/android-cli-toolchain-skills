# Theming

## Dark Theme Pattern

All apps use a dark purple theme based on `Theme.Material.Light.NoActionBar`.
Despite the "Light" parent, it renders dark because all colors are overridden.

### Base Theme

```xml
<style name="Theme.MyApp" parent="@android:style/Theme.Material.Light.NoActionBar">
    <item name="android:windowBackground">@color/bg_dark</item>
    <item name="android:statusBarColor">@color/bg_dark</item>
    <item name="android:navigationBarColor">@color/bg_dark</item>
    <item name="android:alertDialogTheme">@style/Theme.MyApp.Dialog</item>
</style>
```

### Dialog Theme

```xml
<style name="Theme.MyApp.Dialog" parent="@android:style/Theme.Material.Light.Dialog.Alert">
    <item name="android:windowBackground">@color/bg_surface</item>
    <item name="android:textColor">@color/text_primary</item>
    <item name="android:textColorPrimary">@color/text_primary</item>
    <item name="android:textColorSecondary">@color/text_secondary</item>
    <item name="android:colorAccent">@color/accent</item>
</style>
```

Set `android:alertDialogTheme` in the base theme so all dialogs use it
without needing to pass a style parameter to `AlertDialog.Builder`.

### Color Palette

```xml
<color name="bg_dark">#FF0F0F1A</color>       <!-- Very dark navy -->
<color name="bg_surface">#FF1E1B2E</color>     <!-- Dark purple-gray -->
<color name="primary">#FF7C3AED</color>        <!-- Purple -->
<color name="accent">#FF06B6D4</color>         <!-- Cyan -->
<color name="text_primary">#FFE2E8F0</color>   <!-- Light gray -->
<color name="text_secondary">#FF94A3B8</color>  <!-- Muted gray -->
```

## CRITICAL: Dialog Styling Rules

1. **Do NOT** override `android:colorBackground` in the base theme.
   This property cascades into AlertDialog and makes text unreadable
   (dark text on dark background).

2. **Do NOT** pass an explicit style parameter to `AlertDialog.Builder`.
   Use `android:alertDialogTheme` in the base theme instead.

3. **CORRECT** — dialog inherits theme's `alertDialogTheme`:
   ```java
   new AlertDialog.Builder(this)
       .setTitle("Title")
       .setMessage("Message")
       .setPositiveButton("OK", null)
       .show();
   ```

## ActionMode / Selection Mode (Contextual Action Bar)

When using `startActionMode()` for multi-select:

1. Extract `ActionMode.Callback` to a **named top-level class** (D8 bug)
2. Pass activity reference and data via constructor
3. Set `android:showAsAction="ifRoom"` on menu items with icons

```java
// Named class (not anonymous)
public class MyActionModeCallback implements ActionMode.Callback {
    private final Activity activity;
    public MyActionModeCallback(Activity activity) { this.activity = activity; }

    @Override
    public boolean onCreateActionMode(ActionMode mode, Menu menu) {
        mode.getMenuInflater().inflate(R.menu.my_context_menu, menu);
        return true;
    }

    @Override
    public boolean onPrepareActionMode(ActionMode mode, Menu menu) { return false; }

    @Override
    public boolean onActionItemClicked(ActionMode mode, MenuItem item) {
        // handle action
        return true;
    }

    @Override
    public void onDestroyActionMode(ActionMode mode) {
        // clear selection state
    }
}
```

## Header/Toolbar with Dark Background

For a toolbar-like header on dark background:

- Set `android:background="@color/bg_surface"` on the container
- Use `ImageButton` with `android:src="@drawable/ic_xxx"`
- Add `android:tint="@android:color/white"` to ImageButtons because
  `colorControlNormal` from the Light parent resolves to black

```xml
<LinearLayout
    android:layout_width="match_parent"
    android:layout_height="?android:attr/actionBarSize"
    android:background="@color/bg_surface"
    android:orientation="horizontal"
    android:gravity="center_vertical">

    <ImageButton
        android:id="@+id/back_button"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:src="@drawable/ic_back"
        android:tint="@android:color/white"
        android:background="?android:attr/selectableItemBackgroundBorderless"
        android:padding="12dp" />
</LinearLayout>
```
