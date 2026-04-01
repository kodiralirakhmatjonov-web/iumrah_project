import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iumrah_project/core/localization/translations_store.dart';
import 'package:iumrah_project/core/navigation/premium_route.dart';
import 'package:iumrah_project/core/ui/app_ui.dart';
import 'package:iumrah_project/features/advisor/advisor_chat_page.dart';
import 'package:iumrah_project/home/home_page.dart';
import 'package:iumrah_project/home/tawaf_page.dart';
import 'package:iumrah_project/home/widgets/advisor_top_nav.dart';
import 'package:iumrah_project/home/widgets/umrah_header.dart';
import 'package:iumrah_project/widgets/green_wave.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UmrahStartPage extends StatefulWidget {
  const UmrahStartPage({super.key});

  @override
  State<UmrahStartPage> createState() => _UmrahStartPageState();
}

class _UmrahStartPageState extends State<UmrahStartPage> {
  String t(String key) => TranslationsStore.get(key);

  final AudioPlayer _audioPlayer = AudioPlayer();

  int _phase = 0;
  bool _advisorExpanded = false;
  bool _audioStarted = false;
  String _appLanguage = 'ru';

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

  static const int _lastPhase = 5;

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('app_language') ?? 'ru';

    if (!mounted) return;

    setState(() {
      _appLanguage = lang;
    });
  }

  bool get _isRtlLanguage {
    const rtlCodes = {'ar', 'fa', 'ur', 'he'};
    return rtlCodes.contains(_appLanguage.toLowerCase());
  }

  TextDirection get _textDirection =>
      _isRtlLanguage ? TextDirection.rtl : TextDirection.ltr;

  String _localized(
    String primaryKey, {
    String? fallbackKey,
    required String fallbackText,
  }) {
    final primary = t(primaryKey).trim();
    if (primary.isNotEmpty && primary != primaryKey) return primary;

    if (fallbackKey != null) {
      final fallback = t(fallbackKey).trim();
      if (fallback.isNotEmpty && fallback != fallbackKey) return fallback;
    }

    return fallbackText;
  }

  String _phaseText(int phase) {
    switch (phase) {
      case 0:
        return _localized(
          'start_text',
          fallbackText: 'Start text',
        );
      case 1:
        return _localized(
          'start_text1',
          fallbackKey: 'start_text',
          fallbackText: 'Start text',
        );
      case 2:
        return _localized(
          'start_text2',
          fallbackKey: 'start_text1',
          fallbackText: 'Start text',
        );
      case 3:
        return _localized(
          'start_text3',
          fallbackKey: 'start_text2',
          fallbackText: 'Start text',
        );
      case 4:
        return _localized(
          'start_text4',
          fallbackKey: 'start_text3',
          fallbackText: 'Start text',
        );
      case 5:
      default:
        return _localized(
          'start_text5',
          fallbackKey: 'start_text4',
          fallbackText: 'Start text',
        );
    }
  }

  String _continueLabel() {
    return _localized(
      'complete_btn',
      fallbackKey: 'continue_btn',
      fallbackText: 'Continue',
    );
  }

  String _backLabel() {
    return _localized(
      'back_btn',
      fallbackKey: 'back_button',
      fallbackText: 'Back',
    );
  }

  double _phaseFontSize(String text) {
    final length = text.length;

    if (length > 220) return 24;
    if (length > 180) return 26;
    if (length > 145) return 29;
    if (length > 110) return 33;
    if (length > 85) return 37;
    return 42;
  }

  Future<void> _startAdvisorAudio() async {
    if (!_advisorExpanded) return;
    if (_audioStarted) return;

    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('app_language') ?? 'ru';
    final localPath = prefs.getString('audio_tawaf_start_$lang');

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

  void _handleModeChange(AdvisorMode mode) {
    if (mode == AdvisorMode.emotional) {
      Navigator.pushReplacement(
        context,
        PremiumRoute.push(const UmrahStartPage()),
      );
    }

    if (mode == AdvisorMode.reading) {
      Navigator.pushReplacement(
        context,
        PremiumRoute.push(const HomePage()), // ⚠️ создай страницу если нет
      );
    }

    if (mode == AdvisorMode.chat) {
      Navigator.pushReplacement(
        context,
        PremiumRoute.push(
            const AdvisorChatPage()), // ⚠️ создай страницу если нет
      );
    }
  }

  Future<void> _handleAdvisorTap() async {
    HapticFeedback.lightImpact();

    final willExpand = !_advisorExpanded;

    setState(() {
      _advisorExpanded = willExpand;
    });

    if (willExpand) {
      await _startAdvisorAudio();
    } else {
      await _stopAudio();
    }
  }

  Future<void> _goBack() async {
    if (_phase == 0) return;

    HapticFeedback.selectionClick();

    if (!mounted) return;
    setState(() {
      _phase -= 1;
    });
  }

  Future<void> _goNext() async {
    HapticFeedback.selectionClick();

    if (_phase < _lastPhase) {
      if (!mounted) return;
      setState(() {
        _phase += 1;
      });
      return;
    }

    await _stopAudio();

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PremiumRoute.push(const TawafPage()),
    );
  }

  Widget _buildPhaseText() {
    final currentText = _phaseText(_phase);

    return Directionality(
      textDirection: _textDirection,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 420),
        reverseDuration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        layoutBuilder: (currentChild, previousChildren) {
          return Stack(
            alignment: AlignmentDirectional.bottomStart,
            children: [
              ...previousChildren,
              if (currentChild != null) currentChild,
            ],
          );
        },
        transitionBuilder: (child, animation) {
          final slide = Tween<Offset>(
            begin: const Offset(0, 0.14),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
          );

          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            ),
            child: SlideTransition(
              position: slide,
              child: child,
            ),
          );
        },
        child: Text(
          currentText,
          key: ValueKey<int>(_phase),
          textAlign: TextAlign.start,
          style: TextStyle(
            fontFamily: 'Lato',
            fontSize: _phaseFontSize(currentText),
            fontWeight: FontWeight.w800,
            height: 1.03,
            letterSpacing: -0.9,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.34),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButton({
    required String label,
    required VoidCallback onTap,
    required double height,
    required double fontSize,
  }) {
    return PremiumTap(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 18,
            sigmaY: 18,
          ),
          child: Container(
            height: height,
            alignment: AlignmentDirectional.center,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.34),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: Colors.white.withOpacity(0.08),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.24),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Lato',
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                height: 1,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    final showBack = _phase > 0;

    return Directionality(
      textDirection: _textDirection,
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            width: showBack ? 112 : 0,
            height: 62,
            child: ClipRect(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 220),
                opacity: showBack ? 1 : 0,
                child: IgnorePointer(
                  ignoring: !showBack,
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: SizedBox(
                      width: 112,
                      child: _buildBottomButton(
                        label: _backLabel(),
                        onTap: _goBack,
                        height: 62,
                        fontSize: 17,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            width: showBack ? 12 : 0,
          ),
          Expanded(
            child: _buildBottomButton(
              label: _continueLabel(),
              onTap: _goNext,
              height: 62,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.0, 0.9),
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
              padding: const EdgeInsetsDirectional.only(
                start: 24,
                end: 24,
                bottom: 20,
              ),
              child: Column(
                children: [
                  const UmrahHeader(currentStep: 0),
                  const SizedBox(height: 15),
                  AdvisorTopNav(
                    current: AdvisorMode.emotional,
                    onChanged: _handleModeChange,
                  ),
                  const SizedBox(height: 20),
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
                        Directionality(
                          textDirection: TextDirection
                              .ltr, // 🔥 фиксируем LTR только здесь
                          child: SizedBox(
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

                                // ❗ заменили PositionedDirectional → Positioned
                                Positioned(
                                  top: 20,
                                  left: 30,
                                  child: Container(
                                    width: _progressW,
                                    height: _progressH,
                                    decoration: BoxDecoration(
                                      color: const Color(0x33F06D13),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                ),

                                const Positioned(
                                  left: 40,
                                  top: 80,
                                  child: Text(
                                    'Advisor Premium Guide',
                                    textAlign: TextAlign.left, // ❗ фикс
                                    style: TextStyle(
                                      fontFamily: 'Lato',
                                      fontWeight: FontWeight.w800,
                                      fontSize: 23,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),

                                Positioned(
                                  left: _advisorExpanded
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
                                      behavior: HitTestBehavior.opaque,
                                      onTap: _handleAdvisorTap,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(18),
                                        child: IgnorePointer(
                                          // 🔥 чтобы wave не ломал тапы
                                          child: GreenWave(
                                            expanded: _advisorExpanded,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: AlignmentDirectional.bottomStart,
                      child: Padding(
                        padding: const EdgeInsetsDirectional.only(
                          start: 4,
                          end: 4,
                          bottom: 4,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ConstrainedBox(
                              constraints: const BoxConstraints(
                                minHeight: 220,
                              ),
                              child: Align(
                                alignment: AlignmentDirectional.bottomStart,
                                child: _buildPhaseText(),
                              ),
                            ),
                            const SizedBox(height: 26),
                            _buildControls(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
