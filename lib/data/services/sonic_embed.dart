import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_edge_ai/flutter_edge_ai.dart';

class SonicEmbed {
  static const windowSeconds = 10;
  static const _sampleRate = 16000;
  static const _windowLength = windowSeconds * _sampleRate;

  final EmbeddingModel _model;

  SonicEmbed(this._model);

  static Future<SonicEmbed> load(File bundle) async {
    await FlutterEdgeAi.installEmbedder().modelFromFile(bundle.path).install();
    final model = await FlutterEdgeAi.getActiveEmbedder(
      preferredBackend: PreferredBackend.cpu,
      supportAudio: true,
    );
    return SonicEmbed(model);
  }

  // the model already returns unit-length vectors, so dot product is cosine
  Future<Float32List> embedQuery(String query) async {
    final embedding = await _model.embed(
      EmbeddingInput.text(query),
      taskType: TaskType.retrievalQuery,
    );
    return Float32List.fromList(embedding);
  }

  // the partial last window is mostly silence, which matches every query
  Future<List<Float32List>> embedWindows(Float32List samples) async {
    final windowCount = samples.length ~/ _windowLength;
    final clips = [
      for (var window = 0; window < windowCount; window++)
        Float32List.sublistView(
          samples,
          window * _windowLength,
          (window + 1) * _windowLength,
        ),
    ];
    // songs shorter than one window are embedded whole
    if (clips.isEmpty) clips.add(samples);

    final embeddings = await _model.embedAll([
      for (final clip in clips) EmbeddingInput.audio(_wav(clip)),
    ], taskType: TaskType.none);
    return [
      for (final embedding in embeddings) Float32List.fromList(embedding),
    ];
  }

  // the plugin only takes encoded audio files, so wrap the samples in a
  // 44-byte WAV header: RIFF size, fmt chunk, then the data chunk
  static Uint8List _wav(Float32List clip) {
    final format = ByteData(16)
      // format 3 (32-bit float), 1 channel, sample rate, bytes per second,
      // bytes per sample, bits per sample
      ..setUint16(0, 3, Endian.little)
      ..setUint16(2, 1, Endian.little)
      ..setUint32(4, _sampleRate, Endian.little)
      ..setUint32(8, _sampleRate * 4, Endian.little)
      ..setUint16(12, 4, Endian.little)
      ..setUint16(14, 32, Endian.little);
    // the clip's own bytes, since it's a view into the whole song
    final samples = clip.buffer.asUint8List(
      clip.offsetInBytes,
      clip.lengthInBytes,
    );
    final wav = BytesBuilder(copy: false)
      ..add(ascii.encode('RIFF'))
      // file size minus these first 8 bytes
      ..add(_uint32(36 + samples.length))
      ..add(ascii.encode('WAVEfmt '))
      ..add(_uint32(format.lengthInBytes))
      ..add(format.buffer.asUint8List())
      ..add(ascii.encode('data'))
      ..add(_uint32(samples.length))
      ..add(samples);
    return wav.takeBytes();
  }

  static Uint8List _uint32(int value) {
    final bytes = ByteData(4)..setUint32(0, value, Endian.little);
    return bytes.buffer.asUint8List();
  }
}
