import 'dart:async';
import 'package:flutter/material.dart';
import 'package:iumrah_project/core/localization/translations_store.dart';
import 'package:iumrah_project/core/navigation/premium_route.dart';
import 'package:iumrah_project/core/ui/app_ui.dart';
import 'package:iumrah_project/features/umrah/mydua_modal.dart';
import 'package:iumrah_project/home/certificate_page.dart';
import 'package:iumrah_project/home/modal/pay_overlay.dart';
import 'package:iumrah_project/widgets/green_wave.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart'; // ✅ ДОБАВЛЕНО

class UmrahEndPage extends StatefulWidget {
  const UmrahEndPage({super.key});

  @override
  State<UmrahEndPage> createState() => _UmrahEndPageState();
}

class _UmrahEndPageState extends State<UmrahEndPage>
    with TickerProviderStateMixin {
  String t(String key) => TranslationsStore.get(key);

  int _phase = 0;
  bool _darkMode = false;
  bool _advisorExpanded = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final AudioPlayer _audioPlayer = AudioPlayer(); // ✅
  bool _audioStarted = false; // ✅ защита от повторного старта

  final double _advisorW = 340;
  final double _collapsedHeight = 150;
  final double _expandedHeight = 240;

  final double _progressW = 280;
  final double _progressH = 35;

  final double _waveCollapsedWidth = 200;
  final double _waveCollapsedHeight = 70;
  final double _waveCollapsedStart = 122;
  final double _waveCollapsedTop = 70;

  final double _waveExpandedWidth = 310;
  final double _waveExpandedHeight = 120;
  final double _waveExpandedStart = 16;
  final double _waveExpandedTop = 110;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);

    _startPhases();
  }

  Future<bool> _isPremiumUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_premium') ?? false;
  }

  // ====================================================
  // 🎧 AUDIO LOGIC (ТРОГАЕМ ТОЛЬКО ЭТО)
  // ====================================================

  Future<void> _startPremiumAudio() async {
    final prefs = await SharedPreferences.getInstance();

    final isPremium = prefs.getBool('is_premium') ?? false;
    if (!isPremium) return;

    if (!_advisorExpanded) return;

    if (_audioStarted) return;

    final lang = prefs.getString('app_language') ?? 'ru';

    // 👇 БЕРЕМ ИЗ КЕША AudioGetPage
    final localPath = prefs.getString("audio_safa_end_$lang");

    if (localPath == null) return;

    try {
      await _audioPlayer.setFilePath(localPath);
      await _audioPlayer.play();
      _audioStarted = true;
    } catch (_) {}
  }

  Future<void> _stopAudio() async {
    try {
      await _audioPlayer.stop();
    } catch (_) {}
    _audioStarted = false;
  }

  // ====================================================

  Future<void> _startPhases() async {
    await _runSinglePhase(0);
    await _runSinglePhase(1);
    await _runSinglePhase(2);

    setState(() {
      _phase = 3;
    });

    await _fadeController.forward();
  }

  Future<void> _handleAdvisorTap() async {
    HapticFeedback.lightImpact();

    final isPremium = await _isPremiumUser();

    if (!isPremium) {
      if (!mounted) return;
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const PayOverlay(),
      );
      return;
    }

    _toggleAdvisor();

    if (_advisorExpanded) {
      await _startPremiumAudio();
    } else {
      await _stopAudio();
    }
  }

  Future<void> _runSinglePhase(int phaseIndex) async {
    setState(() {
      _phase = phaseIndex;
    });

    await _fadeController.forward();
    await Future.delayed(const Duration(seconds: 30));
    await _fadeController.reverse();
  }

  void _toggleDarkMode() {
    if (_phase == 3) {
      setState(() {
        _darkMode = !_darkMode;
      });
    }
  }

  void _goNext() {
    Navigator.of(context).pushReplacement(
      PremiumRoute.push(const CertificatePage()),
    );
  }

  void _toggleAdvisor() {
    setState(() => _advisorExpanded = !_advisorExpanded);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _audioPlayer.dispose(); // ✅
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isFinalPhase = _phase == 3;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.0, 0.1),
                  radius: 0.7,
                  colors: [
                    Color(0xffF06D13),
                    Color(0x00F06D13),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Image.asset(
                        'assets/images/iumrah_logo1.png',
                        height: 85,
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          height: 50,
                          width: 50,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            size: 30,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // ================= ADVISOR =================
                  SizedBox(
                    width: _advisorW,
                    height: 240, // фиксируем максимальную высоту
                    child: Stack(
                      children: [
                        // =======================
                        // BLACK CONTAINER
                        // =======================

                        AnimatedContainer(
                          duration: const Duration(seconds: 1),
                          curve: Curves.easeInOutCubic,
                          width: _advisorW,
                          height: _advisorExpanded
                              ? _expandedHeight
                              : _collapsedHeight,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(
                              color: const Color(0xFFF06D13),
                              width: 1,
                            ),
                          ),
                        ),

                        // =======================
                        // PROGRESS BAR (Umrah top progress: Tawaf fills to 50%)
                        // =======================

                        PositionedDirectional(
                          top: 20,
                          start: 30,
                          child: Container(
                            width: _progressW,
                            height: _progressH,
                            decoration: BoxDecoration(
                              color: const Color(0x33F06D13),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeInOut,
                                height: _progressH,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF06D13),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // =======================
                        // ADVISOR TEXT
                        // =======================

                        const PositionedDirectional(
                          start: 40,
                          top: 80,
                          child: Text(
                            'Advisor Umrah Assistant',
                            style: TextStyle(
                              fontFamily: 'Lato',
                              fontWeight: FontWeight.w700,
                              fontSize: 22,
                              color: Colors.white,
                            ),
                          ),
                        ),

                        // =======================
                        // GREEN WAVE (ТАЧ ЗДЕСЬ)
                        // =======================

                        PositionedDirectional(
                          start: _advisorExpanded
                              ? _waveExpandedStart
                              : _waveCollapsedStart,
                          top: _advisorExpanded
                              ? _waveExpandedTop
                              : _waveCollapsedTop,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 900),
                            curve: Curves.easeInOutCubic,
                            width: _advisorExpanded
                                ? _waveExpandedWidth
                                : _waveCollapsedWidth,
                            height: _advisorExpanded
                                ? _waveExpandedHeight
                                : _waveCollapsedHeight,
                            child: GestureDetector(
                              onTap: _handleAdvisorTap,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: GreenWave(
                                  expanded: _advisorExpanded,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // =======================
                        // POWERED BY AI
                        // =======================

                        PositionedDirectional(
                          end: 20,
                          bottom: 18,
                          child: AnimatedOpacity(
                            opacity: _advisorExpanded ? 1 : 0,
                            duration: const Duration(milliseconds: 500),
                            child: const Text(
                              'powered by AI',
                              style: TextStyle(
                                fontFamily: 'Lato',
                                fontSize: 11,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // ================= TEXT PHASE =================
                  GestureDetector(
                    onTap: _toggleDarkMode,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        _phase == 0
                            ? t('end_text')
                            : _phase == 1
                                ? t('end_text1')
                                : t('end_text3'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: _phase >= 2 ? 30 : 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // ================= BOTTOM BLOCK =================
                  Container(
                    padding: const EdgeInsetsDirectional.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(
                        color: const Color(0xFFF06D13),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        // DUA BUTTON
                        PremiumTap(
                          onTap: () {
                            MyDuaModal.open(context);
                          },
                          child: Container(
                            height: 50,
                            width: double.infinity,
                            alignment: AlignmentDirectional.center,
                            decoration: BoxDecoration(
                              color: Colors.yellow,
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Text(
                              t('home_btn3'),
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 15),

                        // CONTINUE BUTTON
                        SizedBox(
                          height: 60,
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                            ),
                            onPressed: _goNext, // всегда активна
                            child: Text(
                              t('continue_btn'),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // ================= DARK MODE FULL SCREEN =================
          if (_darkMode && _phase == 3)
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleDarkMode,
                child: Container(
                  color: Colors.black,
                  alignment: Alignment.center,
                  child: Text(
                    t('start_text3'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 30,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
