import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../services/whisper_service.dart';
import '../services/notification_service.dart';
import 'history_screen.dart';

class TranscriptionScreen extends StatefulWidget {
  final String modelPath;
  final String audioPath;
  final bool isHinglish;

  const TranscriptionScreen({
    super.key,
    required this.modelPath,
    required this.audioPath,
    required this.isHinglish,
  });

  @override
  State<TranscriptionScreen> createState() => _TranscriptionScreenState();
}

class _TranscriptionScreenState extends State<TranscriptionScreen> with SingleTickerProviderStateMixin {
  late final WhisperService _whisperService;
  late AnimationController _pulseController;
  Timer? _elapsedTimer;
  int _secondsElapsed = 0;
  
  bool _isProcessing = true;
  String _status = "Initializing AI...";
  String _srtContent = "";
  String? _savedFilePath;
  
  int _progress = 0;
  Timer? _progressTimer;
  String? _progressFilePath;

  @override
  void initState() {
    super.initState();
    _whisperService = WhisperService(modelPath: widget.modelPath);
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _isProcessing) {
        setState(() {
          _secondsElapsed++;
        });
      }
    });

    _startTranscription();
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    _progressTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  String get _formattedTime {
    final m = (_secondsElapsed ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsElapsed % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  Future<void> _startTranscription() async {
    try {
      debugPrint('--- Starting Transcription Process ---');
      final tempDir = await getTemporaryDirectory();
      _progressFilePath = '${tempDir.path}/whisper_progress_${DateTime.now().millisecondsSinceEpoch}.txt';
      debugPrint('Progress file path set to: $_progressFilePath');
      
      // Clear old progress file
      final progressFile = File(_progressFilePath!);
      if (progressFile.existsSync()) {
        progressFile.deleteSync();
      }

      _progressTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) async {
        if (!mounted || !_isProcessing) {
          timer.cancel();
          return;
        }
        if (progressFile.existsSync()) {
          try {
            final content = await progressFile.readAsString();
            final progressVal = int.tryParse(content.trim());
            if (progressVal != null && progressVal >= 0 && progressVal <= 100) {
              setState(() {
                _progress = progressVal;
              });
            }
          } catch (e) {
            // ignore read errors
          }
        }
      });

      setState(() {
        _status = "Transcribing with Medium Model...\nThis might take a few minutes.";
      });

      debugPrint('Starting foreground service...');
      await NotificationService().startTranscriptionForegroundService();

      debugPrint('Calling _whisperService.transcribeToSrt...');
      final content = await _whisperService.transcribeToSrt(
        widget.audioPath,
        isHinglish: widget.isHinglish,
        progressPath: _progressFilePath,
      );
      debugPrint('Transcription complete. Content length: ${content.length}');
      
      setState(() {
        _status = "Saving .srt file...";
      });

      debugPrint('Calling _whisperService.saveSrtFile...');
      final savedPath = await _whisperService.saveSrtFile(widget.audioPath, content);
      debugPrint('SRT file saved at: $savedPath');

      await NotificationService().stopForegroundServiceAndNotifySuccess();

      setState(() {
        _srtContent = content;
        _savedFilePath = savedPath;
        _isProcessing = false;
        _status = "Success!";
      });
      
      // Auto navigate to history after short delay
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => HistoryScreen(whisperService: _whisperService)),
          );
        }
      });
      
    } catch (e, stackTrace) {
      debugPrint('Error caught in _startTranscription: $e\n$stackTrace');
      await NotificationService().stopForegroundServiceAndNotifyError(e.toString());
      setState(() {
        _isProcessing = false;
        _status = "An error occurred:\n$e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Processing'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isProcessing)
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      padding: EdgeInsets.all(20 + (_pulseController.value * 20)),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.deepPurpleAccent.withOpacity(0.2 * (1 - _pulseController.value)),
                      ),
                      child: const Icon(
                        Icons.settings_voice_rounded,
                        size: 80,
                        color: Colors.deepPurpleAccent,
                      ),
                    );
                  }
                )
              else
                const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 100,
                  color: Colors.greenAccent,
                ),
              
              const SizedBox(height: 40),
              
              if (_isProcessing)
                Text(
                  'Elapsed Time: $_formattedTime',
                  style: const TextStyle(
                    color: Colors.deepPurpleAccent,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
              const SizedBox(height: 20),
              
              if (_isProcessing) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: _progress > 0 ? _progress / 100.0 : null,
                      minHeight: 12,
                      backgroundColor: Colors.white12,
                      color: Colors.greenAccent,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '$_progress%',
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],

              const SizedBox(height: 20),
              
              Text(
                _status,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: _isProcessing ? Colors.white : Colors.greenAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),

              if (!_isProcessing && _savedFilePath != null) ...[
                const SizedBox(height: 20),
                Text(
                  'Saved to: $_savedFilePath',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
