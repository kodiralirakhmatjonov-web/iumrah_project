import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iumrah_project/core/localization/translations_store.dart';
import 'package:iumrah_project/core/navigation/premium_route.dart';
import 'package:iumrah_project/core/ui/app_ui.dart';
import 'package:iumrah_project/features/advisor/advisor_chat_page.dart';
import 'package:iumrah_project/features/advisor/hotba_page.dart';
import 'package:iumrah_project/home/certificate_page.dart';
import 'package:iumrah_project/widgets/green_wave.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdvisorHomePage extends StatefulWidget {
  const AdvisorHomePage({super.key});

  @override
  State<AdvisorHomePage> createState() => _AdvisorHomePageState();
}

class _AdvisorHomePageState extends State<AdvisorHomePage>
    with TickerProviderStateMixin {
  late final AnimationController _glowCtrl;
  late final Animation<double> _glowOpacity;

  final GlobalKey navBarKey = GlobalKey();

  static const Duration _fadeDur = Duration(seconds: 3);
  static const Duration _holdDur = Duration(seconds: 15);

  final ScrollController _scrollController = ScrollController();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _textVisible = true;
  int _phase = 0;
  bool _advisorExpanded = false;
  bool _audioStarted = false;
  String _appLanguage = 'ru';

  Timer? _cycleTimer;

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

    _loadLanguage();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navState = navBarKey.currentState as dynamic;
      navState.animateToAdvisor(context);
    });
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

  String _avatarAsset(String key) {
    if (key.startsWith('male_')) {
      return 'assets/profile/avatars/male/$key.png';
    }
    if (key.startsWith('female_')) {
      return 'assets/profile/avatars/female/$key.png';
    }
    return 'assets/profile/avatars/male/male_01.png';
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

  @override
  void dispose() {
    _cycleTimer?.cancel();
    _glowCtrl.dispose();
    _scrollController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Widget _animatedHeadline() {
    Widget child;

    if (!_textVisible) {
      child = const SizedBox(
        key: ValueKey('empty'),
      );
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
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.0,
              letterSpacing: -0.9,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            t('home2_3_subtitle'),
            textAlign: TextAlign.center,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            softWrap: true,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.0,
              letterSpacing: -0.9,
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
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.0,
              letterSpacing: -0.9,
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
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.0,
              letterSpacing: -0.9,
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
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.0,
              letterSpacing: -0.9,
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
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.0,
              letterSpacing: -0.9,
            ),
          ),
        ],
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(seconds: 1),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (widget, animation) {
        final fade = FadeTransition(opacity: animation, child: widget);
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.02),
            end: Offset.zero,
          ).animate(animation),
          child: fade,
        );
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

  Widget _buildTopRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(
          'assets/images/advisor_ai_logo.png',
          height: 60,
        ),
        const Spacer(),
        SizedBox(
          height: 60,
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: PremiumTap(
              onTap: () {
                Navigator.of(context).maybePop();
              },
              child: Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.96),
                  gradient: LinearGradient(
                    begin: AlignmentDirectional.topStart,
                    end: AlignmentDirectional.bottomEnd,
                    colors: [
                      Colors.white,
                      const Color(0xFFF1F1F1),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.10),
                      blurRadius: 14,
                      offset: const Offset(0, 1),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.18),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                alignment: AlignmentDirectional.center,
                child: const Icon(
                  Icons.close_rounded,
                  size: 26,
                  weight: 40,
                  color: Color.fromARGB(255, 60, 60, 60),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeadlineBlock() {
    return SizedBox(
      height: 240,
      child: Center(
        child: _animatedHeadline(),
      ),
    );
  }

  Widget _buildAdvisorGuideBlock() {
    return Directionality(
      textDirection: _textDirection,
      child: Center(
        child: SizedBox(
          width: _advisorW,
          height: 240,
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(seconds: 1),
                curve: Curves.easeInOutCubic,
                width: _advisorW,
                height: _advisorExpanded ? _expandedHeight : _collapsedHeight,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: const Color(0xFFF06D13),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF06D13).withOpacity(0.08),
                      blurRadius: 26,
                      spreadRadius: 1,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
              ),
              Directionality(
                textDirection: TextDirection.ltr,
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
                          textAlign: TextAlign.left,
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardsBlock() {
    return Column(
      children: [
        PremiumTap(
          onTap: () => _go(const AdvisorChatPage()),
          child: Container(
            height: 110,
            width: double.infinity,
            padding: const EdgeInsetsDirectional.fromSTEB(22, 18, 18, 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              gradient: const LinearGradient(
                begin: AlignmentDirectional.centerStart,
                end: AlignmentDirectional.centerEnd,
                colors: [
                  Color.fromARGB(255, 254, 106, 1),
                  Color.fromARGB(255, 73, 41, 0),
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
                      const Text(
                        'Advisor AI',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.0,
                          letterSpacing: -0.9,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        t('advhome_btn_sub'),
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.2,
                          fontWeight: FontWeight.w600,
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
        const SizedBox(height: 16),
        _premiumCard(
          onTap: () => _go(const HotbaPage()),
          child: Container(
            height: 110,
            width: double.infinity,
            padding: const EdgeInsetsDirectional.fromSTEB(22, 0, 18, 0),
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
                        t('advhome_btn3'),
                        style: const TextStyle(
                          fontSize: 24,
                          height: 1.05,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111111),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        t('advhome_btn3_sub'),
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
        const SizedBox(height: 16),
      ],
    );
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
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.0, 0.15),
                  radius: 0.6,
                  colors: [
                    Color(0xFFD76211),
                    Color(0x00D76211),
                  ],
                  stops: [0.0, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 24),
              child: CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 25),
                  ),
                  SliverToBoxAdapter(
                    child: _buildTopRow(),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 36),
                  ),
                  SliverToBoxAdapter(
                    child: _buildAdvisorGuideBlock(),
                  ),
                  SliverToBoxAdapter(
                    child: _buildHeadlineBlock(),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 20),
                  ),
                  SliverToBoxAdapter(
                    child: _buildCardsBlock(),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 140),
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
