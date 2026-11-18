String formatDuration(Duration duration) {
  final seconds = duration.inSeconds % 60;
  return '${duration.inMinutes}:${seconds.toString().padLeft(2, '0')}';
}

String formatHours(Duration duration) {
  final minutes = duration.inMinutes % 60;
  if (duration.inHours == 0) return '$minutes min';
  return '${duration.inHours} h $minutes min';
}

String byline(String? artist, List<String> genres) {
  final name = artist ?? 'Unknown artist';
  final genre = genres.firstOrNull;
  if (genre == null) return name;
  return '$name · $genre';
}
