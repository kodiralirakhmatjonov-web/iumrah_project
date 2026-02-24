import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:iumrah_project/core/localization/translations_store.dart';
import 'package:iumrah_project/core/navigation/premium_route.dart';

import 'package:iumrah_project/features/umrah/mydua_modal.dart';
import 'package:iumrah_project/home/modal/pay_overlay.dart';
import 'package:iumrah_project/home/modal/safa_modal.dart';
import 'package:iumrah_project/home/umrah_end.dart';
import 'package:iumrah_project/widgets/green_wave.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class SafaPage extends StatefulWidget {
  const SafaPage({super.key});

  @override
  State<SafaPage> createState() => _SafaPageState();
}

class _SafaPageState extends State<SafaPage> with TickerProviderStateMixin {
  // ---------- translations helper (твоя архитектура: TranslationsStore.get)
  String t(String key) => TranslationsStore.get(key);

  // ======================
  // TAWAF STATE (1..7)
  // ======================
  int _currentRound = 1; // 1..7

  // ---------- Advisor card (2 состояния)
  bool _advisorExpanded = false;

  // blinking "tap_btn" (5s on / 5s off)
  bool _showTap = true;
  Timer? _tapTimer;

  // ---------- text states (Standart / Personal)
  final PageController _textPage = PageController();
  int _textIndex = 0;

  // ---------- Audio
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _audioStarted = false;

  bool _isPremium = false;
  static const String _premiumKey = 'is_premium';

  // ---------- swipe slider
  double _sliderDx = 0.0; // 0..max
  bool _sliderDone = false;

  // размеры (как ты дал)
  static const double _advisorW = 340;

  static const double _progressW = 280;
  static const double _progressH = 35;

  // =======================
  // CONTAINER HEIGHTS
  // =======================
  final double _collapsedHeight = 150;
  final double _expandedHeight = 240;

  // =======================
  // WAVE — COLLAPSED
  // =======================
  final double _waveCollapsedWidth = 200;
  final double _waveCollapsedHeight = 70;
  final double _waveCollapsedStart = 122;
  final double _waveCollapsedTop = 70;

  // =======================
  // WAVE — EXPANDED
  // =======================
  final double _waveExpandedWidth = 310;
  final double _waveExpandedHeight = 120;
  final double _waveExpandedStart = 16;
  final double _waveExpandedTop = 110;

  // зона свайпа
  static const double _swipeW = 310;
  static const double _swipeH = 85;

  // ползунок внутри зоны
  static const double _knobSize = 62;
  double get _sliderMax => (_swipeW - _knobSize - 16).clamp(0, 9999);

  // ======================
  // PROGRESS
  // ======================
  double get _roundProgress {
    if (_sliderMax <= 0) return 0.0;
    return (_sliderDx / _sliderMax).clamp(0.0, 1.0);
  }

  // Tawaf = 50% всей Umrah-полосы
  double get _umrahTopProgress {
    final completedBefore = (_currentRound - 1).clamp(0, 7);
    final total = (completedBefore + _roundProgress).clamp(0.0, 7.0);

    return 0.5 + ((total / 7.0) * 0.5); // 0.5 .. 1.0
  }

  double get _topFillWidth => _progressW * _umrahTopProgress;

  // ======================
  // TEXT KEYS (dynamic)
  // ======================
  String get _titleKey => 'safa${_currentRound}_title1';

  String _standardKeyForRound(int r) => 'safa${r}_text1';

  String _personalKeyForRound(int r) {
    final k2 = 'safa${r}_text2';
    final v2 = t(k2);
    if (v2 != k2) return k2;

    final k3 = 'safa${r}_text3';
    final v3 = t(k3);
    if (v3 != k3) return k3;

    return k2;
  }

  // ======================
  // OFFLINE AUDIO KEY (SharedPrefs from AudioGetPage)
  // ======================
  String _audioPrefsKey(int round, String lang) => 'audio_safa_${round}_$lang';

  Future<void> _startAudioIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();

    final isPremium = prefs.getBool('is_premium') ?? false;
    if (!isPremium) return;
    if (!_advisorExpanded) return;
    if (_audioStarted) return;

