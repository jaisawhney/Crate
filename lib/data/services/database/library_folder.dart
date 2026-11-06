import 'package:objectbox/objectbox.dart';

@Entity()
class LibraryFolder {
  @Id()
  int id;

  @Unique(onConflict: ConflictStrategy.replace)
  String path;

  LibraryFolder({this.id = 0, required this.path});
}
