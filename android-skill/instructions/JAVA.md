# Java Coding Patterns

## D8 Compiler Bug — CRITICAL

This environment's D8 version (`R8 3.3.20-dev`) has a known crash on
anonymous inner classes. It produces a NullPointerException:

```
java.lang.NullPointerException: Cannot invoke "String.length()"
because "<parameter1>" is null
```

### Rule: Extract ALL anonymous classes to named top-level classes.

**BAD** — crashes d8:
```java
view.setOnClickListener(new View.OnClickListener() {
    @Override
    public void onClick(View v) {
        doSomething();
    }
});

ActionMode.Callback callback = new ActionMode.Callback() {
    // ...
};
```

**GOOD** — compiles successfully:
```java
// Named top-level class
public class MyClickListener implements View.OnClickListener {
    private final Context context;
    public MyClickListener(Context context) { this.context = context; }
    @Override
    public void onClick(View v) {
        doSomething();
    }
}

// Usage
view.setOnClickListener(new MyClickListener(this));
```

### Lambdas are SAFE

Lambdas compile to `invokedynamic` which does not trigger this bug:
```java
view.setOnClickListener(v -> doSomething());
```

## Naming Convention

- Activity classes: descriptive noun + `Activity` (e.g., `MainActivity`, `SettingsActivity`)
- Adapter classes: noun + `Adapter` (e.g., `MyListAdapter`)
- Listener classes: verb + noun + `Listener` (e.g., `SendClickListener`, `SetDefaultClickListener`)
- Watcher classes: noun + `Watcher` (e.g., `SearchWatcher`)
- Receiver classes: noun + `Receiver` (e.g., `SmsReceiver`, `StatusReceiver`)
- Database helper: noun + `Db` (e.g., `NoteDb`, `OutboxDb`)

## Activity Communication

Pass data between activities using `Intent` extras:

```java
// Sender
Intent intent = new Intent(this, TargetActivity.class);
intent.putExtra("key_string", "value");
intent.putExtra("key_long", 42L);
startActivity(intent);

// Receiver
String val = getIntent().getStringExtra("key_string");
long num = getIntent().getLongExtra("key_long", -1);
```

## Menu / ActionMode

Options menu in `res/menu/`:

```xml
<menu xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:id="@+id/action_my_action"
        android:title="Action"
        android:icon="@drawable/ic_my_action"
        android:showAsAction="ifRoom" />
</menu>
```

Inflate in Activity:
```java
@Override
public boolean onCreateOptionsMenu(Menu menu) {
    getMenuInflater().inflate(R.menu.my_options, menu);
    return true;
}
```

## Dynamic BroadcastReceivers

Register in `onResume()`, unregister in `onPause()`:

```java
private MyReceiver myReceiver;

@Override
protected void onResume() {
    super.onResume();
    myReceiver = new MyReceiver(() -> refreshData());
    registerReceiver(myReceiver, new IntentFilter("com.myapp.MY_ACTION"));
}

@Override
protected void onPause() {
    super.onPause();
    if (myReceiver != null) {
        try { unregisterReceiver(myReceiver); } catch (Exception ignored) {}
        myReceiver = null;
    }
}
```

## Toast Messages

```java
Toast.makeText(this, "Message text", Toast.LENGTH_SHORT).show();
```

## Permissions

Request at runtime (API 23+):

```java
private static final int PERMISSION_REQUEST = 1;

private boolean hasPermission(String perm) {
    return checkSelfPermission(perm) == PackageManager.PERMISSION_GRANTED;
}

private void requestMyPermissions() {
    requestPermissions(new String[]{
        Manifest.permission.EXAMPLE_PERMISSION
    }, PERMISSION_REQUEST);
}

@Override
public void onRequestPermissionsResult(int code, String[] perms, int[] results) {
    super.onRequestPermissionsResult(code, perms, results);
    if (code == PERMISSION_REQUEST) {
        if (hasPermission(Manifest.permission.EXAMPLE_PERMISSION)) {
            // Permission granted
        } else {
            // Permission denied
        }
    }
}
```

## Threading

All Android UI operations happen on the main thread.
For background work, use:

```java
new Thread(() -> {
    // Do background work
    runOnUiThread(() -> {
        // Update UI
    });
}).start();
```

## Cursor Handling

Always close cursors when done:

```java
Cursor c = null;
try {
    c = getContentResolver().query(uri, projection, selection, args, order);
    while (c != null && c.moveToNext()) {
        // process row
    }
} catch (Exception e) {
    // handle
} finally {
    if (c != null) c.close();
}
```

## SharedPreferences

Simple key-value storage:

```java
// Write
getSharedPreferences("my_prefs", MODE_PRIVATE)
    .edit().putString("key", "value").apply();

// Read
String val = getSharedPreferences("my_prefs", MODE_PRIVATE)
    .getString("key", "default");
```