    final lang = prefs.getString('app_language') ?? 'ru';

    final localPath = prefs.getString(_audioPrefsKey(_currentRound, lang));
    if (localPath == null || localPath.isEmpty) return;

    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(DeviceFileSource(localPath));
      _audioStarted = true;
    } catch (_) {}
  }

  Future<void> _stopAudio() async {
    try {
      await _audioPlayer.stop();
    } catch (_) {}
    _audioStarted = false;
  }

  Future<void> _loadPremium() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getBool(_premiumKey) ?? false;
    if (!mounted) return;
    setState(() => _isPremium = v);
  }

  Future<void> _handleAdvisorTap() async {
    HapticFeedback.lightImpact();

    final prefs = await SharedPreferences.getInstance();
    final isPremium = prefs.getBool('is_premium') ?? false;

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

    setState(() => _advisorExpanded = !_advisorExpanded);

    if (_advisorExpanded) {
      await _startAudioIfNeeded();
    } else {
      await _stopAudio();
    }
  }

  // ======================
  // ROUND COMPLETE
  // ======================
  void _goNextRoundOrFinish() {
    if (_currentRound < 7) {
      setState(() {
        _currentRound += 1;
        _sliderDx = 0.0;
        _sliderDone = false;
        _audioStarted = false;
      });

      _textPage.jumpToPage(0);

      if (_advisorExpanded) {
        _startAudioIfNeeded();
      }
    } else {
      Navigator.of(context).pushReplacement(
        PremiumRoute.push(const UmrahEndPage()),
      );
    }
  }

  void _openMyDua() => MyDuaModal.open(context);
  void _openSunnaDua() => SafaModal.open(context);

  void _onSwipeUpdate(DragUpdateDetails d) {
    if (_sliderDone) return;
    setState(() {
      _sliderDx = (_sliderDx + d.delta.dx).clamp(0.0, _sliderMax);
    });
  }

  void _onSwipeEnd(DragEndDetails d) {
    if (_sliderDone) return;

    final done = _sliderDx >= _sliderMax * 0.92;
    if (done) {
      setState(() {
        _sliderDx = _sliderMax;
        _sliderDone = true;
      });
      Future.delayed(const Duration(milliseconds: 250), _goNextRoundOrFinish);
    } else {
      setState(() => _sliderDx = 0.0);
    }
  }

  Widget _dot(bool active) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: active ? Colors.black54 : Colors.black12,
        shape: BoxShape.circle,
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    _tapTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      setState(() => _showTap = !_showTap);
    });

    _loadPremium();

    _textPage.addListener(() {
      final p = _textPage.page ?? 0.0;
      final idx = (p.round()).clamp(0, 1);
      if (idx != _textIndex && mounted) {
        setState(() => _textIndex = idx);
      }
    });
  }

  @override
  void dispose() {
    _tapTimer?.cancel();
    _textPage.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int currentStep = _currentRound;
    final double circleProgress = (_currentRound / 7).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFFe6e6ef),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ---------- TOP: logo left, back right
                  SizedBox(
                    width: double.infinity,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Image.asset(
                          'assets/images/iumrah_logo.png',
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
                  ),

                  const SizedBox(height: 16),

                  // =======================
                  // ADVISOR BLOCK
                  // =======================

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
                          ),
                        ),
                        Positioned(
                          top: 20,
                          left: 30,
                          child: Container(
                            width: _progressW,
                            height: _progressH,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E4F3B),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeInOut,
                                width: _topFillWidth.clamp(0.0, _progressW),
                                height: _progressH,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF9DFF3C),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const Positioned(
                          left: 40,
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
                        Positioned(
                          right: 20,
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

                  const SizedBox(height: 30),

                  // ---------- TEXT BLOCK (2 состояния, свайп)
                  SizedBox(
                    width: 360,
                    child: Column(
                      children: [
                        SizedBox(
                          height: 270,
                          child: PageView(
                            controller: _textPage,
                            children: [
                              _DuaTextPage(
                                titleLeft: 'Standart ',
                                titleRight: t(_titleKey),
                                body: t(_standardKeyForRound(_currentRound)),
                              ),
                              _DuaTextPage(
                                titleLeft: 'Personal',
                                titleRight: t(_titleKey),
                                body: t(_personalKeyForRound(_currentRound)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _dot(_textIndex == 0),
                            const SizedBox(width: 10),
                            _dot(_textIndex == 1),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ---------- Buttons container (two pills)
                  Container(
                    width: 340,
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _PillButton(
                                height: 46,
                                radius: 50,
                                bg: const Color(0xFFD7C24B),
                                fg: Colors.white,
                                text: t('home_btn3'),
                                onTap: _openMyDua,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _PillButton(
                                height: 46,
                                radius: 50,
                                bg: Colors.black,
                                fg: Colors.white,
                                text: t('sunna_dua_btn'),
                                onTap: _openSunnaDua,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Container(
                            width: _swipeW,
                            height: _swipeH,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(40),
                            ),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(40),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 160),
                                        width: _sliderDone
                                            ? _swipeW
                                            : (16 + _sliderDx + _knobSize),
                                        height: _swipeH,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF9DFF3C)
                                              .withOpacity(0.75),
                                          borderRadius:
                                              BorderRadius.circular(40),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 8 + _sliderDx,
                                  top: (_swipeH - _knobSize) / 2,
                                  child: GestureDetector(
                                    onHorizontalDragUpdate: _onSwipeUpdate,
                                    onHorizontalDragEnd: _onSwipeEnd,
                                    child: Container(
                                      width: _knobSize,
                                      height: _knobSize,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF9DFF3C),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            blurRadius: 18,
                                            offset: const Offset(0, 8),
                                            color:
                                                Colors.black.withOpacity(0.18),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Icon(
                                          _sliderDone
                                              ? Icons.check_rounded
                                              : Icons.arrow_forward_rounded,
                                          size: 26,
                                          color: Colors.black.withOpacity(0.65),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 4,
                                  top: (_swipeH - 80) / 2,
                                  child: SizedBox(
                                    width: 80,
                                    height: 80,
                                    child: TweenAnimationBuilder<double>(
                                      tween: Tween<double>(
                                        begin: 0,
                                        end: circleProgress,
                                      ),
                                      duration:
                                          const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                      builder: (context, value, _) {
                                        return Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            CustomPaint(
                                              size: const Size(80, 80),
                                              painter: _CircleProgressPainter(
                                                progress: value,
                                                backgroundColor:
                                                    const Color(0xFF2E4F3F),
                                                progressColor:
                                                    const Color(0xFFB4F000),
                                                strokeWidth: 13,
                                              ),
                                            ),
                                            Text(
                                              '$currentStep',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 20,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                if (_showTap && !_sliderDone)
                                  Positioned.fill(
                                    child: Center(
                                      child: Text(
                                        t('tap_btn'),
                                        style: TextStyle(
                                          fontFamily: 'Lato',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black.withOpacity(0.35),
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
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CircleProgressPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;
  final double strokeWidth;

  const _CircleProgressPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2.5;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircleProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

class _DuaTextPage extends StatelessWidget {
  final String titleLeft;
  final String titleRight;
  final String body;

  const _DuaTextPage({
    required this.titleLeft,
    required this.titleRight,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              titleLeft,
              textAlign: TextAlign.left,
              style: TextStyle(
                fontFamily: 'Lato',
                fontWeight: FontWeight.w700,
                fontSize: 24,
                color: Colors.black.withOpacity(0.55),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              titleRight,
              textAlign: TextAlign.left,
              style: TextStyle(
                fontFamily: 'Lato',
                fontWeight: FontWeight.w800,
                fontSize: 22,
                color: Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Center(
            child: Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Lato',
                fontWeight: FontWeight.w600,
                fontSize: 26,
                height: 1.1,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PillButton extends StatelessWidget {
  final double height;
  final double radius;
  final Color bg;
  final Color fg;
  final String text;
  final VoidCallback onTap;

  const _PillButton({
    required this.height,
    required this.radius,
    required this.bg,
    required this.fg,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onTap,
          child: Center(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Lato',
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: fg,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
