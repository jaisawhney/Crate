import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'library_folder.dart';
import 'moment.dart';
import 'objectbox.g.dart';
import 'track.dart';

class LibraryDatabaseService {
  final Box<Track> _tracks;
  final Box<Moment> _moments;
  final Box<LibraryFolder> _folders;

  LibraryDatabaseService(Store store)
    : _tracks = store.box<Track>(),
      _moments = store.box<Moment>(),
      _folders = store.box<LibraryFolder>();

  static Future<LibraryDatabaseService> open() async {
    final support = await getApplicationSupportDirectory();
    return LibraryDatabaseService(
      await openStore(directory: p.join(support.path, 'library')),
    );
  }

  List<Track> loadTracks() => _tracks.getAll();

  List<Track> loadTracksWithoutEmbedding() =>
      _find(_tracks.query(Track_.embedding.isNull()));

  List<Track> loadTracksWithEmbedding() =>
      _find(_tracks.query(Track_.embedding.notNull()));

  void saveTrack(Track track) => _tracks.put(track);

  void saveTracks(List<Track> tracks) => _tracks.putMany(tracks);

  void removeTracks(List<int> ids) => _tracks.removeMany(ids);

  List<Track?> loadTracksById(List<int> ids) => _tracks.getMany(ids);

  List<Moment> loadMoments(int trackId) => _find(
    _moments.query(Moment_.trackId.equals(trackId)).order(Moment_.startSeconds),
  );

  List<ObjectWithScore<Moment>> searchMoments(
    List<double> embedding,
    int count,
  ) {
    final query = _moments
        .query(Moment_.embedding.nearestNeighborsF32(embedding, count))
        .build();
    final results = query.findWithScores();
    query.close();
    return results;
  }

  void saveMoments(List<Moment> moments) => _moments.putMany(moments);

  void removeMoments(List<int> trackIds) {
    final query = _moments.query(Moment_.trackId.oneOf(trackIds)).build();
    query.remove();
    query.close();
  }

  List<LibraryFolder> loadFolders() => _folders.getAll();

  void saveFolder(LibraryFolder folder) => _folders.put(folder);

  void removeFolder(int id) => _folders.remove(id);

  static List<T> _find<T>(QueryBuilder<T> builder) {
    final query = builder.build();
    final results = query.find();
    query.close();
    return results;
  }
}
