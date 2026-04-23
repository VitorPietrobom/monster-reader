class TextPreprocessor {
  static String clean(String text) {
    return text
        // Rejoin words hyphenated across line breaks
        .replaceAll(RegExp(r'-\n'), '')
        // Drop lines that are only a page number
        .replaceAll(RegExp(r'(?m)^\s*\d+\s*$'), '')
        // Collapse 3+ consecutive newlines to a paragraph break
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        // Normalise horizontal whitespace
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .trim();
  }
}
