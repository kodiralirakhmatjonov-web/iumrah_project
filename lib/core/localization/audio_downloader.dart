import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class AudioDownloader {
  static final Dio _dio = Dio();

  static Future<void> downloadPack({
    required String lang,
    required Function(double) onProgress,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final audioDir = Directory('${dir.path}/audio/$lang');

    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }

    // 🔥 Твои ключи
    final audioKeys = [
      'pray',
      'zam_zam',
      'safa_go',
      'safa_dua',
    ];

    int completed = 0;

    for (final key in audioKeys) {
      final file = File('${audioDir.path}/$key.mp3');

      if (await file.exists()) {
        completed++;
        onProgress(completed / audioKeys.length);
        continue;
      }

      final url =
          'https://coaqrsapnpyutsxflsru.supabase.co/storage/v1/object/public/audio/$lang/$key.mp3';

      await _dio.download(
        url,
        file.path,
        onReceiveProgress: (rec, total) {
          final fileProgress = total != 0 ? rec / total : 0;

          final global = (completed + fileProgress) / audioKeys.length;

          onProgress(global);
        },
      );

      completed++;
      onProgress(completed / audioKeys.length);
    }
  }
}
