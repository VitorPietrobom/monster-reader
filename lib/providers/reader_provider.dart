import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../services/preferences_service.dart';

class ReaderProvider extends ChangeNotifier {
  List<String> _words = [];
  int _currentIndex = 0;
  int _wpm = 250;
  double _fontSize = 48.0;
  bool _isPlaying = false;
  bool _hasStarted = false;
  int? _countdown;
  int? _pendingResumeIndex;
  String _rawText = '';
  Timer? _timer;

  List<String> get words => _words;
  int get currentIndex => _currentIndex;
  int get wpm => _wpm;
  double get fontSize => _fontSize;
  bool get isPlaying => _isPlaying;
  bool get hasText => _words.isNotEmpty;
  int? get countdown => _countdown;
  int? get pendingResumeIndex => _pendingResumeIndex;

  double get progress => _words.isEmpty ? 0 : _currentIndex / _words.length;
  String get currentWord => _words.isEmpty ? '' : _words[_currentIndex];
  bool get isFinished => _words.isNotEmpty && _currentIndex >= _words.length - 1;
  int get wordsRemaining => _words.isEmpty ? 0 : _words.length - _currentIndex;
  double get minutesLeft => _wpm == 0 ? 0 : wordsRemaining / _wpm;

  List<MapEntry<int, String>> get contextWords {
    if (_words.isEmpty) return [];
    final start = max(0, _currentIndex - 8);
    final end = min(_words.length - 1, _currentIndex + 15);
    return [for (var i = start; i <= end; i++) MapEntry(i, _words[i])];
  }

  ReaderProvider() {
    final prefs = PreferencesService.instance;
    _wpm = prefs.wpm;
    _fontSize = prefs.fontSize;
  }

  void loadText(String text) {
    _timer?.cancel();
    _rawText = text;
    _words = text
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    _currentIndex = 0;
    _isPlaying = false;
    _hasStarted = false;
    _countdown = null;

    final prefs = PreferencesService.instance;
    final savedIndex = prefs.lastWordIndex;
    if (prefs.lastTextKey == _bookmarkKey && savedIndex != null && savedIndex < _words.length) {
      _pendingResumeIndex = savedIndex;
    } else {
      _pendingResumeIndex = null;
    }

    notifyListeners();
  }

  void setWpm(int wpm) {
    _wpm = wpm.clamp(50, 1000);
    PreferencesService.instance.saveWpm(_wpm);
    if (_isPlaying) {
      _timer?.cancel();
      _scheduleNext();
    }
    notifyListeners();
  }

  void setFontSize(double size) {
    _fontSize = size.clamp(24.0, 80.0);
    PreferencesService.instance.saveFontSize(_fontSize);
    notifyListeners();
  }

  void acceptResume() {
    if (_pendingResumeIndex != null) {
      _currentIndex = _pendingResumeIndex!.clamp(0, _words.length - 1);
    }
    _pendingResumeIndex = null;
    notifyListeners();
  }

  void declineResume() {
    _pendingResumeIndex = null;
    notifyListeners();
  }

  void togglePlayPause() {
    if (_countdown != null) {
      _cancelCountdown();
      return;
    }
    if (_isPlaying) {
      pause();
    } else {
      play();
    }
  }

  void play() {
    if (_words.isEmpty) return;
    if (isFinished) {
      _currentIndex = 0;
      _hasStarted = false;
    }
    if (!_hasStarted) {
      _startCountdown();
    } else {
      _resumeDirectly();
    }
  }

  void pause() {
    _timer?.cancel();
    _isPlaying = false;
    _saveBookmark();
    notifyListeners();
  }

  void restart() {
    _timer?.cancel();
    _currentIndex = 0;
    _isPlaying = false;
    _hasStarted = false;
    _countdown = null;
    notifyListeners();
  }

  void stepForward() {
    _cancelCountdown();
    if (_currentIndex < _words.length - 1) {
      _currentIndex++;
      notifyListeners();
    }
  }

  void stepBackward() {
    _cancelCountdown();
    if (_currentIndex > 0) {
      _currentIndex--;
      notifyListeners();
    }
  }

  void _startCountdown() {
    _countdown = 3;
    notifyListeners();
    _timer = Timer.periodic(const Duration(milliseconds: 750), (t) {
      if (_countdown != null && _countdown! > 1) {
        _countdown = _countdown! - 1;
        notifyListeners();
      } else {
        t.cancel();
        _countdown = null;
        _hasStarted = true;
        _isPlaying = true;
        notifyListeners();
        _scheduleNext();
      }
    });
  }

  void _cancelCountdown() {
    if (_countdown != null) {
      _timer?.cancel();
      _countdown = null;
      notifyListeners();
    }
  }

  void _resumeDirectly() {
    _isPlaying = true;
    notifyListeners();
    _scheduleNext();
  }

  void _scheduleNext() {
    if (!_isPlaying || _words.isEmpty) return;
    if (_currentIndex >= _words.length - 1) {
      pause();
      return;
    }
    _timer = Timer(_delayForWord(_words[_currentIndex]), () {
      if (!_isPlaying) return;
      _currentIndex++;
      if (_currentIndex % 20 == 0) _saveBookmark();
      notifyListeners();
      _scheduleNext();
    });
  }

  // Longer pause after sentence-ending and clause-ending punctuation
  Duration _delayForWord(String word) {
    final base = 60000.0 / _wpm;
    final last = word.isEmpty ? '' : word[word.length - 1];
    double mult = 1.0;
    if ('.!?…'.contains(last)) mult = 2.5;
    else if (',;:'.contains(last)) mult = 1.5;
    return Duration(milliseconds: (base * mult).round());
  }

  String get _bookmarkKey {
    final flat = _rawText.replaceAll(RegExp(r'\s+'), ' ').trim();
    return flat.substring(0, min(100, flat.length));
  }

  void _saveBookmark() {
    if (_words.isEmpty || _bookmarkKey.isEmpty) return;
    PreferencesService.instance.saveBookmark(_bookmarkKey, _currentIndex);
  }

  static int orpIndex(String word) {
    final len = word.replaceAll(RegExp(r'[^a-zA-Z]'), '').length;
    if (len <= 1) return 0;
    if (len <= 5) return 1;
    if (len <= 9) return 2;
    return 3;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
