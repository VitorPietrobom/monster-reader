# Features — Monster Reader

---

## 1. RSVP Reader

**What it does:** Displays words from a loaded text one at a time at a fixed point on screen, flashing each word for a duration determined by the current WPM setting.

**User flow:**
1. Text is loaded via Home Screen.
2. User taps **Start Reading** → navigates to Reader Screen.
3. User presses Play → 3-2-1 countdown → words begin flashing.
4. Reading ends automatically when the last word is shown; playback stops.

**Edge cases / constraints:**
- Restarting resets `_hasStarted = false`, so the countdown shows again.
- After a pause-resume, countdown is skipped (`_hasStarted` remains `true`).
- Tapping the word area toggles play/pause.
- If `isFinished` and Play is pressed, index resets to 0 and countdown starts.

**Source files:**
- `lib/providers/reader_provider.dart` — all playback logic
- `lib/screens/reader_screen.dart` — UI
- `lib/widgets/word_display.dart` — word rendering

---

## 2. ORP Highlighting

**What it does:** Highlights a single "pivot" letter within each word in red. The pivot is always at the same horizontal screen position so the eye never moves.

**User flow:** Automatic — visible whenever a word is displayed in the Reader Screen.

**Edge cases / constraints:**
- ORP index is based on the count of alphabetic characters only (ignores punctuation).
- Alignment uses a pixel offset calculated as `(_maxOrp - orp) * (fontSize * 0.58)`. This is an approximation for Roboto; other fonts may misalign slightly.
- Words of 1 character: pivot is the character itself (index 0).

**Source files:**
- `lib/providers/reader_provider.dart` — `orpIndex()` static method
- `lib/widgets/word_display.dart` — rendering + alignment

---

## 3. WPM Control

**What it does:** Lets the user set words-per-minute (50–1000) via a slider on the Reader Screen. Changes take effect immediately, even during playback.

**User flow:** Drag the WPM slider; the current word's remaining timer is cancelled and a new one is scheduled at the updated rate.

**Edge cases / constraints:**
- Clamped: `wpm.clamp(50, 1000)`.
- On change during playback: `_timer?.cancel(); _scheduleNext()` — the current word restarts its timer at the new rate.
- Value is persisted to `SharedPreferences` on every change.

**Source files:**
- `lib/providers/reader_provider.dart` — `setWpm()`, `_delayForWord()`
- `lib/screens/reader_screen.dart` — `_WpmSlider` widget

---

## 4. Font Size Control

**What it does:** Adjusts the word display font size (24–80pt) via +/− buttons. Also scales the ORP alignment offset proportionally.

**User flow:** Tap **+** or **−** buttons in the Reader Screen. Display updates immediately.

**Edge cases / constraints:**
- Step size: 4pt per tap.
- Clamped: `fontSize.clamp(24.0, 80.0)`.
- Persisted to `SharedPreferences` on every change.
- `_charWidth` is recalculated as `fontSize * 0.58` for alignment.

**Source files:**
- `lib/providers/reader_provider.dart` — `setFontSize()`
- `lib/screens/reader_screen.dart` — `_FontSizeControls` widget
- `lib/widgets/word_display.dart` — uses `fontSize` parameter

---

## 5. Punctuation Pause

**What it does:** Automatically extends the display time of words ending with sentence or clause punctuation, improving comprehension at speed.

**User flow:** Transparent to the user — happens automatically during playback.

**Multipliers:**
- `.` `!` `?` `…` → 2.5× base interval
- `,` `;` `:` → 1.5× base interval

**Edge cases / constraints:**
- Multiplier is based on the **last character** of the word string (may include punctuation like `word.` or `word,`).
- Implemented via per-word `Timer` delay, not post-hoc sleep.

**Source files:**
- `lib/providers/reader_provider.dart` — `_delayForWord()`

---

## 6. 3-2-1 Countdown

**What it does:** Shows an animated countdown (3→2→1) before playback begins, giving the user time to focus on the ORP position.

**User flow:**
1. User presses Play for the first time (or after Restart).
2. Reader area shows `3`, then `2`, then `1` (750ms each) with scale+fade animation.
3. Playback begins automatically.
4. Tapping the pause button during countdown cancels it.

**Edge cases / constraints:**
- Countdown is **skipped** on resume after pause (`_hasStarted` is already `true`).
- During countdown, the play button shows a pause icon (tapping cancels).
- Context strip is hidden during countdown.

**Source files:**
- `lib/providers/reader_provider.dart` — `_startCountdown()`, `_cancelCountdown()`
- `lib/widgets/countdown_overlay.dart` — `AnimatedSwitcher` rendering
- `lib/screens/reader_screen.dart` — conditional display

---

## 7. Reading Stats

**What it does:** Displays current position and estimated time remaining in the app bar of the Reader Screen.

**Format:** `{currentIndex + 1} / {total}  ·  {Xm left}` or `<1m left` or `Xh Ym left`.

**Edge cases / constraints:**
- Minutes remaining is a real-time estimate based on current WPM, not a fixed value set at load time.
- Updates on every word change via `Consumer`.

**Source files:**
- `lib/providers/reader_provider.dart` — `minutesLeft`, `wordsRemaining`
- `lib/screens/reader_screen.dart` — app bar `Consumer`

---

## 8. Context Strip

**What it does:** Shows a 3-line band of surrounding words below the main RSVP display, with the current word highlighted. Provides comprehension recovery without stopping.

**Window:** 8 words before current, 15 words after current.

