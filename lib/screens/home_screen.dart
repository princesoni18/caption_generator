import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/whisper_service.dart';
import 'transcription_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  final String modelPath;

  const HomeScreen({super.key, required this.modelPath});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isHinglish = false;

  Future<void> _pickFile(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.media,
    );

    if (result != null && result.files.single.path != null) {
      String filePath = result.files.single.path!;
      
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TranscriptionScreen(
              modelPath: widget.modelPath,
              audioPath: filePath,
              isHinglish: _isHinglish,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Transcription'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'View History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HistoryScreen(
                    whisperService: WhisperService(modelPath: widget.modelPath),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Upload your video or audio to generate a highly accurate .srt caption file.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 40),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment<bool>(
                    value: false,
                    label: Text('English'),
                    icon: Icon(Icons.language),
                  ),
                  ButtonSegment<bool>(
                    value: true,
                    label: Text('Hinglish'),
                    icon: Icon(Icons.translate),
                  ),
                ],
                selected: {_isHinglish},
                onSelectionChanged: (Set<bool> newSelection) {
                  setState(() {
                    _isHinglish = newSelection.first;
                  });
                },
                style: SegmentedButton.styleFrom(
                  backgroundColor: Colors.grey.shade900,
                  selectedBackgroundColor: Colors.deepPurpleAccent.withOpacity(0.3),
                  selectedForegroundColor: Colors.deepPurpleAccent.shade100,
                ),
              ),
              const SizedBox(height: 30),
              GestureDetector(
                onTap: () => _pickFile(context),
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.deepPurpleAccent.withOpacity(0.5), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurpleAccent.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        size: 60,
                        color: Colors.deepPurpleAccent.shade100,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Tap to Select File',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Supports MP4, MP3, WAV, etc.',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
