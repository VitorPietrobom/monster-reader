# Patterns — Monster Reader

## How to Add a New Feature

1. **If it's pure UI state** (e.g. a modal open/closed flag): keep it in the widget's `State`.
2. **If it's reader state** (anything to do with playback, words, settings): add it to `ReaderProvider`.
3. **If it persists across sessions**: add a key to `PreferencesService`, read it in `ReaderProvider()`  constructor, write it in the relevant setter.
4. **If it's a stateless text/file transform**: add a `static` method to the relevant service (`TextPreprocessor`, `EpubService`).
5. Update `docs/FEATURES.md` with the new feature section.
6. Update `docs/PATTERNS.md` if a new recurring pattern emerges.

---

## Recurring Patterns

### Reading provider state in a widget (rebuilds on change)

```dart
Consumer<ReaderProvider>(
  builder: (context, reader, _) {
    return Text(reader.currentWord);
  },
)
```

### One-shot provider call (no rebuild needed)

```dart
ElevatedButton(
  onPressed: () => context.read<ReaderProvider>().restart(),
  child: const Text('Restart'),
)
```

### Async file loading with loading/error state

```dart
bool _loading = false;
String? _error;

Future<void> _loadFile() async {
  setState(() { _loading = true; _error = null; });
  try {
    final result = await /* async work */;
    setState(() { /* apply result */ });
  } catch (_) {
    setState(() => _error = 'Something went wrong.');
  } finally {
    setState(() => _loading = false);
  }
}
```

Used in: `HomeScreen._importFile()`

### Inline error banner

```dart
if (_error != null)
  Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF4444), size: 15),
        const SizedBox(width: 6),
        Expanded(child: Text(_error!, style: const TextStyle(color: Color(0xFFFF4444), fontSize: 12))),
      ],
    ),
  ),
```

### Adding a persisted setting

```dart
// 1. Add key in preferences_service.dart
int get myPref => _prefs?.getInt('myPref') ?? defaultValue;
Future<void> saveMyPref(int v) async => _prefs?.setInt('myPref', v);

// 2. Load in ReaderProvider constructor
_myPref = PreferencesService.instance.myPref;

// 3. Save in setter
void setMyPref(int v) {
  _myPref = v.clamp(min, max);
  PreferencesService.instance.saveMyPref(_myPref);
  notifyListeners();
}
```

### Variable-delay timer (the playback loop)

```dart
void _scheduleNext() {
  if (!_isPlaying || _words.isEmpty) return;
  if (_currentIndex >= _words.length - 1) { pause(); return; }
  _timer = Timer(_delayForWord(_words[_currentIndex]), () {
    if (!_isPlaying) return;
    _currentIndex++;
    notifyListeners();
    _scheduleNext();   // ← recursive, not periodic
  });
}
```

**Never** replace this with `Timer.periodic` — punctuation pauses need per-word delay.

### Post-frame callback for dialogs from `initState`

```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    // safe to call showDialog here
    if (condition) _showMyDialog();
  });
}
```

Used in: `ReaderScreen` for the resume dialog.

### Haptic feedback — which level to use

| Action | Call |
|---|---|
| Play / pause / Start Reading | `HapticFeedback.mediumImpact()` |
| Restart | `HapticFeedback.heavyImpact()` |
| Step, close, tap-to-toggle | `HapticFeedback.lightImpact()` |
| Slider drag, font ±buttons | `HapticFeedback.selectionClick()` |

### Text extraction pipeline

```
raw file bytes
  └─ PDF  → PdfDocument.openFile() → page.loadText() → fullText per page
  └─ ePub → ZipDecoder().decodeBytes() → filter html/xhtml → _stripHtml()
       ↓
TextPreprocessor.clean(raw)
       ↓
ReaderProvider.loadText(cleaned)
```

---

## Anti-Patterns

| Avoid | Use instead | Why |
|---|---|---|
| `Timer.periodic` for word advancement | Recursive `Timer` via `_scheduleNext()` | Punctuation needs variable delay per word |
| `(?m)` inline regex flag | `RegExp(r'...', multiLine: true)` | Dart's RegExp does not support inline flags |
| `late SharedPreferences _prefs` in singleton | `SharedPreferences? _prefs` | Tests construct `ReaderProvider` without init; `late` throws |
| Picking packages without checking SDK constraints on pub.dev | Verify `environment: sdk:` in pubspec on pub.dev | Mismatched Dart SDK = `flutter pub get` failure in CI |
| AGP 8+ with unmaintained plugins | Use only actively maintained plugins that declare `namespace` | AGP 8 requires `namespace` in all library `build.gradle` |
| Storing reader state in widget `State` | Keep it in `ReaderProvider` | Survives navigation, is testable, single source of truth |
| Calling `Navigator.pop` inside `initState` | Use `addPostFrameCallback` | Frame not rendered yet; will throw |
