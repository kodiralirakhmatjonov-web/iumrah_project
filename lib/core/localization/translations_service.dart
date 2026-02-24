import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'translations_store.dart';

class TranslationsService {
  static const _cachePrefix = 'cached_translations_';

  /// Универсальная загрузка:
  /// 1) Пробуем кэш конкретного языка
  /// 2) Если нет — грузим с сервера
  static Future<bool> load(String lang) async {
    final hasCache = await loadFromCache(lang);
    if (hasCache) return true;

    try {
      await loadFromServer(lang);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Загрузка с сервера (при первом запуске)
  static Future<void> loadFromServer(String lang) async {
    final supabase = Supabase.instance.client;
    final prefs = await SharedPreferences.getInstance();

    final response = await supabase
        .from('translations')
        .select('key, value')
        .eq('lang', lang);

    final Map<String, String> map = {};

    for (final item in response) {
      map[item['key']] = item['value'];
    }

    // В память
    TranslationsStore.setAll(map);

    // В кэш по языку
    await prefs.setString(
      '$_cachePrefix$lang',
      jsonEncode(map),
    );
  }

  /// Загрузка из кэша по языку
  static Future<bool> loadFromCache(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('$_cachePrefix$lang');

    if (cached == null) return false;

    try {
      final Map<String, dynamic> decoded = jsonDecode(cached);
      final Map<String, String> map =
          decoded.map((k, v) => MapEntry(k, v.toString()));

      TranslationsStore.setAll(map);
      return true;
    } catch (_) {
      return false;
    }
  }
}
