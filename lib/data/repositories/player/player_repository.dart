import 'dart:async';

import 'package:just_audio/just_audio.dart';

class PlayerRepository {
  final _player = AudioPlayer();

  Stream<Duration> watchPosition() => _player.positionStream;

  Stream<Duration?> watchDuration() => _player.durationStream;

  Stream<ProcessingState> watchFinished() => _player.processingStateStream
      .where((state) => state == ProcessingState.completed);

  Future<void> open(String path) => _player.setFilePath(path);

  // just_audio's play() only completes once playback stops
  void play() => unawaited(_player.play());

  Future<void> pause() => _player.pause();

  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> dispose() => _player.dispose();
}
