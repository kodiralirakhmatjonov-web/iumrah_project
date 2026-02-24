import 'package:iumrah_project/splash/version_gate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../localization/translations_service.dart';
import '../localization/translations_store.dart';
import '../localization/audio_cache_service.dart';

class AppBootstrap {
  static const String _langKey = 'app_language';

  // Текущий язык приложения
  static String? currentLang;

  /// Инициализация приложения
  /// 1) Проверяем выбран ли язык
  /// 2) Загружаем переводы (кэш → сервер)
  /// 3) Загружаем аудио ссылки
  static Future<bool> init() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('app_language');

    if (lang == null || lang.isEmpty) {
      return false;
    }

    try {
      // 1️⃣ ЗАГРУЗКА ПЕРЕВОДОВ (ОБЯЗАТЕЛЬНО)
      final translationsLoaded = await TranslationsService.load(lang);
      if (!translationsLoaded) return false;

      // 3️⃣ ОФФЛАЙН АУДИО КЕШ
      await AudioCacheService.loadAndCacheAudio(lang);

      return TranslationsStore.isReady;
    } catch (e) {
      return false;
    }
  }

  /// Установка языка вручную
  /// Используется после выбора языка
  static Future<void> setLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, lang);

    currentLang = lang;

    // Переводы
    await TranslationsService.load(lang);

    // Аудио
    await AudioCacheService.loadAndCacheAudio(lang);
  }
}
