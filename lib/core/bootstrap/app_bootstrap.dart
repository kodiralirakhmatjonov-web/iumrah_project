import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

// если у тебя эти импорты уже есть — оставь свои пути как в проекте
import 'package:iumrah_project/core/localization/translations_service.dart';
import 'package:iumrah_project/core/localization/translations_store.dart';
import 'package:iumrah_project/core/localization/audio_cache_service.dart';

class AppBootstrap {
  static const String _langKey = 'app_language';
  static String currentLang = 'en';

  /// Offline-first init:
  /// - Никогда не блокируем запуск из-за сети
  /// - Переводы и аудио запускаем мягко (timeout / background)
  static Future<bool> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lang = prefs.getString(_langKey) ?? currentLang;
      currentLang = lang;

      // 1) Переводы: пробуем загрузить, но НЕ БЛОКИРУЕМ старт
      // Если сеть есть — ок. Если нет — просто продолжаем.
      try {
        await TranslationsService.load(lang)
            .timeout(const Duration(seconds: 2), onTimeout: () => false);
      } catch (_) {
        // offline / ошибка — игнорируем, app должен стартовать
      }

      // 2) Аудио кеш: НИКОГДА не должен блокировать старт.
      // Запускаем в фоне. Даже если упадёт — не важно для запуска.
      unawaited(_safeWarmupAudio(lang));

      // 3) Старта достаточно. Если переводы не готовы — UI всё равно должен жить.
      // (Тексты могут быть дефолтными/плейсхолдерами, пока нет сети/кеша.)
      return true;
    } catch (_) {
      // Даже если что-то совсем пошло не так — оффлайн старт разрешаем.
      return true;
    }
  }

  static Future<void> _safeWarmupAudio(String lang) async {
    try {
      await AudioCacheService.loadAndCacheAudio(lang)
          .timeout(const Duration(seconds: 2));
    } catch (_) {
      // игнорируем
    }
  }

  /// Установка языка вручную
  /// Важно: тоже не блокируем UI из-за сети/аудио
  static Future<void> setLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, lang);

    currentLang = lang;

    // Переводы — пытаемся, но не держим пользователя
    unawaited(_safeLoadTranslations(lang));

    // Аудио — фоном
    unawaited(_safeWarmupAudio(lang));
  }

  static Future<void> _safeLoadTranslations(String lang) async {
    try {
      await TranslationsService.load(lang)
          .timeout(const Duration(seconds: 2), onTimeout: () => false);
    } catch (_) {
      // игнорируем
    }
  }
}
