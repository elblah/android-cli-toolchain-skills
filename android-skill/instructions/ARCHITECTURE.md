# App Architecture

## Project Structure

```
myapp/
 AndroidManifest.xml        — Package, permissions, activities, receivers
 ic_launcher.svg            — Vector icon (rsvg-convert renders to PNG)
 build.sh                   — Full build script (from templates/)
 src/
  com/myapp/
   MainActivity.java        — Launcher activity
   ...                      — Other activities, adapters, helpers
 res/
  values/
   strings.xml              — All user-facing strings
   colors.xml               — Color palette (no hardcoded colors in layouts)
   themes.xml               — Dark theme + dialog theme
  layout/
   activity_main.xml        — Per-activity layouts
   list_item_xxx.xml        — Per-list-item layouts
  drawable/
   *.xml                    — Shape drawables, vector drawables
  menu/
   *.xml                    — Action mode menus, options menus
  mipmap-{mdpi,hdpi,...}/   — PNG launcher icons (auto-generated)
```

## Key Principles

- **minSdkVersion 21, targetSdkVersion 30**
- Package name matches directory: `com.myapp` → `src/com/myapp/`
- Every resource file must be explicitly compiled in `build.sh`
- Every Java file must be explicitly listed in the `javac` command
- No Gradle, no XML namespaces beyond `android:`

## Activity Pattern

```java
public class MainActivity extends Activity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        findViewById(R.id.my_button).setOnClickListener(v -> {
            // Lambdas are safe (compiled to invokedynamic)
        });
    }
}
```

## Lifecycle

- Use `onResume()` to refresh data/register dynamic receivers
- Use `onPause()` to unregister dynamic receivers
- Use `onCreateOptionsMenu()` / `onOptionsItemSelected()` for the toolbar menu
- Use `startActivity()` with `Intent.putExtra()` to pass data between activities

## List/Adapter Pattern

```java
class MyItem {
    final long id;
    final String text;
    MyItem(long id, String text) { this.id = id; this.text = text; }
}

class MyAdapter extends BaseAdapter {
    private final List<MyItem> items;
    MyAdapter(List<MyItem> items) { this.items = items; }

    @Override public int getCount() { return items.size(); }
    @Override public Object getItem(int i) { return items.get(i); }
    @Override public long getItemId(int i) { return items.get(i).id; }

    @Override
    public View getView(int i, View convertView, ViewGroup parent) {
        if (convertView == null) {
            convertView = LayoutInflater.from(parent.getContext())
                    .inflate(R.layout.list_item_xxx, parent, false);
        }
        TextView tv = convertView.findViewById(R.id.text);
        tv.setText(items.get(i).text);
        return convertView;
    }
}
```

## Local Database (SQLite)

Use `SQLiteOpenHelper` for local storage:

```java
public class MyDb extends SQLiteOpenHelper {
    private static final String DB_NAME = "myapp.db";
    private static final int DB_VERSION = 1;

    public MyDb(Context context) {
        super(context, DB_NAME, null, DB_VERSION);
    }

    @Override
    public void onCreate(SQLiteDatabase db) {
        db.execSQL("CREATE TABLE items (" +
                "_id INTEGER PRIMARY KEY AUTOINCREMENT," +
                "text TEXT NOT NULL)");
    }

    @Override
    public void onUpgrade(SQLiteDatabase db, int oldV, int newV) {
        db.execSQL("DROP TABLE IF EXISTS items");
        onCreate(db);
    }
}
```

## System Content Providers

Read from system providers via `ContentResolver.query()`:

```java
Cursor c = getContentResolver().query(
    Uri.parse("content://some_provider/table"),
    new String[]{"column1", "column2"},
    "selection_column=?",
    new String[]{"value"},
    "date_column DESC");
```

Close cursors in `finally` block or try-with-resources.
