import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/bootstrap/app_bootstrap.dart';
import 'core/navigation/premium_route.dart';
import 'auth/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://coaqrsapnpyutsxflsru.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNvYXFyc2FwbnB5dXRzeGZsc3J1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNjE2OTcsImV4cCI6MjA3OTkzNzY5N30.iycnHay3nX__40VTKzvkyX3NKbSo8wWqBhKGKGl2yIo',
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  final bool ready = await AppBootstrap.init();
  runApp(MyApp(isReady: ready));
}

class MyApp extends StatelessWidget {
  final bool isReady;
  const MyApp({super.key, required this.isReady});

  static const _langKey = 'app_language';

  bool _isRtlLang(String? lang) {
    // если у тебя арабский хранится как 'ar' — этого достаточно
    return lang != null && lang.toLowerCase().startsWith('ar');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snap) {
        final prefs = snap.data;
        final lang = prefs
            ?.getString(_langKey); // язык, который ты сохраняешь в AppBootstrap
        final isRtl = _isRtlLang(lang);

        return MaterialApp(
          debugShowCheckedModeBanner: false,

          // ✅ важно для RTL: делегаты
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          // ✅ добавь сюда свои языки (минимум ar чтобы RTL работал корректно)
          supportedLocales: const [
            Locale('en'),
            Locale('ru'),
            Locale('ar'),
            // Locale('uz'), Locale('tr'), ...
          ],

          // ✅ ключевое: глобально задаём направление
          builder: (context, child) {
            return Directionality(
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              child: child ?? const SizedBox.shrink(),
            );
          },

          // твоя текущая логика навигации не трогаю
          onGenerateRoute: (settings) {
            return PremiumRoute.push(const AuthGate());
          },
        );
      },
    );
  }
}
