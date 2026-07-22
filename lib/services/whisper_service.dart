import 'dart:io';
import 'package:whisper_ggml/whisper_ggml.dart';
import 'package:indic_transliteration_dart/indic_transliteration_dart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

class WhisperService {
  late final Whisper _whisper;
  final String modelPath;

  WhisperService({required this.modelPath}) {
    _whisper = Whisper(
      model: WhisperModel.medium, // Using medium model per user request
    );
  }

  Future<String> transcribeToSrt(String audioFilePath, {bool isHinglish = false, String? progressPath}) async {
    debugPrint('WhisperService.transcribeToSrt called. Audio: $audioFilePath, Hinglish: $isHinglish');
    
    final transcribeRequest = TranscribeRequest(
      audio: audioFilePath,
      language: isHinglish ? 'hi' : 'en', 
      threads: Platform.numberOfProcessors > 0 ? Platform.numberOfProcessors : 6,
      speedUp: true, // Enables 2x audio speedup for faster processing
    );

    debugPrint('Calling _whisper.transcribe...');
    final response = await _whisper.transcribe(
      transcribeRequest: transcribeRequest,
      modelPath: modelPath,
      progressPath: progressPath,
    );
    debugPrint('Received response from _whisper.transcribe. Generating SRT...');

    final srtContent = _generateSrtContent(response.segments ?? [], isHinglish);
    debugPrint('SRT generation complete.');
    return srtContent;
  }

  String _generateSrtContent(List<WhisperTranscribeSegment> segments, bool isHinglish) {
    final StringBuffer srtBuffer = StringBuffer();

    if (isHinglish) {
      initializeSchemes();
    }

    for (int i = 0; i < segments.length; i++) {
      final segment = segments[i];
      srtBuffer.writeln('${i + 1}');
      srtBuffer.writeln('${_formatDuration(segment.fromTs)} --> ${_formatDuration(segment.toTs)}');
      
      String text = segment.text.trim();
      if (isHinglish) {
        text = transliterate(text, fromScheme: devanagari, toScheme: itrans).toLowerCase();
      }
      
      srtBuffer.writeln(text);
      srtBuffer.writeln();
    }

    return srtBuffer.toString();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String threeDigits(int n) => n.toString().padLeft(3, "0");

    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    String milliseconds = threeDigits(duration.inMilliseconds.remainder(1000));

    return "$hours:$minutes:$seconds,$milliseconds";
  }

  Future<String> saveSrtFile(String audioFilePath, String srtContent) async {
    final File audioFile = File(audioFilePath);
    final String baseName = audioFile.uri.pathSegments.last.split('.').first;
    
    // Default to app documents
    String targetDir = (await getApplicationDocumentsDirectory()).path;
    
    if (Platform.isAndroid) {
      try {
        final Directory downloadDir = Directory('/storage/emulated/0/Download/CaptionGenerator');
        if (!await downloadDir.exists()) {
          await downloadDir.create(recursive: true);
        }
        targetDir = downloadDir.path;
      } catch (e) {
        // Fallback to app documents directory if permission is denied
        targetDir = (await getApplicationDocumentsDirectory()).path;
      }
    }

    String srtPath = '$targetDir/$baseName.srt';
    File srtFile = File(srtPath);
    
    try {
      await srtFile.writeAsString(srtContent);
    } catch (e) {
      // In case even writing fails, save directly to temporary or docs
      targetDir = (await getApplicationDocumentsDirectory()).path;
      srtPath = '$targetDir/$baseName.srt';
      srtFile = File(srtPath);
      await srtFile.writeAsString(srtContent);
    }
    
    return srtPath;
  }

  Future<List<File>> getSavedSrtFiles() async {
    final List<File> files = [];
    
    // Check app documents
    final String docsDir = (await getApplicationDocumentsDirectory()).path;
    final Directory dir1 = Directory(docsDir);
    if (await dir1.exists()) {
      files.addAll(dir1.listSync().whereType<File>().where((file) => file.path.endsWith('.srt')));
    }
    
    if (Platform.isAndroid) {
      // Check downloads folder
      try {
        final Directory dir2 = Directory('/storage/emulated/0/Download/CaptionGenerator');
        if (await dir2.exists()) {
          files.addAll(dir2.listSync().whereType<File>().where((file) => file.path.endsWith('.srt')));
        }
      } catch (e) {
        // Ignore if permission denied
      }
    }
    
    // Remove duplicates based on path just in case
    final uniqueFiles = <String, File>{};
    for (var f in files) {
      uniqueFiles[f.path] = f;
    }
    return uniqueFiles.values.toList();
  }
}
