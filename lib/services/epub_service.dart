import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';

class EpubService {
  static Future<String> extractText(File file) async {
    final bytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    // Collect HTML/XHTML content files, excluding navigation/TOC files
    final htmlFiles = archive.files
        .where((f) =>
            f.isFile &&
            (f.name.endsWith('.html') ||
                f.name.endsWith('.xhtml') ||
                f.name.endsWith('.htm')) &&
            !f.name.toLowerCase().contains('toc') &&
            !f.name.toLowerCase().contains('nav'))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    final buffer = StringBuffer();
    for (final entry in htmlFiles) {
      final raw = entry.content as List<int>;
      final html = utf8.decode(raw, allowMalformed: true);
      final text = _stripHtml(html);
      if (text.trim().isNotEmpty) {
        buffer
          ..writeln(text.trim())
          ..writeln();
      }
    }
    return buffer.toString().trim();
  }

  static String _stripHtml(String html) => html
      .replaceAll(
          RegExp(r'<style[^>]*>.*?</style>', dotAll: true, caseSensitive: false), '')
      .replaceAll(
          RegExp(r'<script[^>]*>.*?</script>', dotAll: true, caseSensitive: false), '')
      .replaceAll(RegExp(r'<[^>]+>'), ' ')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
