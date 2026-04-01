import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/bootstrap/app_bootstrap.dart';
import 'core/navigation/premium_route.dart';
import 'auth/auth_gate.dart';
import 'package:iumrah_project/deep_link_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  await Supabase.initialize(
    url: 'https://coaqrsapnpyutsxflsru.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNvYXFyc2FwbnB5dXRzeGZsc3J1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNjE2OTcsImV4cCI6MjA3OTkzNzY5N30.iycnHay3nX__40VTKzvkyX3NKbSo8wWqBhKGKGl2yIo',
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  final bool ready = await AppBootstrap.init();

  /// 🔥 ВАЖНО: запускаем deeplink listener
  await DeepLinkHandler.instance.start();

  runApp(MyApp(isReady: ready));
}

class MyApp extends StatelessWidget {
  final bool isReady;
  const MyApp({super.key, required this.isReady});

  static const _langKey = 'app_language';

  bool _isRtlLang(String? lang) {
    return lang != null && lang.toLowerCase().startsWith('ar');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snap) {
        final prefs = snap.data;
        final lang = prefs?.getString(_langKey);
        final isRtl = _isRtlLang(lang);

        return MaterialApp(
          debugShowCheckedModeBanner: false,

          /// 🔥 ВАЖНО: подключаем navigatorKey для deeplink
          navigatorKey: navigatorKey,

          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          supportedLocales: const [
            Locale('en'),
            Locale('ru'),
            Locale('ar'),
          ],

          builder: (context, child) {
            return Directionality(
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              child: child ?? const SizedBox.shrink(),
            );
          },

          onGenerateRoute: (settings) {
            return PremiumRoute.push(const AuthGate());
          },
        );
      },
    );
  }
}
