import 'package:flutter_test/flutter_test.dart';
import 'package:monster_reader/providers/reader_provider.dart';
import 'package:monster_reader/services/text_preprocessor.dart';

void main() {
  group('ReaderProvider', () {
    test('loads text and splits into words', () {
      final provider = ReaderProvider();
      provider.loadText('Hello world foo');
      expect(provider.words, ['Hello', 'world', 'foo']);
      expect(provider.currentIndex, 0);
      expect(provider.isPlaying, false);
    });

    test('ORP index is correct', () {
      expect(ReaderProvider.orpIndex('I'), 0);
      expect(ReaderProvider.orpIndex('the'), 1);
      expect(ReaderProvider.orpIndex('hello'), 1);
      expect(ReaderProvider.orpIndex('flutter'), 2);
      expect(ReaderProvider.orpIndex('foundation'), 3);
    });

    test('stepForward and stepBackward work', () {
      final provider = ReaderProvider();
      provider.loadText('one two three');
      provider.stepForward();
      expect(provider.currentIndex, 1);
      provider.stepBackward();
      expect(provider.currentIndex, 0);
    });

    test('restart resets to beginning', () {
      final provider = ReaderProvider();
      provider.loadText('one two three');
      provider.stepForward();
      provider.stepForward();
      provider.restart();
      expect(provider.currentIndex, 0);
      expect(provider.isPlaying, false);
    });

    test('fontSize clamps between 24 and 80', () {
      final provider = ReaderProvider();
      provider.setFontSize(100);
      expect(provider.fontSize, 80.0);
      provider.setFontSize(10);
      expect(provider.fontSize, 24.0);
    });

    test('wpm clamps between 50 and 1000', () {
      final provider = ReaderProvider();
      provider.setWpm(9999);
      expect(provider.wpm, 1000);
      provider.setWpm(1);
      expect(provider.wpm, 50);
    });

    test('wordsRemaining and minutesLeft are correct', () {
      final provider = ReaderProvider();
      provider.loadText('one two three four five');
      provider.setWpm(300);
      expect(provider.wordsRemaining, 5);
      expect(provider.minutesLeft, closeTo(5 / 300, 0.001));
    });

    test('contextWords returns window around current index', () {
      final provider = ReaderProvider();
      provider.loadText(List.generate(30, (i) => 'word$i').join(' '));
      provider.stepForward(); // index 1
      final ctx = provider.contextWords;
      expect(ctx.any((e) => e.key == 1), true);
    });

    test('declineResume keeps index at 0', () {
      final provider = ReaderProvider();
      provider.loadText('one two three');
      provider.declineResume();
      expect(provider.currentIndex, 0);
      expect(provider.pendingResumeIndex, null);
    });
  });

  group('TextPreprocessor', () {
    test('removes standalone page numbers', () {
      final result = TextPreprocessor.clean('Hello\n\n42\n\nWorld');
      expect(result.contains('42'), false);
      expect(result.contains('Hello'), true);
      expect(result.contains('World'), true);
    });

    test('fixes hyphenated line breaks', () {
      final result = TextPreprocessor.clean('hyphen-\nated');
      expect(result.contains('hyphenated'), true);
    });

    test('collapses excessive newlines', () {
      final result = TextPreprocessor.clean('a\n\n\n\nb');
      expect(result, 'a\n\nb');
    });
  });
}
