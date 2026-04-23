import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf_text/pdf_text.dart';
import 'package:provider/provider.dart';

import '../providers/reader_provider.dart';
import 'reader_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _controller = TextEditingController();
  bool _loadingPdf = false;
  String? _pdfError;

  @override
  void dispose() {
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

  Future<void> _importPdf() async {
    setState(() {
      _loadingPdf = true;
      _pdfError = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result == null || result.files.single.path == null) {
        setState(() => _loadingPdf = false);
        return;
      }

      final file = File(result.files.single.path!);
      final doc = await PDFDoc.fromFile(file);
      final text = await doc.text;

      if (text.trim().isEmpty) {
        setState(() {
          _pdfError = 'Could not extract text from this PDF (may be image-based).';
          _loadingPdf = false;
        });
        return;
      }

      _controller.text = text.trim();
      HapticFeedback.lightImpact();
    } catch (e) {
      setState(() => _pdfError = 'Failed to read PDF. Please try another file.');
    } finally {
      setState(() => _loadingPdf = false);
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
          _loadingPdf
              ? const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFFF4444),
                      ),
                    ),
                  ),
                )
              : IconButton(
                  onPressed: _importPdf,
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  color: const Color(0xFFFF4444),
                  tooltip: 'Import PDF',
                ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_pdfError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Color(0xFFFF4444), size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _pdfError!,
                        style: const TextStyle(
                            color: Color(0xFFFF4444), fontSize: 12),
                      ),
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
                  hintText: 'Paste text here, or tap the PDF icon above to import…',
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
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _startReading,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF4444),
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
