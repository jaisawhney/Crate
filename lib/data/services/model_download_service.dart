import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../models/model_download_progress.dart';

class ModelDownloadService {
  static const _host = 'https://pub-4e1450c6144c44568e5ad90af9642577.r2.dev';
  static const _path = 'v1/sonicembed_int8.litertlm';
  static const _sha256 =
      '39c2b93b07ce2b9dd1dee2f8d51137d679b926e7bc56996b2837943324ff9481';

  final _dio = Dio();
  final _progress = StreamController<ModelDownloadProgress>.broadcast();

  Stream<ModelDownloadProgress> watchProgress() => _progress.stream;

  Future<File> download() async {
    final support = await getApplicationSupportDirectory();
    final bundle = File(p.join(support.path, 'models', p.basename(_path)));
    if (await bundle.exists()) return bundle;

    final partial = File('${bundle.path}.part');
    await partial.parent.create(recursive: true);
    var start = 0;
    if (await partial.exists()) start = await partial.length();

    try {
      await _dio.download(
        '$_host/$_path',
        partial.path,
        deleteOnError: false,
        fileAccessMode: FileAccessMode.append,
        options: Options(headers: {HttpHeaders.rangeHeader: 'bytes=$start-'}),
        onReceiveProgress: (received, total) => _progress.add(
          ModelDownloadProgress(start + received, start + total),
        ),
      );
    } on DioException catch (error) {
      // a partial file that's already whole has no bytes left to send
      final status = error.response?.statusCode;
      if (status != HttpStatus.requestedRangeNotSatisfiable) rethrow;
    }

    if (await _checksum(partial.path) != _sha256) {
      await partial.delete();
      throw FileSystemException(
        'SonicEmbed download does not match its checksum',
        bundle.path,
      );
    }
    await partial.rename(bundle.path);
    return bundle;
  }

  // hashing hundreds of MB would stall the UI isolate
  static Future<String> _checksum(String path) => Isolate.run(() async {
    final digest = await sha256.bind(File(path).openRead()).first;
    return digest.toString();
  });
}
