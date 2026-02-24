import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:iumrah_project/home/audio_get.dart';
import 'package:iumrah_project/home/in_umrah_page.dart';
import 'package:iumrah_project/home/mydua_page.dart';
import 'package:iumrah_project/home/plus_page.dart';
import 'package:iumrah_project/home/profile_page.dart';
import 'package:iumrah_project/home/umrah_end.dart';
import 'package:iumrah_project/home/umrah_page.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:iumrah_project/core/navigation/premium_route.dart';
import 'package:iumrah_project/core/localization/translations_store.dart';
import 'package:iumrah_project/core/ui/app_ui.dart'; // AppUI + PremiumTap
import 'package:iumrah_project/home/widgets/floating_nav_bar.dart';
import '../splash/version_gate.dart';
import '../core/navigation/premium_route.dart';
import '../splash/update_required_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  // UI
  late final AnimationController _glowCtrl;
  late final Animation<double> _glowOpacity;

  static const Duration _fadeDur = Duration(seconds: 3);
  static const Duration _holdDur = Duration(seconds: 12);

  bool _textVisible = true;

  // Text cycling
  int _phase = 0; // 0 -> with name + welcome, 1 -> title2, 2 -> title3
  Timer? _cycleTimer;

  // Profile cache
  String _name = '';
  bool _loadingName = true;
  String _country = '';

  // Pref keys
  static const String _prefsNameKey = 'profile_name';
  static const String _prefsCountryKey = 'profile_country';
  static const String _prefsPremiumKey = 'is_premium';

  static const _lastCheckKey = 'last_version_check';

  Future<void> _checkAppVersionWeekly() async {
    final prefs = await SharedPreferences.getInstance();

    final lastCheck = prefs.getInt(_lastCheckKey);
    final now = DateTime.now().millisecondsSinceEpoch;

    /// 7 дней
    const weekMs = 7 * 24 * 60 * 60 * 1000;

    /// если уже проверяли недавно — НЕ ИДЕМ В БАЗУ
    if (lastCheck != null && now - lastCheck < weekMs) return;

    final must = await VersionGate.mustUpdate();

    if (!mounted) return;

    /// сохраняем время проверки
    await prefs.setInt(_lastCheckKey, now);

    if (must) {
      Navigator.of(context).pushAndRemoveUntil(
        PremiumRoute.push(const UpdateRequiredPage()),
        (route) => false,
      );
    }
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

    /// ⬇️ ВАЖНО: проверка ПОСЛЕ первого рендера
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAppVersionWeekly();
    });
  }

  Future<void> _bootstrap() async {
    _glowCtrl.forward();
    _startCycle();
    await _loadNameOnce();
  }

  void _startCycle() {
    _cycleTimer?.cancel();
    _cycleTimer = Timer.periodic(_holdDur, (_) {
      final next = (_phase + 1) % 3;
      _switchPhase(next);
    });
  }

  Future<void> _switchPhase(int next) async {
    if (!mounted) return;

    setState(() => _textVisible = false);

    await Future.delayed(_fadeDur);
    if (!mounted) return;

    setState(() {
      _phase = next;
      _textVisible = true;
    });
  }

  Future<void> _loadNameOnce() async {
    final prefs = await SharedPreferences.getInstance();

    // 1) cache first
    final cached = prefs.getString(_prefsNameKey);
    if (cached != null && cached.trim().isNotEmpty) {
      if (!mounted) return;
      setState(() {
        _name = cached.trim();
        _country = (prefs.getString(_prefsCountryKey) ?? '').trim();
        _loadingName = false;
      });
      return;
    }

    // 2) one request максимум (и только если есть user)
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() => _loadingName = false);
      return;
    }

    try {
      final row = await Supabase.instance.client
          .from('profiles')
          .select('name, country, is_premium')
          .eq('user_id', user.id)
          .maybeSingle();

      final fetchedName = (row?['name'] ?? '').toString().trim();
      final fetchedCountry = (row?['country'] ?? '').toString().trim();

      // ✅ ВАЖНО: правильное присваивание (это была твоя главная ошибка)
      final fetchedPremium =
          (row?['is_premium'] == true || row?['is_premium'] == 1);

      if (fetchedName.isNotEmpty) {
        await prefs.setString(_prefsNameKey, fetchedName);
      }

      if (fetchedCountry.isNotEmpty) {
        await prefs.setString(_prefsCountryKey, fetchedCountry);
      }

      // ✅ premium сохраняем отдельно
      await prefs.setBool(_prefsPremiumKey, fetchedPremium);

      // debug (если хочешь)
      // ignore: avoid_print
      print("PREMIUM LOCAL = ${prefs.getBool(_prefsPremiumKey)}");

      if (!mounted) return;
      setState(() {
        _name = fetchedName;
        _country = fetchedCountry;
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
    final colors = <Color>[
      const Color(0xFF14B8A6),
    ];
    return colors[rnd.nextInt(colors.length)];
  }

  String _initialLetter() {
    final s = _name.trim();
    if (s.isEmpty) return 'A';
    return s.characters.first.toUpperCase();
  }

  Widget _animatedHeadline() {
    Widget child;

    if (!_textVisible) {
      child = const SizedBox(key: ValueKey('empty'));
    } else if (_phase == 0) {
      child = Column(
        key: const ValueKey('phase0'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _loadingName ? '' : _name,
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
            t('home_title'),
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
        ],
      );
    } else if (_phase == 1) {
      child = Column(
        key: const ValueKey('phase1'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            t('home_title2'),
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
            t('home_title2_sub'),
            textAlign: TextAlign.center,
            maxLines: 4,
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
    } else {
      child = Column(
        key: const ValueKey('phase2'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            t('home_title3'),
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
            t('home_title3_sub'),
            textAlign: TextAlign.center,
            maxLines: 4,
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
      backgroundColor: const Color(0xFF131313),
      body: Stack(
        children: [
          // ЗОЛОТОЙ СВЕТ
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.0, -0.4),
                  radius: 0.6,
                  colors: [
                    Color(0xFFFFBD07),
                    Color(0x00FFBD07),
                  ],
                  stops: [0.0, 1.0],
                ),
              ),
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
                          height: 80,
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

                  _animatedHeadline(),

                  const Spacer(),

                  Column(
                    children: [
                      // Green premium card
                      _premiumCard(
                        onTap: () {
                          Navigator.of(context).push(
                            PremiumRoute.push(const PlusPage()),
                          );
                        },
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
                                Color(0xFF62FF00),
                                Color(0xff007D06),
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
                                      t('home_btn2'),
                                      style: const TextStyle(
                                        fontSize: 24,
                                        height: 1.1,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      t('home_btn2_sub'),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        height: 1.2,
                                        fontWeight: FontWeight.w400,
                                        color: Color(0xFFEFFFEA),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 50,
                                color: Colors.white.withOpacity(0.95),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 17),

                      // White card: Start Umrah
                      _premiumCard(
                        onTap: () {
                          Navigator.of(context).push(
                            PremiumRoute.push(const InUmrahPage()),
                          );
                        },
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
                                child: Text(
                                  t('home_btn'),
                                  style: const TextStyle(
                                    fontSize: 26,
                                    height: 1.1,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFB56B00),
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 50,
                                color: Colors.black.withOpacity(0.35),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // White card: My Dua
                      _premiumCard(
                        onTap: () => _go(const MyDuaPage()),
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
                                      t('home_btn3'),
                                      style: const TextStyle(
                                        fontSize: 24,
                                        height: 1.05,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF111111),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      t('home_btn3_sub'),
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
                                color: Colors.black.withOpacity(0.35),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),

          const FloatingNavBar(currentIndex: 0),
        ],
      ),
    );
  }
}
