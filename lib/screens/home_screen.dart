import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf_text/pdf_text.dart';
import 'package:provider/provider.dart';

import '../providers/reader_provider.dart';
import '../services/epub_service.dart';
import '../services/text_preprocessor.dart';
import 'reader_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _controller = TextEditingController();
  bool _loadingFile = false;
  String? _importError;
  int _wordCount = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final text = _controller.text.trim();
    final count = text.isEmpty ? 0 : text.split(RegExp(r'\s+')).length;
    if (count != _wordCount) setState(() => _wordCount = count);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _startReading() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.mediumImpact();
    context.read<ReaderProvider>().loadText(text);
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ReaderScreen()));
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    final text = data?.text?.trim() ?? '';
    if (text.isEmpty) return;
    setState(() {
      _controller.text = text;
      _importError = null;
    });
    HapticFeedback.lightImpact();
  }

  Future<void> _importFile() async {
    setState(() {
      _loadingFile = true;
      _importError = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'epub'],
      );

      if (result == null || result.files.single.path == null) {
        setState(() => _loadingFile = false);
        return;
      }

      final path = result.files.single.path!;
      final file = File(path);
      final ext = path.split('.').last.toLowerCase();

      String raw;
      if (ext == 'epub') {
        raw = await EpubService.extractText(file);
      } else {
        final doc = await PDFDoc.fromFile(file);
        raw = await doc.text;
      }

      if (raw.trim().isEmpty) {
        setState(() {
          _importError = ext == 'epub'
              ? 'Could not extract text from this ePub.'
              : 'Could not extract text — PDF may be image-based.';
          _loadingFile = false;
        });
        return;
      }

      final cleaned = TextPreprocessor.clean(raw);
      setState(() {
        _controller.text = cleaned;
        _importError = null;
      });
      HapticFeedback.lightImpact();
    } catch (_) {
      setState(() => _importError = 'Failed to read file. Please try another.');
    } finally {
      setState(() => _loadingFile = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Monster Reader',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_loadingFile)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Color(0xFFFF4444)),
                ),
              ),
            )
          else
            IconButton(
              onPressed: _importFile,
              icon: const Icon(Icons.file_open_outlined),
              color: const Color(0xFFFF4444),
              tooltip: 'Import PDF or ePub',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_importError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Color(0xFFFF4444), size: 15),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(_importError!,
                          style: const TextStyle(
                              color: Color(0xFFFF4444), fontSize: 12)),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: const TextStyle(
                    fontSize: 15, height: 1.6, color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Paste text here, or use the import button above…',
                  hintStyle: const TextStyle(color: Colors.white38),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFFFF4444), width: 2),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: _pasteFromClipboard,
                  icon: const Icon(Icons.content_paste_rounded, size: 16),
                  label: const Text('Paste'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white54,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
                if (_wordCount > 0)
                  Text(
                    '$_wordCount words · ~${(_wordCount / 250).toStringAsFixed(0)} min @ 250 wpm',
                    style:
                        const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _wordCount > 0 ? _startReading : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF4444),
                  disabledBackgroundColor: Colors.white12,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text(
                  'Start Reading',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
