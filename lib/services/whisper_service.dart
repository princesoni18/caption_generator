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
    if (Platform.isWindows) {
      return await _transcribeWithPython(audioFilePath, isHinglish);
    }
    
    debugPrint('WhisperService.transcribeToSrt called. Audio: $audioFilePath, Hinglish: $isHinglish');
    
    final transcribeRequest = TranscribeRequest(
      audio: audioFilePath,
      language: isHinglish ? 'hi' : 'en', 
      threads: Platform.numberOfProcessors > 0 ? Platform.numberOfProcessors : 6,
      speedUp: true, // Enables 2x audio speedup for faster processing
      initialPrompt: isHinglish ? "ki aaj maine seekha ki kaise hum caption bna skte h" : null,
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

  Future<String> _transcribeWithPython(String audioFilePath, bool isHinglish) async {
    debugPrint('Using Python Whisper for Windows...');
    final tempDir = await getTemporaryDirectory();
    final scriptFile = File('${tempDir.path}/windows_whisper.py');
    final srtFile = File('${tempDir.path}/temp_output.srt');

    if (!await scriptFile.exists()) {
      await scriptFile.writeAsString(_windowsPythonScript);
    }

    List<String> args = [scriptFile.path, audioFilePath, '-o', srtFile.path];
    if (isHinglish) {
      args.add('--hinglish');
    }

    final result = await Process.run('python', args);
    debugPrint('Python Script Output: ${result.stdout}');
    if (result.stderr.toString().isNotEmpty) {
      debugPrint('Python Script Error: ${result.stderr}');
    }

    if (await srtFile.exists()) {
      final content = await srtFile.readAsString();
      await srtFile.delete();
      return content;
    } else {
      throw Exception('Python Whisper failed to generate SRT. Error: ${result.stderr}');
    }
  }

  static const String _windowsPythonScript = r'''
import os
import argparse
import logging
import torch
import whisper

logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")
log = logging.getLogger(__name__)

def format_timestamp(seconds: float) -> str:
    """Convert seconds to SRT timestamp format (HH:MM:SS,mmm)"""
    hours = int(seconds // 3600)
    minutes = int((seconds % 3600) // 60)
    secs = int(seconds % 60)
    millis = int((seconds - int(seconds)) * 1000)
    return f"{hours:02d}:{minutes:02d}:{secs:02d},{millis:03d}"

def generate_srt(input_path: str, output_path: str, is_hinglish: bool):
    if not os.path.exists(input_path):
        log.error(f"Input file not found: {input_path}")
        return

    _device = "cuda" if torch.cuda.is_available() else "cpu"
    
    try:
        log.info(f"Loading Whisper 'medium' model on {_device}...")
        _whisper = whisper.load_model("medium", device=_device)
    except torch.cuda.OutOfMemoryError:
        log.warning(f"CUDA OutOfMemoryError: Not enough VRAM available for 'medium' model on {_device}.")
        log.info("Falling back to CPU...")
        _device = "cpu"
        _whisper = whisper.load_model("medium", device=_device)
    
    log.info("Detecting language...")
    audio = whisper.load_audio(input_path)
    audio_clip = whisper.pad_or_trim(audio)
    mel = whisper.log_mel_spectrogram(audio_clip).to(_device)
    _, probs = _whisper.detect_language(mel)
    detected_lang = max(probs, key=probs.get)
    log.info(f"Detected language: {detected_lang} ({probs[detected_lang]:.2f})")

    initial_prompt = None
    if is_hinglish:
        log.info(f"Transcribing (Hinglish mode) in {detected_lang}...")
        initial_prompt = (
            "Yaar dekho, aisa hota h. Architecture mein kya difference h, "
            "samjhte ho? Bilkul sahi kaha. Toh basically kya h ki, "
            "ek dum clear h yeh concept. Matlab simply bolo toh."
        )
    else:
        log.info(f"Transcribing (Standard mode) in {detected_lang}...")

    result = _whisper.transcribe(
        input_path,
        task="transcribe",
        language=detected_lang,
        initial_prompt=initial_prompt,
        word_timestamps=True,
        verbose=False,
        condition_on_previous_text=True,
    )
    
    # Generate SRT content
    log.info("Generating SRT file...")
    with open(output_path, "w", encoding="utf-8") as srt_file:
        for i, segment in enumerate(result["segments"], start=1):
            start_time = format_timestamp(segment["start"])
            end_time = format_timestamp(segment["end"])
            text = segment["text"].strip()
            
            srt_file.write(f"{i}\n")
            srt_file.write(f"{start_time} --> {end_time}\n")
            srt_file.write(f"{text}\n\n")

    log.info(f"Successfully saved transcript to: {output_path}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate SRT captions using Whisper")
    parser.add_argument("input", help="Path to the input video/audio file")
    parser.add_argument("-o", "--output", help="Optional output SRT file path")
    parser.add_argument("--hinglish", action="store_true", help="Enable Hinglish transcription context")
    args = parser.parse_args()

    input_file = args.input
    output_file = args.output
    
    if not output_file:
        base, _ = os.path.splitext(input_file)
        output_file = f"{base}.srt"

    generate_srt(input_file, output_file, args.hinglish)
''';

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
