import 'dart:async';
import 'package:flutter/material.dart';
import 'package:iumrah_project/core/localization/translations_store.dart';
import 'package:iumrah_project/core/navigation/premium_route.dart';
import 'package:iumrah_project/core/ui/app_ui.dart';
import 'package:iumrah_project/features/umrah/mydua_modal.dart';
import 'package:iumrah_project/home/advisor_home.dart';
import 'package:iumrah_project/home/widgets/app_header.dart';
import 'package:iumrah_project/widgets/green_wave.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

class HotbaPage extends StatefulWidget {
  const HotbaPage({super.key});

  @override
  State<HotbaPage> createState() => _HotbaPageState();
}

class _HotbaPageState extends State<HotbaPage> with TickerProviderStateMixin {
  String t(String key) {
    final value = TranslationsStore.get(key).trim();
    if (value.isEmpty || value == key || value == '[$key]') return '';
    return value;
  }

  int _phase = 0;
  bool _darkMode = false;
  bool _advisorExpanded = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  late AnimationController _tapHintController;

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _audioStarted = false;

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

    _tapHintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 7500),
    )..repeat();

    _audioPlayer.playerStateStream.listen((state) {
      if (!mounted) return;
      if (state.processingState == ProcessingState.completed) {
        _audioStarted = false;
      }
    });

    _startPhases();
  }

  Future<void> _startHeartAudio() async {
    if (!_advisorExpanded) return;
    if (_audioStarted) return;

    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('app_language') ?? 'ru';

    final localPath = prefs.getString('audio_hotba_$lang') ??
        prefs.getString('audio_heart_prep_$lang') ??
        prefs.getString('audio_safa_end_$lang');

    if (localPath == null || localPath.isEmpty) return;

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

    _toggleAdvisor();

    if (_advisorExpanded) {
      await _startHeartAudio();
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
      PremiumRoute.push(const AdvisorHomePage()),
    );
  }

  void _toggleAdvisor() {
    setState(() => _advisorExpanded = !_advisorExpanded);
  }

  double _tapHintOpacity() {
    final v = _tapHintController.value;

    if (v < 0.08) {
      return v / 0.08;
    }
    if (v < 0.67) {
      return 1;
    }
    if (v < 0.80) {
      return 1 - ((v - 0.67) / 0.13);
    }
    return 0;
  }

  Widget _buildPreparingStatus() {
    return Text(
      t(
        'hotba_running',
      ),
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontFamily: 'Lato',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
  }

  String _phaseText() {
    switch (_phase) {
      case 0:
        return t(
          'hotba_text',
        );
      case 1:
        return t(
          'hotba_text1',
        );
      case 2:
        return t(
          'hotba_text3',
        );
      default:
        return t(
          'hotba_text4',
        );
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _tapHintController.dispose();
    _audioPlayer.dispose();
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
                  AppHeader(
                    isDarkBackground: false,
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: _advisorW,
                    height: 240,
                    child: Stack(
                      children: [
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
                                width: 0,
                                height: _progressH,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF06D13),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ),
                        ),
                        PositionedDirectional(
                          start: 40,
                          top: 80,
                          child: const Text(
                            'Advisor Premium Guide',
                            style: TextStyle(
                              fontFamily: 'Lato',
                              fontWeight: FontWeight.w700,
                              fontSize: 22,
                              color: Colors.white,
                            ),
                          ),
                        ),
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
                                child: Text(
                                  t(
                                    'hotbar_tap_hint',
                                  ),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontFamily: 'Lato',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black,
                                        blurRadius: 10,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
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
                        PositionedDirectional(
                          start: 0,
                          end: 0,
                          bottom: 18,
                          child: AnimatedOpacity(
                            opacity: _advisorExpanded ? 1 : 0,
                            duration: const Duration(milliseconds: 500),
                            child: Center(
                              child: _buildPreparingStatus(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _toggleDarkMode,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        _phaseText(),
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
                        SizedBox(
                          height: 60,
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                            ),
                            onPressed: _goNext,
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
          if (_darkMode && isFinalPhase)
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleDarkMode,
                child: Container(
                  color: Colors.black,
                  alignment: Alignment.center,
                  child: Text(
                    t(
                      'hotbar_text5',
                    ),
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
