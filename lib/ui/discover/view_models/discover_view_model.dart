import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/dependencies.dart';
import '../../../data/services/database/track.dart';
import '../../../domain/library_notifier.dart';
import '../../../domain/playback_notifier.dart';
import '../../../models/search_result.dart';
import '../../../models/song_moment.dart';

const defaultGenreCount = 6;
// one per color in the map's palette
const maxComparedGenres = 9;

final queryProvider = NotifierProvider(() => _Value(''));
final momentQueryProvider = NotifierProvider(() => _Value<SongMoment?>(null));
// null until the user picks genres to compare
final genreChoiceProvider = NotifierProvider(
  () => _Value<List<String?>?>(null),
);
final highlightProvider = NotifierProvider(() => _Value<int?>(null));

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

  void highlight(int? trackId) =>
      ref.read(highlightProvider.notifier).set(trackId);

  void play(SearchResult result) =>
      ref.read(playbackProvider.notifier).playFrom(result.track, result.start);

  void playOrPause(SearchResult result) {
    if (!ref.read(playbackProvider).isCurrent(result.track)) {
      return play(result);
    }
    ref.read(playbackProvider.notifier).toggle(result.track);
  }

  void playTrack(Track track) {
    final results = ref.read(searchResultsProvider).value ?? const [];
    for (final result in results) {
      if (result.track.id == track.id) return play(result);
    }
    ref.read(playbackProvider.notifier).playFrom(track, Duration.zero);
  }

  void toggleGenre(String genre) {
    final choice = ref.read(genreChoiceProvider.notifier);
    final slots = [...ref.read(comparedGenresProvider)];
    final slot = slots.indexOf(genre);
    if (slot != -1) {
      slots[slot] = null;
      return choice.set(slots);
    }

    final free = slots.indexOf(null);
    if (free != -1) {
      slots[free] = genre;
      return choice.set(slots);
    }

    if (slots.length >= maxComparedGenres) return;
    choice.set([...slots, genre]);
  }

  void resetGenres() => ref.read(genreChoiceProvider.notifier).set(null);

  void clearGenres() => ref.read(genreChoiceProvider.notifier).set(const []);

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

final musicMapProvider = FutureProvider((ref) async {
  await ref.watch(libraryTracksProvider.future);
  final library = await ref.watch(libraryRepositoryProvider.future);
  return library.loadMusicMap();
});

// ties go alphabetically so the order doesn't shift between runs
final genreCountsProvider = Provider((ref) {
  final counts = <String, int>{};
  for (final track in ref.watch(tracksProvider)) {
    for (final genre in track.genres.toSet()) {
      counts[genre] = (counts[genre] ?? 0) + 1;
    }
  }
  final genres = counts.keys.toList()
    ..sort((a, b) {
      final byCount = counts[b]!.compareTo(counts[a]!);
      if (byCount != 0) return byCount;
      return a.compareTo(b);
    });
  return {for (final genre in genres) genre: counts[genre]!};
});

// a genre keeps its slot, and so its color, when another is unchecked
final comparedGenresProvider = Provider((ref) {
  final chosen = ref.watch(genreChoiceProvider);
  if (chosen != null) return chosen;

  final biggest = ref.watch(genreCountsProvider).keys.take(defaultGenreCount);
  return <String?>[...biggest];
});

final matchScoresProvider = Provider.autoDispose((ref) {
  final results = ref.watch(searchResultsProvider).value ?? const [];
  final scores = DiscoverViewModel._rescale([
    for (final result in results) result.score,
  ]);
  return {
    for (var idx = 0; idx < results.length; idx++)
      results[idx].track.id: scores[idx],
  };
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
