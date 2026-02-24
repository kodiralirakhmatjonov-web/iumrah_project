import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';

class VersionGate {
  /// 👉 вызывается из Splash / AppBootstrap
  static Future<bool> mustUpdate() async {
    final prefs = await SharedPreferences.getInstance();

    final cachedVersion = prefs.getString('cached_min_version');
    final lastCheck = prefs.getInt('version_check_time') ?? 0;

    final now = DateTime.now().millisecondsSinceEpoch;

    // 7 дней
    const weekMs = 604800000;

    /// если версия есть и неделя не прошла
    if (cachedVersion != null && (now - lastCheck) < weekMs) {
      final current = await _getCurrentVersion();
      return _isLower(current, cachedVersion);
    }

    /// иначе идем в Supabase
    final supabase = Supabase.instance.client;

    final config = await supabase
        .from('app_config')
        .select('value')
        .eq('key', 'min_version')
        .single();

    final minVersion = config['value'];

    /// сохраняем локально
    await prefs.setString('cached_min_version', minVersion);
    await prefs.setInt('version_check_time', now);

    final current = await _getCurrentVersion();

    return _isLower(current, minVersion);
  }

  /// текущая версия приложения
  static Future<String> _getCurrentVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }

  /// сравнение версий
  static bool _isLower(String current, String min) {
    final c = current.split('.').map(int.parse).toList();
    final m = min.split('.').map(int.parse).toList();

    for (int i = 0; i < m.length; i++) {
      if (i >= c.length) return true;
      if (c[i] < m[i]) return true;
      if (c[i] > m[i]) return false;
    }

    return false;
  }
}
