import 'package:objectbox/objectbox.dart';

@Entity()
class Moment {
  @Id()
  int id;

  @Index()
  int trackId;

  int startSeconds;

  @Property(type: PropertyType.floatVector)
  List<double> embedding;

  Moment({
    this.id = 0,
    required this.trackId,
    required this.startSeconds,
    required this.embedding,
  });
}
