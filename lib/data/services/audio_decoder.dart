import 'dart:io';
import 'dart:typed_data';

import 'package:ffmpeg_kit_extended_flutter/ffmpeg_kit_extended_flutter.dart';

class AudioDecoder {
  static const _sampleRate = 16000;

  static Future<AudioDecoder> load() async {
    await FFmpegKitExtended.initialize();
    return AudioDecoder();
  }

  Future<Float32List> decode(String path) async {
    final directory = await Directory.systemTemp.createTemp('crate_');
    final output = File('${directory.path}/audio.f32');
    try {
      final session = await FFmpegKit.createSessionFromArguments([
        '-v', 'error',
        '-i', path,
        '-map', '0:a:0',
        // same as librosa.load(sr=16000, mono=True): channel mean (ffmpeg's -ac 1 is 3 dB louder) and soxr_hq
        '-af',
        'aresample=osr=$_sampleRate:ochl=mono:rematrix_maxval=1:resampler=soxr:precision=20',
        '-f', 'f32le',
        output.path,
      ]).executeAsync();
      if (!ReturnCode.isSuccess(session.getReturnCode())) {
        throw Exception('Failed to decode $path: ${session.getOutput()}');
      }
      return Float32List.sublistView(await output.readAsBytes());
    } finally {
      await directory.delete(recursive: true);
    }
  }
}
