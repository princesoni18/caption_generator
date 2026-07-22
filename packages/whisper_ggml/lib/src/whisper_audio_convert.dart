import 'dart:async';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/foundation.dart';
import 'package:universal_io/io.dart';

/// Class used to convert any audio file to wav
class WhisperAudioConvert {
  ///
  const WhisperAudioConvert({
    required this.audioInput,
    required this.audioOutput,
  });

  /// Input audio file
  final File audioInput;

  /// Output audio file
  /// Overwriten if already exist
  final File audioOutput;

  /// convert [audioInput] to wav file
  Future<File?> convert() async {
    debugPrint('WhisperAudioConvert.convert() started. Input: ${audioInput.path}, Target Output: ${audioOutput.path}');
    final FFmpegSession session = await FFmpegKit.executeWithArguments([
      '-y',
      '-i',
      audioInput.path,
      '-ar',
      '16000',
      '-ac',
      '1',
      '-c:a',
      'pcm_s16le',
      audioOutput.path,
    ]);

    final ReturnCode? returnCode = await session.getReturnCode();
    debugPrint('WhisperAudioConvert.convert() finished. FFmpeg Return Code: ${returnCode?.getValue()}');

    if (ReturnCode.isSuccess(returnCode)) {
      return audioOutput;
    } else if (ReturnCode.isCancel(returnCode)) {
      debugPrint('File convertion canceled');
    } else {
      debugPrint('File convertion error with returnCode ${returnCode?.getValue()}');
    }

    return null;
  }
}
