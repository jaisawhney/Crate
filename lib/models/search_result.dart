import '../data/services/database/track.dart';

class SearchResult {
  final Track track;
  final Duration start;
  final double score;

  const SearchResult(this.track, this.start, this.score);
}
