import 'package:flutter_test/flutter_test.dart';
import 'package:monster_reader/providers/reader_provider.dart';

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
  });
}
