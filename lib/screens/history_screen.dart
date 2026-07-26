import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/whisper_service.dart';
import 'file_viewer_screen.dart';

class HistoryScreen extends StatefulWidget {
  final WhisperService whisperService;

  const HistoryScreen({super.key, required this.whisperService});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<File> _files = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() => _isLoading = true);
    try {
      final files = await widget.whisperService.getSavedSrtFiles();
      // Sort by modified date descending
      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      setState(() {
        _files = files;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'History',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.deepPurpleAccent))
          : _files.isEmpty
              ? Center(
                  child: Text(
                    'No captions generated yet.',
                    style: GoogleFonts.outfit(color: Colors.white54, fontSize: 16),
                  ),
                )
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _files.length,
                  itemBuilder: (context, index) {
                    final file = _files[index];
                    final name = file.uri.pathSegments.last;
                    final size = (file.lengthSync() / 1024).toStringAsFixed(1);
                    
                    return Card(
                      color: Colors.white.withOpacity(0.05),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const Icon(Icons.description, color: Colors.deepPurpleAccent),
                        title: Text(
                          name,
                          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          '$size KB • ${file.lastModifiedSync().toString().split('.')[0]}',
                          style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.folder_open_rounded, color: Colors.white70),
                          tooltip: 'Open Folder Location',
                          onPressed: () => WhisperService.openFolderLocation(file.path),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FileViewerScreen(file: file),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
    );
  }
}
