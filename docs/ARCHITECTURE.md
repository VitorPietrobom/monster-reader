# Architecture — Monster Reader

## System Diagram

```
┌─────────────────────────────────────────────────────┐
│                      UI Layer                        │
│                                                      │
│  HomeScreen                  ReaderScreen            │
│  ├── TextEditingController   ├── Consumer<Reader>    │
│  ├── FilePicker              ├── WordDisplay         │
│  ├── EpubService (stateless) ├── ContextStrip        │
│  └── TextPreprocessor        ├── CountdownOverlay    │
│       ↓ loadText()           └── Controls            │
│                                                      │
│              ChangeNotifierProvider                  │
│                      │                               │
│              ReaderProvider  ←──── PreferencesService│
│              (single source  ────→ (singleton,       │
│               of truth)             SharedPrefs)     │
└─────────────────────────────────────────────────────┘
         │                          │
  ┌──────┴──────┐           ┌──────┴──────┐
  │  pdfrx      │           │  archive    │
  │  (pdfium)   │           │  (ZIP+HTML) │
  │  PDF text   │           │  ePub text  │
  └─────────────┘           └─────────────┘
```

## Data / Control Flow

```
User picks file
      │
      ▼
HomeScreen._importFile()
      │
      ├─ .pdf ──▶ PdfDocument.openFile() ──▶ page.loadText() ──▶ raw string
      └─ .epub ──▶ EpubService.extractText() ──▶ ZIP decode ──▶ HTML strip ──▶ raw string
      │
      ▼
TextPreprocessor.clean(raw)   ← strips page numbers, hyphens, excess whitespace
      │
      ▼
ReaderProvider.loadText(text)
      │  splits on \s+, checks bookmark, resets state
      ▼
ReaderScreen (push)
      │
      ├─ play() ──▶ _startCountdown(3→2→1) ──▶ _scheduleNext()
      │                                              │
      │                          Timer(_delayForWord(currentWord))
      │                                              │
      │                          _currentIndex++, notifyListeners()
      │                                              │
      │                          _scheduleNext() [recursive]
      │
      └─ pause() ──▶ timer.cancel(), _saveBookmark()
```

## Navigation / Routing

Flat two-screen stack. No named routes.

```
HomeScreen (root, always in stack)
      │
      └─ Navigator.push(MaterialPageRoute) ──▶ ReaderScreen
                                                      │
                                              Navigator.pop()
```

`ReaderScreen` uses `StatefulWidget` solely to hook `initState` for the resume dialog via `WidgetsBinding.instance.addPostFrameCallback`.

## Dependency Injection

Single `ChangeNotifierProvider` at the app root (`main.dart`). No service locator or get_it. Widgets access the provider via:

- `Consumer<ReaderProvider>` — for widgets that rebuild on state changes
- `context.read<ReaderProvider>()` — for one-shot calls (e.g. button handlers)

`PreferencesService` is a Dart singleton (`PreferencesService.instance`). It is **not** injected through the provider tree — `ReaderProvider` calls it directly. This is intentional: preferences are infrastructure, not UI state.

## External Services

| Service | Package | Integration point | Notes |
|---|---|---|---|
| PDF extraction | `pdfrx ^1.0.101` | `home_screen.dart` | pdfium-based; text-layer PDFs only |
| ePub extraction | `archive ^3.6.1` | `lib/services/epub_service.dart` | ePub = ZIP; reads HTML chapter files, strips tags |
| File picker | `file_picker ^8.1.2` | `home_screen.dart` | System document picker; no storage permission on Android 13+ |
| Persistence | `shared_preferences ^2.3.2` | `lib/services/preferences_service.dart` | KV store; init awaited in `main()` before `runApp` |

## Key Technical Decisions

| Decision | Rationale |
|---|---|
| `Timer` (recursive) instead of `Timer.periodic` | Punctuation pauses require per-word variable delays; `periodic` uses a fixed interval |
| `pdfrx` over `pdf_text` | `pdf_text` is abandoned and requires Kotlin 1.3.x, incompatible with AGP 8 |
| `archive` over `epubx` | `epubx` does not exist on pub.dev; ePub is a ZIP so `archive` + regex is sufficient |
| `PreferencesService` nullable `_prefs` | Allows `ReaderProvider` to be constructed in unit tests without `SharedPreferences` being initialised |
| `compileSdk 35` hardcoded | `flutter_plugin_android_lifecycle` ≥2.0.15 requires SDK 35; using `flutter.compileSdkVersion` resolved to 34 |
| `multiLine: true` param instead of `(?m)` | Dart's `RegExp` does not support inline mode flags |
| Dark-only theme | Target use case is night/commute reading; no light mode currently |
