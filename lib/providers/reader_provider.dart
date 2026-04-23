import 'dart:async';
import 'package:flutter/foundation.dart';

class ReaderProvider extends ChangeNotifier {
  List<String> _words = [];
  int _currentIndex = 0;
  int _wpm = 250;
  double _fontSize = 48.0;
  bool _isPlaying = false;
  Timer? _timer;

  List<String> get words => _words;
  int get currentIndex => _currentIndex;
  int get wpm => _wpm;
  double get fontSize => _fontSize;
  bool get isPlaying => _isPlaying;
  bool get hasText => _words.isNotEmpty;

  double get progress => _words.isEmpty ? 0 : _currentIndex / _words.length;
  String get currentWord => _words.isEmpty ? '' : _words[_currentIndex];
  bool get isFinished => _currentIndex >= _words.length - 1;

  void loadText(String text) {
    _words = text
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    _currentIndex = 0;
    _isPlaying = false;
    _timer?.cancel();
    notifyListeners();
  }

  void setWpm(int wpm) {
    _wpm = wpm.clamp(50, 1000);
    if (_isPlaying) _restartTimer();
    notifyListeners();
  }

  void setFontSize(double size) {
    _fontSize = size.clamp(24.0, 80.0);
    notifyListeners();
  }

  void play() {
    if (_words.isEmpty || isFinished) return;
    _isPlaying = true;
    _restartTimer();
    notifyListeners();
  }

  void pause() {
    _isPlaying = false;
    _timer?.cancel();
    notifyListeners();
  }

  void togglePlayPause() {
    if (_isPlaying) {
      pause();
    } else {
      if (isFinished) restart();
      else play();
    }
  }

  void restart() {
    _timer?.cancel();
    _currentIndex = 0;
    _isPlaying = false;
    notifyListeners();
  }

  void stepForward() {
    if (_currentIndex < _words.length - 1) {
      _currentIndex++;
      notifyListeners();
    }
  }

  void stepBackward() {
    if (_currentIndex > 0) {
      _currentIndex--;
      notifyListeners();
    }
  }

  void _restartTimer() {
    _timer?.cancel();
    final interval = Duration(milliseconds: (60000 / _wpm).round());
    _timer = Timer.periodic(interval, (_) {
      if (_currentIndex < _words.length - 1) {
        _currentIndex++;
        notifyListeners();
      } else {
        pause();
      }
    });
  }

  // Optimal recognition point: the letter the eye should anchor on
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
