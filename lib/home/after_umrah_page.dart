import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iumrah_project/home/certificate_page.dart';
import 'package:iumrah_project/home/profile_page.dart';
import 'package:iumrah_project/home/umrah_start.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/navigation/premium_route.dart';
import '../../core/localization/translations_store.dart';
import 'package:iumrah_project/core/ui/app_ui.dart'; // AppUI + PremiumTap
import 'package:iumrah_project/home/widgets/floating_nav_bar.dart';

//import 'package:iumrah_project/home/green_wave.dart';

class AfterUmrahPage extends StatefulWidget {
  const AfterUmrahPage({super.key});

  @override
  State<AfterUmrahPage> createState() => _AfterUmrahPageState();
}

class _AfterUmrahPageState extends State<AfterUmrahPage>
    with TickerProviderStateMixin {
  // UI
  late final AnimationController _glowCtrl;
  late final Animation<double> _glowOpacity;
  static const Duration _fadeDur = Duration(seconds: 3);
  static const Duration _holdDur = Duration(seconds: 12);

  bool _textVisible = true;

  // Text cycling
  int _phase = 0; // 0 -> with name + welcome, 1 -> title3, 2 -> title2
  Timer? _cycleTimer;

  // Profile cache
  String _name = '';
  bool _loadingName = true;

  // keys
  static const _prefsNameKey = 'profile_name_cache';

  Null get style => null;

  String _langFromPrefsOrDefault(SharedPreferences prefs) {
    final v = prefs.getString('app_language');
    if (v == null || v.isEmpty) return 'en';
    return v;
  }

  // translation getter (Store-first)
  String t(String key) => TranslationsStore.get(key);

  @override
  void initState() {
    super.initState();

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _glowOpacity =
        CurvedAnimation(parent: _glowCtrl, curve: Curves.easeOutCubic);

    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // glow
    _glowCtrl.forward();

    // start cycling (always, even если имя ещё грузится)
    _startCycle();

    // load name cached -> else fetch once -> cache
    await _loadNameOnce();
  }

  void _startCycle() {
    _cycleTimer?.cancel();
    _cycleTimer = Timer.periodic(_holdDur, (_) {
      final next = (_phase + 1) % 3;
      _switchPhase(next);
    });
  }

  void _showComingSoon() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        content: Text(
          t('cooming_text'),
          textAlign: TextAlign.start,
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Future<void> _switchPhase(int next) async {
    if (!mounted) return;

    // 1) сперва прячем текущий текст
    setState(() => _textVisible = false);

    // ждём пока он полностью исчезнет (1 сек)
    await Future.delayed(_fadeDur);
    if (!mounted) return;

    // 2) меняем фазу и показываем новый текст
    setState(() {
      _phase = next;
      _textVisible = true;
    });
  }

  Future<void> _loadNameOnce() async {
    final prefs = await SharedPreferences.getInstance();

    final cached = prefs.getString(_prefsNameKey);
    if (cached != null && cached.trim().isNotEmpty) {
      if (!mounted) return;
      setState(() {
        _name = cached.trim();
        _loadingName = false;
      });
      return;
    }

    // one request максимум (и только если есть user)
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() => _loadingName = false);
      return;
    }

    try {
      final row = await Supabase.instance.client
          .from('profiles')
          .select('name')
          .eq('user_id', user.id)
          .maybeSingle();

      final fetched = (row?['name'] ?? '').toString().trim();
      if (fetched.isNotEmpty) {
        await prefs.setString(_prefsNameKey, fetched);
      }

      if (!mounted) return;
      setState(() {
        _name = fetched;
        _loadingName = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingName = false);
    }
  }

  @override
  void dispose() {
    _cycleTimer?.cancel();
    _glowCtrl.dispose();
    super.dispose();
  }

  // Telegram-like color (stable)
  Color _avatarColorFor(String seed) {
    if (seed.isEmpty) return const Color(0xFF14B8A6);
    int h = 0;
    for (final c in seed.codeUnits) {
      h = 31 * h + c;
    }
    final rnd = Random(h);
    // мягкие “премиум” тона
    final colors = <Color>[
      const Color(0xFF14B8A6),
      const Color(0xFF3B82F6),
      const Color(0xFF8B5CF6),
      const Color(0xFFF59E0B),
      const Color(0xFF22C55E),
      const Color(0xFFEC4899),
    ];
    return colors[rnd.nextInt(colors.length)];
  }

  String _initialLetter() {
    final s = _name.trim();
    if (s.isEmpty) return 'A';
    return s.characters.first.toUpperCase();
  }

  Widget _animatedHeadline() {
    // phase mapping:
    // 0: name + home_title
    // 1: home_title3 + home_title3_sub
    // 2: home_title2 + home_title2_sub
    Widget child;

    if (!_textVisible) {
      child = const SizedBox(key: ValueKey('empty'));
    } else if (_phase == 0) {
      child = Column(
        key: const ValueKey('phase0'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            t('home2_3title'),
            textAlign: TextAlign.center,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            softWrap: true,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            t('home2_3_subtitle'),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            softWrap: true,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.25,
            ),
          ),
        ],
      );
    } else if (_phase == 1) {
      child = Column(
        key: const ValueKey('phase1'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            t('home2_title2'),
            textAlign: TextAlign.center,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            softWrap: true,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            t('home2_title2_sub'),
            textAlign: TextAlign.center,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            softWrap: true,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.25,
            ),
          ),
        ],
      );
    } else {
      child = Column(
        key: const ValueKey('phase2'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            t('home2_title3'),
            textAlign: TextAlign.center,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            softWrap: true,
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            t('home2_title3_sub'),
            textAlign: TextAlign.center,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            softWrap: true,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.25,
            ),
          ),
        ],
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(seconds: 1),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (w, anim) {
        final fade = FadeTransition(opacity: anim, child: w);
        final slide = SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.02),
            end: Offset.zero,
          ).animate(anim),
          child: fade,
        );
        return slide;
      },
      child: child,
    );
  }

  Widget _premiumCard({
    required VoidCallback onTap,
    required Widget child,
  }) {
    // PremiumTap из твоего app_ui.dart (scale+opacity)
    return PremiumTap(
      onTap: onTap,
      child: child,
    );
  }

  void _go(Widget page) {
    Navigator.of(context).push(PremiumRoute.push(page));
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
    return Scaffold(
      backgroundColor: const Color(0xFF131313), // основной фон из Figma
      body: Stack(
        children: [
          // ЗОЛОТОЙ СВЕТ
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.0, -0.4), // чуть выше центра
                  radius: 0.6,
                  colors: [
                    Color(0xFF07E2FF), // центр
                    Color(0x0007E2FF), // прозрачный край
                  ],
                  stops: [0.0, 1.0],
                ),
              ),
            ),
          ),

          // ТВОЙ КОНТЕНТ
          SafeArea(
            child: Column(
              children: const [
                // сюда твой UI
              ],
            ),
          ),

          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 25),

                  // top row: logo + avatar
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset(
                        'assets/images/iumrah_logo1.png',
                        height: 85,
                      ),
                      const Spacer(),
                      PremiumTap(
                        onTap: () {
                          Navigator.of(context).push(
                            PremiumRoute.push(
                              const ProfilePage(),
                            ),
                          );
                        },
                        child: Container(
                          width: 56,
                          height: 80, // ← делаем квадрат, 90 не нужно
                          decoration: BoxDecoration(
                            color: _avatarColorFor(_name.isEmpty ? 'A' : _name),
                            shape: BoxShape.circle,
                          ),
                          alignment: AlignmentDirectional.center,
                          child: Text(
                            _initialLetter(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 34),

                  // headline block (animated)
                  _animatedHeadline(),

                  const Spacer(),

                  // Cards column
                  Column(
                    children: [
                      // Blue premium card
                      PremiumTap(
                        onTap: _showComingSoon,
                        child: Container(
                          height: 110,
                          width: double.infinity,
                          padding: const EdgeInsetsDirectional.fromSTEB(
                              22, 18, 18, 18),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(40),
                            gradient: const LinearGradient(
                              begin: AlignmentDirectional.centerStart,
                              end: AlignmentDirectional.centerEnd,
                              colors: [
                                Color(0xFF006593),
                                Color(0xFF01C1C5),
                              ],
                            ),
                            boxShadow: const [
                              BoxShadow(
                                blurRadius: 28,
                                offset: Offset(0, 10),
                                color: Color(0x33000000),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      t('home_3_btn'),
                                      style: const TextStyle(
                                        fontSize: 24,
                                        height: 1.1,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 50,
                                color: const Color.fromARGB(255, 255, 255, 255)
                                    .withOpacity(0.95),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 17),

                      // White card: certificate
                      _premiumCard(
                        onTap: () => _go(const CertificatePage()),
                        child: Container(
                          height: 110,
                          width: double.infinity,
                          padding: const EdgeInsetsDirectional.fromSTEB(
                              22, 0, 18, 0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(40),
                            color: Colors.white,
                            boxShadow: const [
                              BoxShadow(
                                blurRadius: 18,
                                offset: Offset(0, 8),
                                color: Color(0x24000000),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      t('home_3_btn2'),
                                      style: const TextStyle(
                                        fontSize: 24,
                                        height: 1.05,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF111111),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      t('home_3_btn2_sub'),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        height: 1.2,
                                        fontWeight: FontWeight.w400,
                                        color: Color.fromARGB(255, 83, 73, 73),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 50,
                                color:
                                    const Color(0xFF000000).withOpacity(0.35),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // White card: next umrah
                      _premiumCard(
                        onTap: () => _go(const UmrahStartPage()),
                        child: Container(
                          height: 110,
                          width: double.infinity,
                          padding: const EdgeInsetsDirectional.fromSTEB(
                              22, 0, 18, 0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(40),
                            color: Colors.white,
                            boxShadow: const [
                              BoxShadow(
                                blurRadius: 18,
                                offset: Offset(0, 8),
                                color: Color(0x24000000),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      t('home_3_btn3'),
                                      style: const TextStyle(
                                        fontSize: 24,
                                        height: 1.05,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF111111),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      t('home_3_btn3_sub'),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        height: 1.2,
                                        fontWeight: FontWeight.w400,
                                        color: Color.fromARGB(255, 83, 73, 73),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 50,
                                color:
                                    const Color(0xFF000000).withOpacity(0.35),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 120), // место под FloatingNavBar
                ],
              ),
            ),
          ),

          // Floating nav bar (как ты просил — подключение 1 строкой)
          FloatingNavBar(currentIndex: 2), // 0,1,2
        ],
      ),
    );
  }
}
