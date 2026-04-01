import 'dart:async';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VersionGate {
  /// Проверяется при КАЖДОМ запуске
  static Future<bool> mustUpdate() async {
    try {
      final supabase = Supabase.instance.client;

      final config = await supabase
          .from('app_config')
          .select('value')
          .eq('key', 'min_version')
          .single();

      final minVersion = (config['value'] as String?)?.trim();

      if (minVersion == null || minVersion.isEmpty) {
        return false;
      }

      final current = await _getCurrentVersion();

      return _isLower(current, minVersion);
    } catch (e) {
      // ❗ ВАЖНО:
      // если хочешь ЖЕСТКИЙ режим — верни true
      // если хочешь мягкий — false

      return false;
    }
  }

  /// текущая версия приложения
  static Future<String> _getCurrentVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }

  /// сравнение версий
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
