// TODO Implement this library.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// ГЛОБАЛЬНЫЙ navigatorKey (обязательно подключить в MaterialApp)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class DeepLinkHandler {
  DeepLinkHandler._();
  static final DeepLinkHandler instance = DeepLinkHandler._();

  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _sub;
  bool _started = false;

  /// ВЫЗВАТЬ 1 РАЗ при старте приложения
  Future<void> start() async {
    if (_started) return;
    _started = true;

    _appLinks = AppLinks();

    /// если приложение открыли через ссылку (холодный старт)
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      await _handleUri(initialUri);
    }

    /// если приложение уже открыто
    _sub = _appLinks.uriLinkStream.listen((uri) async {
      await _handleUri(uri);
    });
  }

  Future<void> dispose() async {
    await _sub?.cancel();
  }

  Future<void> _handleUri(Uri uri) async {
    print('DEEPLINK: $uri');

    /// фильтруем только наш deeplink
    if (uri.scheme != 'iumrah') return;
    if (uri.host != 'auth') return;

    try {
      /// даем время Supabase обработать токен
      await Future.delayed(const Duration(milliseconds: 600));

      await Supabase.instance.client.auth.refreshSession();

      final user = Supabase.instance.client.auth.currentUser;

      final isVerified = user?.emailConfirmedAt != null;

      if (isVerified) {
        _goToOnboarding();
      } else {
        _goToVerification();
      }
    } catch (e) {
      print('DeepLink error: $e');
    }
  }

  void _goToOnboarding() {
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/onboarding',
      (route) => false,
    );
  }

  void _goToVerification() {
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/email-verification',
      (route) => false,
    );
  }
}
