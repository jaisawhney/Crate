import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/dependencies.dart';

final libraryReadyProvider = FutureProvider((ref) async {
  await ref.watch(sonicEmbedProvider.future);
});

final downloadProgressProvider = Provider(
  (ref) => ref.watch(modelDownloadProgressProvider).value,
);

final shellViewModelProvider = NotifierProvider(ShellViewModel.new);

class ShellViewModel extends Notifier<void> {
  @override
  void build() {}

  void retry() => ref.invalidate(sonicEmbedProvider);
}
