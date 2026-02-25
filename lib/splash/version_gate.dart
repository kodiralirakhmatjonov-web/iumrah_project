import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VersionGate {
  /// Вызывается из Splash / AppBootstrap
  /// Offline-first: если сети нет — НЕ блокируем запуск (return false).
  static Future<bool> mustUpdate() async {
    final prefs = await SharedPreferences.getInstance();

    final cachedVersion = prefs.getString('cached_min_version');
    final lastCheck = prefs.getInt('version_check_time') ?? 0;

    final now = DateTime.now().millisecondsSinceEpoch;

    // 7 дней
    const weekMs = 604800000;

    // Если кеш есть и неделя не прошла — сравниваем локально, без сети
    if (cachedVersion != null && (now - lastCheck) < weekMs) {
      final current = await _getCurrentVersion();
      return _isLower(current, cachedVersion);
    }

    // Иначе пытаемся сходить в Supabase, но:
    // - с таймаутом
    // - с fallback на cachedVersion
    try {
      final supabase = Supabase.instance.client;

      final config = await supabase
          .from('app_config')
          .select('value')
          .eq('key', 'min_version')
          .single()
          .timeout(const Duration(seconds: 2));

      final minVersion = (config['value'] as String?)?.trim();

      // Если с сервера пришла пустота — fallback
      if (minVersion == null || minVersion.isEmpty) {
        if (cachedVersion != null) {
          final current = await _getCurrentVersion();
          return _isLower(current, cachedVersion);
        }
        return false; // сети/валидной версии нет — запуск разрешаем
      }

      // сохраняем локально
      await prefs.setString('cached_min_version', minVersion);
      await prefs.setInt('version_check_time', now);

      final current = await _getCurrentVersion();
      return _isLower(current, minVersion);
    } on TimeoutException {
      // оффлайн/долгая сеть → НЕ блокируем
      if (cachedVersion != null) {
        final current = await _getCurrentVersion();
        return _isLower(current, cachedVersion);
      }
      return false;
    } catch (_) {
      // любая ошибка → НЕ блокируем
      if (cachedVersion != null) {
        final current = await _getCurrentVersion();
        return _isLower(current, cachedVersion);
      }
      return false;
    }
  }

  /// текущая версия приложения
  static Future<String> _getCurrentVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }

  /// сравнение версий: true если current < min
  static bool _isLower(String current, String min) {
    final c = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final m = min.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    final maxLen = (c.length > m.length) ? c.length : m.length;
    for (int i = 0; i < maxLen; i++) {
      final ci = (i < c.length) ? c[i] : 0;
      final mi = (i < m.length) ? m[i] : 0;
      if (ci < mi) return true;
      if (ci > mi) return false;
    }
    return false;
  }
}
