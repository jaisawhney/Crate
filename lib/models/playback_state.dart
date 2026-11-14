import '../data/services/database/track.dart';

class PlaybackState {
  final Track? track;
  final bool playing;

  const PlaybackState({this.track, this.playing = false});

  bool isCurrent(Track track) => track.path == this.track?.path;

  bool isPlaying(Track track) => playing && isCurrent(track);
}
