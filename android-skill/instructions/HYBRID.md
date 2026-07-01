# Hybrid (WebView) Apps

For apps that use HTML/JS/CSS in a WebView instead of native layouts.
Useful for simple UI-heavy apps that don't need platform APIs.

## Key Pattern

- Single Activity with a full-screen WebView
- All UI is HTML/JS/CSS bundled in `assets/`
- WebView loads from `file:///android_asset/index.html`
- JavaScript ↔ Java bridge via `@JavascriptInterface`

## Project Structure

```
myapp/
 AndroidManifest.xml
 ic_launcher.svg
 build.sh
 src/com/myapp/
  MainActivity.java
 res/
  values/
   strings.xml
   themes.xml
  mipmap-mdpi/  (icons)
  ...
 assets/
  index.html
  style.css
  app.js
  icons/          (cached UI icons, optional)
```

## AndroidManifest.xml

```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.myapp">

    <uses-sdk android:minSdkVersion="21" android:targetSdkVersion="34" />

    <application
        android:label="@string/app_name"
        android:icon="@mipmap/ic_launcher"
        android:theme="@style/Theme.MyApp">

        <activity android:name=".MainActivity">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>

    </application>
</manifest>
```

## Layout (activity_main.xml)

```xml
<?xml version="1.0" encoding="utf-8"?>
<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent">

    <WebView
        android:id="@+id/webview"
        android:layout_width="match_parent"
        android:layout_height="match_parent" />

</FrameLayout>
```

## MainActivity.java

```java
package com.myapp;

import android.app.Activity;
import android.os.Bundle;
import android.webkit.WebView;
import android.webkit.WebViewClient;

public class MainActivity extends Activity {

    private WebView webView;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        webView = findViewById(R.id.webview);

        // Disable all network access
        webView.getSettings().setJavaScriptEnabled(true);
        webView.getSettings().setAllowFileAccess(true);
        webView.getSettings().setAllowContentAccess(false);
        webView.getSettings().setAllowFileAccessFromFileURLs(false);
        webView.getSettings().setAllowUniversalAccessFromFileURLs(false);

        // Stay within the app (no external browser)
        webView.setWebViewClient(new WebViewClient());

        // Expose Java bridge to JS
        webView.addJavascriptInterface(new JsBridge(this), "Android");

        webView.loadUrl("file:///android_asset/index.html");
    }

    @Override
    public void onBackPressed() {
        if (webView.canGoBack()) {
            webView.goBack();
        } else {
            super.onBackPressed();
        }
    }
}
```

## JavaScript ↔ Java Bridge

```java
public class JsBridge {
    private final Context context;

    public JsBridge(Context context) {
        this.context = context;
    }

    @JavascriptInterface
    public void saveData(String key, String value) {
        context.getSharedPreferences("app", Context.MODE_PRIVATE)
            .edit().putString(key, value).apply();
    }

    @JavascriptInterface
    public String loadData(String key) {
        return context.getSharedPreferences("app", Context.MODE_PRIVATE)
            .getString(key, "");
    }
}
```

In JavaScript:
```javascript
// Save
Android.saveData("key", "value");

// Load
let val = Android.loadData("key");
```

## Building

Use the same build pipeline as native apps (`aapt2`, `javac`, `d8`, `apksigner`).
The only difference: pass `-A assets/` to `aapt2 link`:

```bash
aapt2 link -o bin/unsigned.apk \
  -I $ANDROID_JAR \
  --manifest AndroidManifest.xml \
  -A assets/ \
  bin/compiled/*.flat
```

## Caching Icons in Assets

For offline icon usage in HTML, generate PNGs from SVG during build:

```bash
mkdir -p assets/icons
rsvg-convert -w 24 -h 24 ic_icon.svg -o assets/icons/icon.png
```

Or use `FORCE_ICONS=1 bash build.sh` to regenerate.
Reference in HTML: `<img src="icons/icon.png">`
