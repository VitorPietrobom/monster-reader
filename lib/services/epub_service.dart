import 'dart:io';
import 'package:epubx/epubx.dart';

class EpubService {
  static Future<String> extractText(File file) async {
    final bytes = await file.readAsBytes();
    final book = await EpubReader.readBookAsync(bytes);

    final buffer = StringBuffer();
    for (final chapter in book.Chapters ?? []) {
      _extractChapter(chapter, buffer);
    }
    return buffer.toString().trim();
  }

  static void _extractChapter(EpubChapter chapter, StringBuffer buf) {
    final html = chapter.HtmlContent ?? '';
    if (html.isNotEmpty) {
      final text = html
          .replaceAll(RegExp(r'<[^>]+>'), ' ')
          .replaceAll('&nbsp;', ' ')
          .replaceAll('&amp;', '&')
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>')
          .replaceAll('&quot;', '"')
          .replaceAll('&#39;', "'")
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      if (text.isNotEmpty) {
        buf
          ..writeln(text)
          ..writeln();
      }
    }
    for (final sub in chapter.SubChapters ?? []) {
      _extractChapter(sub, buf);
    }
  }
}
