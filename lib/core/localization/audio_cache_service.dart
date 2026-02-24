import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AudioCacheService {
  static const _table = 'audio';
  static const _pfx = 'audio_';

  static String _ready(String lang) => 'audio_ready_$lang';

  /// ОСТАЛОСЬ КАК БЫЛО
  static Future<void> loadAndCacheAudio(String lang) async {
    final prefs = await SharedPreferences.getInstance();

    final data = await Supabase.instance.client
        .from('audio')
        .select('key, url')
        .eq('lang', lang);

    final dir = await getApplicationDocumentsDirectory();

    final client = HttpClient();

    for (final item in data) {
      final key = item['key'];
      final url = item['url'];

      final fileName = '${key}_$lang.mp3';
      final filePath = '${dir.path}/$fileName';
      final file = File(filePath);

      final prefKey = 'audio_${key}_$lang';

      // ✅ ПРОВЕРКА: если файл уже есть — НЕ качаем
      if (await file.exists()) {
        prefs.setString(prefKey, file.path);
        continue;
      }

      try {
        final request = await client.getUrl(Uri.parse(url));
        final response = await request.close();
        final bytes = await consolidateHttpClientResponseBytes(response);
        await file.writeAsBytes(bytes);

        prefs.setString(prefKey, file.path);
      } catch (_) {}
    }
  }
}