**Edge cases / constraints:**
- Hidden during countdown.
- Current word is `Colors.white`, `FontWeight.w600`; surrounding words are `Colors.white30`, normal weight.
- Fixed height (68px); overflowing text is clipped (`TextOverflow.clip`).
- Window clips naturally at text start/end.

**Source files:**
- `lib/providers/reader_provider.dart` — `contextWords` getter
- `lib/widgets/context_strip.dart`
- `lib/screens/reader_screen.dart` — conditionally rendered

---

## 9. Bookmarks / Resume

**What it does:** Saves the reading position periodically and on pause. On next load of the same text, offers to resume from where the user left off.

**User flow:**
1. User reads, pauses, exits app.
2. User opens app, imports or pastes the same text.
3. Reader Screen opens → dialog: "Resume from word X of Y (Z%)?" with **Resume** / **Start over**.

**Edge cases / constraints:**
- Bookmark key = first 100 chars of whitespace-normalised raw text (heuristic, not a hash).
- Bookmark is not shown if `lastWordIndex == 0` (nothing meaningful to resume).
- `acceptResume()` sets `_currentIndex`; `declineResume()` clears `_pendingResumeIndex` and stays at 0.
- Saved every 20 words during playback and on every `pause()`.

**Source files:**
- `lib/providers/reader_provider.dart` — `_saveBookmark()`, `_bookmarkKey`, `acceptResume()`, `declineResume()`
- `lib/services/preferences_service.dart` — `saveBookmark()`, `lastTextKey`, `lastWordIndex`
- `lib/screens/reader_screen.dart` — `_showResumeDialog()`

---

## 10. Persistent Settings

**What it does:** WPM and font size persist across app restarts.

**User flow:** Transparent — settings are restored automatically on launch.

**Source files:**
- `lib/services/preferences_service.dart`
- `lib/providers/reader_provider.dart` — constructor reads from `PreferencesService`
- `lib/main.dart` — `await PreferencesService.instance.init()` before `runApp`

---

## 11. Text Import — Paste / Clipboard

**What it does:** Two ways to get plain text into the app without typing:
- **Text field** — direct paste via system long-press menu.
- **Paste button** — reads `Clipboard.getData('text/plain')` with one tap.

**User flow:** Tap **Paste** button below the text field; text appears immediately.

**Edge cases / constraints:**
- If clipboard is empty, nothing happens (silent no-op).
- Clipboard text is trimmed before insertion.
- Word count updates via `TextEditingController` listener.

**Source files:**
- `lib/screens/home_screen.dart` — `_pasteFromClipboard()`

---

## 12. Text Import — PDF

**What it does:** Lets the user pick a PDF from device storage, extracts the text layer, cleans it, and loads it into the reader.

**User flow:**
1. Tap the import icon (top-right of Home Screen).
2. System file picker opens, filtered to `.pdf` and `.epub`.
3. Text is extracted → cleaned → inserted into text field.
4. Loading spinner shown during extraction; inline error shown on failure.

**Edge cases / constraints:**
- Image-based PDFs (scanned without a text layer) return empty text → error shown.
- Uses `pdfrx ^1.0.101` (pdfium); requires Dart SDK 3.5.x (Flutter 3.24.x).
- `READ_EXTERNAL_STORAGE` permission declared with `maxSdkVersion="32"` for Android ≤12.

**Source files:**
- `lib/screens/home_screen.dart` — `_importFile()`

---

## 13. Text Import — ePub

**What it does:** Picks an `.epub` file, extracts text from all HTML chapter files, and loads it.

**User flow:** Same as PDF import — shared file picker, same import button.

**Edge cases / constraints:**
- ePub = ZIP. Chapters are sorted alphabetically (approximation of reading order).
- Files with `toc` or `nav` in the name are excluded (navigation files, not content).
- DRM-protected ePubs cannot be extracted → empty result → error shown.
- HTML entities (`&amp;`, `&nbsp;`, etc.) are decoded during stripping.

**Source files:**
- `lib/services/epub_service.dart`
- `lib/screens/home_screen.dart` — `_importFile()`

---

## 14. Text Preprocessing

**What it does:** Cleans raw text extracted from PDFs and ePubs before it enters the reader.

**Transformations (in order):**
1. Rejoin hyphenated line breaks: `word-\nbreak` → `wordbreak`
2. Remove standalone page numbers (lines containing only digits)
3. Collapse 3+ consecutive newlines to a double newline
4. Normalise horizontal whitespace (tabs, multiple spaces → single space)

**Source files:**
- `lib/services/text_preprocessor.dart`

---

## 15. Haptic Feedback

**What it does:** Provides tactile confirmation for all interactive controls.

**Source files:**
- `lib/screens/reader_screen.dart` — all control buttons
- `lib/screens/home_screen.dart` — Start Reading, Paste

---

## 16. CI / APK Build

**What it does:** GitHub Actions workflow that runs tests and builds a debug APK on every push, making the APK downloadable from the Actions tab.

**User flow:**
1. Push to `main` or `claude/rsvp-reading-app-hmzdp`.
2. CI runs `flutter test` then `flutter build apk --debug`.
3. APK uploaded as artifact `monster-reader-debug` (retained 7 days).
4. Download from GitHub → Actions → latest run → Artifacts.

**Edge cases / constraints:**
- Flutter 3.24.0 pinned (Dart 3.5.0); `pdfrx` must stay at `^1.0.101` for this constraint.
- `workflow_dispatch` enabled for manual trigger without a push.

**Source files:**
- `.github/workflows/build.yml`
