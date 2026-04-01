import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iumrah_project/core/profiles/profile_store.dart';
import 'package:iumrah_project/features/advisor/haram_status_page.dart';
import 'package:iumrah_project/hajj/main_home_page.dart';
import 'package:iumrah_project/home/incar_page.dart';
import 'package:iumrah_project/home/modal/ihram_zapret_modal.dart';
import 'package:iumrah_project/home/plus_page.dart';
import 'package:iumrah_project/home/profile_page.dart';
import 'package:iumrah_project/home/tawaf_page.dart';
import 'package:iumrah_project/home/umrah_start..dart';

import 'package:iumrah_project/core/navigation/premium_route.dart';
import 'package:iumrah_project/core/localization/translations_store.dart';
import 'package:iumrah_project/core/ui/app_ui.dart';
import 'package:iumrah_project/home/widgets/floating_nav_bar.dart';

class InUmrahPage extends StatefulWidget {
  const InUmrahPage({super.key});

  @override
  State<InUmrahPage> createState() => _InUmrahPageState();
}

class _InUmrahPageState extends State<InUmrahPage>
    with TickerProviderStateMixin {
  late final AnimationController _glowCtrl;
  late final Animation<double> _glowOpacity;

  static const Duration _fadeDur = Duration(seconds: 3);
  static const Duration _holdDur = Duration(seconds: 25);

  final ScrollController _scrollController = ScrollController();

  bool _textVisible = true;
  int _phase = 0;

  Timer? _cycleTimer;

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

  String _avatarAsset(String key) {
    if (key.startsWith('male_')) {
      return 'assets/profile/avatars/male/$key.png';
    }
    if (key.startsWith('female_')) {
      return 'assets/profile/avatars/female/$key.png';
    }
    return 'assets/profile/avatars/male/male_01.png';
  }

  @override
  void dispose() {
    _cycleTimer?.cancel();
    _glowCtrl.dispose();
    _scrollController.dispose();
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
            t('home1_title'),
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
            t('home1_sub'),
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
            t('home1_title2'),
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
            t('home1_title2_sub'),
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
            t('home1_title3'),
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
            t('home1_title3_sub'),
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
          'assets/images/iumrah_logo1.png',
          height: 80,
        ),
        const Spacer(),
        SizedBox(
          height: 80,
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: PremiumTap(
              onTap: () {
                Navigator.of(context).push(
                  PremiumRoute.push(const ProfilePage()),
                );
              },
              child: ValueListenableBuilder<ProfileData>(
                valueListenable: ProfileStore.notifier,
                builder: (context, profile, _) {
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Container(
                      key: ValueKey(profile.avatarKey),
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          _avatarAsset(profile.avatarKey),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
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

  Widget _buildCardsBlock() {
    return Column(
      children: [
        PremiumTap(
          onTap: () {
            Navigator.of(context).push(
              PremiumRoute.push(const PlusPage()),
            );
          },
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
                  Color.fromARGB(255, 255, 134, 6),
                  Color.fromARGB(255, 88, 38, 0),
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
                        t('home_btnp'),
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
        const SizedBox(height: 17),
        _premiumCard(
          onTap: () {
            Navigator.of(context).push(
              PremiumRoute.push(const UmrahStartPage()),
            );
          },
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
                  child: Text(
                    t('home1_btn'),
                    style: const TextStyle(
                      fontSize: 26,
                      height: 1.1,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF04D718),
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
        ///////nafl tawaf ////////
        _premiumCard(
          onTap: () => _go(const TawafPage()),
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
                        t('home1_title3_sub'),
                        style: const TextStyle(
                          fontSize: 24,
                          height: 1.05,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111111),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        t('home1_btn3_sub'),
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

        ///////haram status////////

        _premiumCard(
          onTap: () => _go(const HaramStatusPage()),
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
                        t('home1_btn2'),
                        style: const TextStyle(
                          fontSize: 22,
                          height: 1.05,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111111),
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
        _premiumCard(
          ///////ihram zapret//////////////////////
          onTap: () {
            showIhramRestrictionsModal(context);
          },
          child: Container(
            height: 110,
            width: double.infinity,
            padding: const EdgeInsetsDirectional.fromSTEB(22, 0, 18, 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              color: const Color.fromARGB(255, 221, 0, 0),
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
                        t('home1_btn3'),
                        style: const TextStyle(
                          fontSize: 24,
                          height: 1.05,
                          fontWeight: FontWeight.w800,
                          color: Color.fromARGB(255, 255, 255, 255),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        t('home1_btn3_sub'),
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.2,
                          fontWeight: FontWeight.w400,
                          color: Color.fromARGB(255, 255, 255, 255),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 50,
                  color:
                      const Color.fromARGB(255, 255, 255, 255).withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        /////////////exit umrah card///////////
        _premiumCard(
          onTap: () => _go(const MainHomePage()),
          child: Container(
            height: 90,
            width: double.infinity,
            padding: const EdgeInsetsDirectional.fromSTEB(22, 0, 18, 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              color: const Color.fromARGB(255, 27, 27, 27),
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
                        t('home_btn5'),
                        style: const TextStyle(
                          fontSize: 24,
                          height: 1.05,
                          fontWeight: FontWeight.w800,
                          color: Color.fromARGB(255, 209, 209, 209),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        t('home_btn5_sub'),
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
                  Icons.chevron_left_rounded,
                  size: 50,
                  color: const Color.fromARGB(255, 255, 255, 255)
                      .withOpacity(0.15),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
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
                  center: Alignment(0.0, -0.4),
                  radius: 0.6,
                  colors: [
                    Color(0xFF04D718),
                    Color(0x00737373),
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
          const FloatingNavBar(currentIndex: 1),
        ],
      ),
    );
  }
}
