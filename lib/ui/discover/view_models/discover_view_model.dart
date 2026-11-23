import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/dependencies.dart';
import '../../../domain/library_notifier.dart';
import '../../../domain/playback_notifier.dart';
import '../../../models/search_result.dart';
import '../../../models/song_moment.dart';

final queryProvider = NotifierProvider(() => _Value(''));
final momentQueryProvider = NotifierProvider(() => _Value<SongMoment?>(null));

final discoverViewModelProvider = NotifierProvider(DiscoverViewModel.new);

class DiscoverViewModel extends Notifier<void> {
  @override
  void build() {}

  void search(String query) {
    ref.read(queryProvider.notifier).set(query.trim());
    ref.read(momentQueryProvider.notifier).set(null);
  }

  // the words stay, so going back returns to their matches
  void searchLikeNow() {
    final track = ref.read(playbackProvider).track;
    if (track == null) return;

    final position = ref.read(positionProvider).value ?? Duration.zero;
    ref.read(momentQueryProvider.notifier).set(SongMoment(track, position));
  }

  void clearMoment() => ref.read(momentQueryProvider.notifier).set(null);

  void play(SearchResult result) =>
      ref.read(playbackProvider.notifier).playFrom(result.track, result.start);

  void playOrPause(SearchResult result) {
    if (!ref.read(playbackProvider).isCurrent(result.track)) {
      return play(result);
    }
    ref.read(playbackProvider.notifier).toggle(result.track);
  }

  static List<double> _rescale(List<double> scores) {
    if (scores.isEmpty) return scores;

    final lowest = scores.reduce(min);
    final highest = scores.reduce(max);
    if (highest == lowest) return List.filled(scores.length, 1);
    return [for (final score in scores) (score - lowest) / (highest - lowest)];
  }
}

final queryEmbeddingProvider = FutureProvider.autoDispose((ref) async {
  final query = ref.watch(queryProvider);
  if (query.isEmpty) return null;

  final library = await ref.watch(libraryRepositoryProvider.future);
  return library.embedQuery(query);
});

final searchResultsProvider = FutureProvider.autoDispose((ref) async {
  final moment = ref.watch(momentQueryProvider);
  final embedding = await ref.watch(queryEmbeddingProvider.future);
  await ref.watch(libraryTracksProvider.future);
  final library = await ref.watch(libraryRepositoryProvider.future);

  if (moment != null) return library.searchLike(moment);
  if (embedding == null) return const <SearchResult>[];
  return library.searchText(embedding);
});

final momentScoresProvider = FutureProvider.autoDispose((ref) async {
  final track = ref.watch(currentTrackProvider);
  final moment = ref.watch(momentQueryProvider);
  final embedding = await ref.watch(queryEmbeddingProvider.future);
  if (track == null) return const <double>[];

  final library = await ref.watch(libraryRepositoryProvider.future);
  if (moment != null) {
    return DiscoverViewModel._rescale(library.likeScores(track, moment));
  }
  if (embedding == null) return const <double>[];
  return DiscoverViewModel._rescale(library.textScores(track, embedding));
});

final coverProvider = FutureProvider.autoDispose((ref) async {
  final track = ref.watch(currentTrackProvider);
  if (track == null) return null;

  final library = await ref.watch(libraryRepositoryProvider.future);
  return library.loadCover(track);
});

final waveformProvider = FutureProvider.autoDispose((ref) async {
  final track = ref.watch(currentTrackProvider);
  if (track == null) return const <double>[];

  final library = await ref.watch(libraryRepositoryProvider.future);
  return library.loadWaveform(track);
});

class _Value<T> extends Notifier<T> {
  final T _initial;

  _Value(this._initial);

  @override
  T build() => _initial;

  void set(T value) => state = value;
}
