# Data Model — Monster Reader

There is no database. All runtime state lives in `ReaderProvider` (in-memory) and a small set of `SharedPreferences` keys (on-device KV store).

## Runtime State — `ReaderProvider`

| Field | Type | Nullable | Default | Description |
|---|---|---|---|---|
| `_words` | `List<String>` | no | `[]` | Text split on whitespace |
| `_currentIndex` | `int` | no | `0` | Index into `_words` |
| `_wpm` | `int` | no | from prefs (250) | Words per minute, clamped 50–1000 |
| `_fontSize` | `double` | no | from prefs (48.0) | Clamped 24.0–80.0 pt |
| `_isPlaying` | `bool` | no | `false` | Timer is running |
| `_hasStarted` | `bool` | no | `false` | First play has occurred; controls countdown logic |
| `_countdown` | `int?` | yes | `null` | 3 → 2 → 1; null when not counting down |
| `_pendingResumeIndex` | `int?` | yes | `null` | Set when a bookmark matches current text; cleared after dialog |
| `_rawText` | `String` | no | `''` | Original text used to compute bookmark key |
| `_timer` | `Timer?` | yes | `null` | Active playback or countdown timer |

### Derived / Computed Getters

| Getter | Formula | Notes |
|---|---|---|
| `progress` | `_currentIndex / _words.length` | 0.0–1.0 for `LinearProgressIndicator` |
| `currentWord` | `_words[_currentIndex]` | Empty string if no text loaded |
| `isFinished` | `_currentIndex >= _words.length - 1` | True when last word is reached |
| `wordsRemaining` | `_words.length - _currentIndex` | |
| `minutesLeft` | `wordsRemaining / _wpm` | In minutes (double) |
| `contextWords` | Window `[currentIndex-8, currentIndex+15]` | `List<MapEntry<int,String>>` |
| `_bookmarkKey` | First 100 chars of `_rawText` (whitespace normalised) | Used as `SharedPreferences` lookup key |

### ORP Index (static)

Maps word length (letters only) to the index of the pivot character:

| Letter count | ORP index |
|---|---|
| ≤ 1 | 0 |
| 2–5 | 1 |
| 6–9 | 2 |
| 10+ | 3 |

### Punctuation Delay Multipliers

| Trailing character | Multiplier |
|---|---|
| `.` `!` `?` `…` | 2.5× base interval |
| `,` `;` `:` | 1.5× base interval |
| anything else | 1.0× |

Base interval (ms) = `60000 / wpm`.

## Persistence — `SharedPreferences` Keys

| Key | Type | Default | Set by | Read by |
|---|---|---|---|---|
| `wpm` | `int` | `250` | `PreferencesService.saveWpm()` | `PreferencesService.wpm` |
| `fontSize` | `double` | `48.0` | `PreferencesService.saveFontSize()` | `PreferencesService.fontSize` |
| `lastTextKey` | `String` | — | `PreferencesService.saveBookmark()` | `PreferencesService.lastTextKey` |
| `lastWordIndex` | `int` | — | `PreferencesService.saveBookmark()` | `PreferencesService.lastWordIndex` |

### Bookmark Matching

A bookmark is considered a match when:
```
prefs.lastTextKey == _bookmarkKey  &&  lastWordIndex > 0  &&  lastWordIndex < words.length
```

The key is the first 100 characters of the raw text with all whitespace collapsed to single spaces. This is a best-effort heuristic; it is not a cryptographic hash.

### Bookmark Write Triggers

- Every 20 words during playback (`_currentIndex % 20 == 0`)
- On `pause()`

## No Remote / No Auth

The app is fully offline. There is no backend, no analytics, no user accounts, and no network calls.

## Asset Storage

No user-uploaded assets are stored. Imported files (PDF/ePub) are read transiently from the device file system via `file_picker` and are never copied or cached by the app.
