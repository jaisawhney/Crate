class ModelDownloadProgress {
  static const _megabyte = 1024 * 1024;

  final int received;
  final int total;

  const ModelDownloadProgress(this.received, this.total);

  String get label =>
      'Downloading SonicEmbed · ${received ~/ _megabyte} of ${total ~/ _megabyte} MB';

  double get fraction => received / total;
}
