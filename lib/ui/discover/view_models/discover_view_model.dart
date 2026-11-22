import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/dependencies.dart';
import '../../../domain/library_notifier.dart';
import '../../../models/search_result.dart';

final queryProvider = NotifierProvider(() => _Value(''));

final discoverViewModelProvider = NotifierProvider(DiscoverViewModel.new);

class DiscoverViewModel extends Notifier<void> {
  @override
  void build() {}

  void search(String query) {
    ref.read(queryProvider.notifier).set(query.trim());
  }
}

final queryEmbeddingProvider = FutureProvider.autoDispose((ref) async {
  final query = ref.watch(queryProvider);
  if (query.isEmpty) return null;

  final library = await ref.watch(libraryRepositoryProvider.future);
  return library.embedQuery(query);
});

final searchResultsProvider = FutureProvider.autoDispose((ref) async {
  final embedding = await ref.watch(queryEmbeddingProvider.future);
  await ref.watch(libraryTracksProvider.future);
  final library = await ref.watch(libraryRepositoryProvider.future);

  if (embedding == null) return const <SearchResult>[];
  return library.searchText(embedding);
});

class _Value<T> extends Notifier<T> {
  final T _initial;

  _Value(this._initial);

  @override
  T build() => _initial;

  void set(T value) => state = value;
}
