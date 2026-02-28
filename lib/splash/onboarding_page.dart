import 'package:flutter/material.dart';
import 'package:iumrah_project/core/bootstrap/app_bootstrap.dart';
import 'package:iumrah_project/core/localization/audio_cache_service.dart';
import 'package:iumrah_project/core/localization/premium_service.dart';
import 'package:iumrah_project/core/localization/translations_store.dart';
import 'package:iumrah_project/core/navigation/premium_route.dart';
import 'package:iumrah_project/splash/onboarding1_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final AnimationController _textController;
  late final AnimationController _buttonController;

  late final Animation<double> _logoOpacity;
  late final Animation<double> _textOpacity;
  late final Animation<double> _buttonOpacity;

  bool _isReady = false;
  bool _isLoading = true;

  String t(String key) => TranslationsStore.get(key);

  @override
  void initState() {
    super.initState();

    _initAnimations();
    _startSequence(); // ✅ анимации стартуют сразу

    _initApp(); // ✅ данные грузим параллельно, кнопка пока disabled
  }

  void _initAnimations() {
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _logoOpacity =
        CurvedAnimation(parent: _logoController, curve: Curves.easeInOut);

    _textOpacity =
        CurvedAnimation(parent: _textController, curve: Curves.easeInOut);

    _buttonOpacity =
        CurvedAnimation(parent: _buttonController, curve: Curves.easeIn);
  }

  Future<void> _startSequence() async {
    // 2 секунды логотип
    await _logoController.forward();

    // пауза 1 секунда
    await Future.delayed(const Duration(seconds: 1));

    // 3 секунды текст
    await _textController.forward();

    // пауза 2 секунды
    await Future.delayed(const Duration(seconds: 2));

    // появляется кнопка (но может быть disabled пока не ready)
    if (!mounted) return;
    _buttonController.forward();
  }

  Future<void> _initApp() async {
    try {
      final ok = await AppBootstrap.init();

      if (ok) {
        final lang = AppBootstrap.currentLang;
        if (lang.isNotEmpty) {
          await Future.wait([
            // ⚠️ эти методы могут фейлиться без интернета — это ок, но не должно ломать UI
            AudioCacheService.loadAndCacheAudio(lang).catchError((_) {}),
            PremiumService.syncPremiumStatus().catchError((_) {}),
          ]);
        }

        if (!mounted) return;
        setState(() {
          _isReady = true;
          _isLoading = false;
        });
        return;
      }

      // Если init() вернул false — значит язык/кэш не готов.
      // UI не должен зависать: просто оставляем кнопку disabled.
      if (!mounted) return;
      setState(() {
        _isReady = false;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isReady = false;
        _isLoading = false;
      });
    }
  }

  void _goNext() {
    if (!_isReady) return;
    Navigator.of(context).pushReplacement(
      PremiumRoute.push(const Onbording1Page()),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ===== BACKGROUND IMAGE =====
          Positioned.fill(
            child: Image.asset(
              'assets/images/onbording.png',
              fit: BoxFit.cover,
            ),
          ),

          // ===== DARK GRADIENT =====
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black87,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Spacer(),

                  // ===== LOGO =====
                  FadeTransition(
                    opacity: _logoOpacity,
                    child: Image.asset(
                      'assets/icons/app_icon.png',
                      height: 170,
                      fit: BoxFit.contain,
                    ),
                  ),

                  const Spacer(),

                  // ===== TITLE + SUB =====
                  FadeTransition(
                    opacity: _textOpacity,
                    child: Column(
                      children: [
                        Text(
                          t('onbording_title'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Lato',
                            fontWeight: FontWeight.w800,
                            fontSize: 36,
                            height: 1.3,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          t('onbording_sub'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Lato',
                            fontSize: 20,
                            height: 1.2,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // ===== BUTTON =====
                  FadeTransition(
                    opacity: _buttonOpacity,
                    child: SizedBox(
                      height: 60,
                      width: double.infinity,
                      child: Material(
                        color: _isReady
                            ? Colors.white
                            : Colors.white.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(50),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(50),
                          onTap: _isReady ? _goNext : null,
                          child: Center(
                            child: _isReady
                                ? Text(
                                    t('continue_btn'),
                                    style: const TextStyle(
                                      fontFamily: 'Lato',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18,
                                      color: Colors.black,
                                    ),
                                  )
                                : (_isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.black,
                                        ),
                                      )
                                    : Text(
                                        t('continue_btn'),
                                        style: TextStyle(
                                          fontFamily: 'Lato',
                                          fontWeight: FontWeight.w700,
                                          fontSize: 18,
                                          color: Colors.black.withOpacity(0.4),
                                        ),
                                      )),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
