import 'package:objectbox/objectbox.dart';

@Entity()
class Track {
  @Id()
  int id;

  String path;
  int size;

  @Property(type: PropertyType.date)
  DateTime modified;

  String title;
  String? artist;
  String? album;
  int? durationMilliseconds;
  List<String> genres;

  @Property(type: PropertyType.floatVector)
  List<double>? embedding;

  Track({
    this.id = 0,
    required this.path,
    required this.size,
    required this.modified,
    required this.title,
    this.artist,
    this.album,
    this.durationMilliseconds,
    this.genres = const [],
  });

  Duration? get duration {
    final milliseconds = durationMilliseconds;
    if (milliseconds == null) return null;
    return Duration(milliseconds: milliseconds);
  }
}
