import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/dependencies.dart';
import '../data/repositories/player/player_repository.dart';
import '../data/services/database/track.dart';
import '../models/playback_state.dart';

final playbackProvider = NotifierProvider(PlaybackNotifier.new);

final currentTrackProvider = Provider(
  (ref) => ref.watch(playbackProvider.select((state) => state.track)),
);

final positionProvider = StreamProvider(
  (ref) => ref.watch(playerRepositoryProvider).watchPosition(),
);

final durationProvider = StreamProvider(
  (ref) => ref.watch(playerRepositoryProvider).watchDuration(),
);

final progressProvider = Provider((ref) {
  final position = ref.watch(positionProvider).value ?? Duration.zero;
  final duration = ref.watch(durationProvider).value;
  if (duration == null || duration == Duration.zero) return 0.0;
  return (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
});

class PlaybackNotifier extends Notifier<PlaybackState> {
  late PlayerRepository _player;

  @override
  PlaybackState build() {
    _player = ref.watch(playerRepositoryProvider);
    final subscription = _player.watchFinished().listen((_) => _finish());
    ref.onDispose(subscription.cancel);
    return const PlaybackState();
  }

  Future<void> playFrom(Track track, Duration start) async {
    final opened = state.isCurrent(track);
    state = PlaybackState(track: track, playing: true);
    if (!opened) {
      await _player.open(track.path);
      // another song may have been picked while this one opened
      if (!state.isCurrent(track)) return;
    }
    await _player.seek(start);
    _player.play();
  }

  Future<void> toggle(Track track) async {
    if (!state.isCurrent(track)) return playFrom(track, Duration.zero);

    if (state.playing) {
      state = PlaybackState(track: track);
      await _player.pause();
      return;
    }
    state = PlaybackState(track: track, playing: true);
    _player.play();
  }

  // a drag past either end of the waveform asks for a spot outside the song
  Future<void> seek(double fraction) async {
    final duration = ref.read(durationProvider).value;
    if (duration == null) return;
    await _player.seek(duration * fraction.clamp(0.0, 1.0));
  }

  Future<void> _finish() async {
    state = PlaybackState(track: state.track);
    await _player.pause();
    await _player.seek(Duration.zero);
  }
}
