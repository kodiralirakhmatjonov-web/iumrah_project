import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:iumrah_project/core/localization/translations_store.dart';

class InCarPage extends StatefulWidget {
  const InCarPage({super.key});

  @override
  State<InCarPage> createState() => _InCarPageState();
}

class _InCarPageState extends State<InCarPage> with TickerProviderStateMixin {
  String t(String key) => TranslationsStore.get(key);

  final PageController _brandPager = PageController(viewportFraction: 1.0);
  int _brandIndex = 0;
  Timer? _brandTimer;
  Timer? _tripTicker;

  TravelRouteOption? _selectedRoute;
  DateTime? _tripStartedAt;

  late final AnimationController _radialTextFadeCtrl;
  late final Animation<double> _radialTextFade;
  Timer? _radialTextTimer;
  int _radialTextIndex = 0;

  final List<String> _radialTextKeys = const [
    'incar_radial_text',
    'incar_radial_text1',
    'incar_radial_text3',
  ];

  @override
  void initState() {
    super.initState();

    _radialTextFadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _radialTextFade = CurvedAnimation(
      parent: _radialTextFadeCtrl,
      curve: Curves.easeInOut,
    );

    _radialTextFadeCtrl.value = 1.0;

    _startBrandAutoPager();
    _startRadialTextLoop();
  }

  @override
  void dispose() {
    _brandTimer?.cancel();
    _tripTicker?.cancel();
    _radialTextTimer?.cancel();
    _radialTextFadeCtrl.dispose();
    _brandPager.dispose();
    super.dispose();
  }

  void _startBrandAutoPager() {
    _brandTimer?.cancel();
    _brandTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted || !_brandPager.hasClients) return;
      final next = _brandIndex == 0 ? 1 : 0;
      _brandPager.animateToPage(
        next,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _startRadialTextLoop() {
    _radialTextTimer?.cancel();

    _radialTextTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      if (!mounted) return;

      await _radialTextFadeCtrl.reverse();

      if (!mounted) return;
      setState(() {
        _radialTextIndex = (_radialTextIndex + 1) % _radialTextKeys.length;
      });

      await _radialTextFadeCtrl.forward();
    });
  }

  void _startTrip(TravelRouteOption route) {
    _tripTicker?.cancel();

    setState(() {
      _selectedRoute = route;
      _tripStartedAt = DateTime.now();
    });

    _tripTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  Duration get _elapsed {
    if (_selectedRoute == null || _tripStartedAt == null) {
      return Duration.zero;
    }
    return DateTime.now().difference(_tripStartedAt!);
  }

  double get _tripProgress {
    if (_selectedRoute == null) return 0.0;
    final total = _selectedRoute!.duration.inSeconds;
    if (total <= 0) return 0.0;
    final value = _elapsed.inSeconds / total;
    return value.clamp(0.0, 1.0);
  }

  Duration get _remaining {
    if (_selectedRoute == null) return Duration.zero;
    final remain = _selectedRoute!.duration - _elapsed;
    if (remain.isNegative) return Duration.zero;
    return remain;
  }

  String get _remainingLabel {
    final d = _remaining;
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  Future<void> _openWayModal() async {
    HapticFeedback.lightImpact();

    final result = await showModalBottomSheet<TravelRouteOption>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (_) => _WayModalSheet(
        options: const [
          TravelRouteOption(
            titleKey: 'route_medina_makkah',
            groupKey: 'incar_by_car',
            duration: Duration(hours: 5),
          ),
          TravelRouteOption(
            titleKey: 'route_jeddah_makkah',
            groupKey: 'incar_by_car',
            duration: Duration(hours: 1),
          ),
          TravelRouteOption(
            titleKey: 'route_medina_makkah',
            groupKey: 'incar_by_train',
            duration: Duration(hours: 2),
          ),
          TravelRouteOption(
            titleKey: 'route_jeddah_makkah',
            groupKey: 'incar_by_train',
            duration: Duration(hours: 1),
          ),
        ],
        t: t,
      ),
    );

    if (result != null) {
      _startTrip(result);
    }
  }

  Widget _dot(bool active) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: active
            ? Colors.white.withOpacity(0.95)
            : Colors.white.withOpacity(0.25),
        shape: BoxShape.circle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progressFillWidth = 250.0 * _tripProgress;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF050505),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 12),
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
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 312,
                    height: 110,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                14,
                                12,
                                14,
                                12,
                              ),
                              child: PageView(
                                controller: _brandPager,
                                physics: const BouncingScrollPhysics(),
                                onPageChanged: (value) {
                                  setState(() => _brandIndex = value);
                                },
                                children: [
                                  _BrandCard(
                                    title: 'Uber',
                                    subtitle: t('uber_text'),
                                    leading: Image.asset(
                                      'assets/images/uber_image.png',
                                      height: 90,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  _BrandCard(
                                    title: 'Saudi Official Taxi',
                                    subtitle: t('uber_text'),
                                    leading: Image.asset(
                                      'assets/images/sauditaxi_image.png',
                                      height: 90,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 8,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _dot(_brandIndex == 0),
                                  const SizedBox(width: 8),
                                  _dot(_brandIndex == 1),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _dot(_brandIndex == 0),
                      const SizedBox(width: 8),
                      _dot(_brandIndex == 1),
                    ],
                  ),
                  const SizedBox(height: 18),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 250,
                      child: Image.asset(
                        'assets/images/incar_image.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1F1A),
                      borderRadius: BorderRadius.circular(44),
                      border: Border.all(
                        color: const Color(0xFF00AC03),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(137, 30, 120, 63),
                            borderRadius: BorderRadius.circular(38),
                          ),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Row(
                                  children: [
                                    Container(
                                      width: 108,
                                      height: 56,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF1E783F),
                                        borderRadius: BorderRadius.horizontal(
                                          left: Radius.circular(38),
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: const Icon(
                                        CupertinoIcons.arrow_right,
                                        size: 40,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const Expanded(child: SizedBox()),
                                  ],
                                ),
                              ),
                              PositionedDirectional(
                                end: 22,
                                top: 0,
                                bottom: 0,
                                child: Center(
                                  child: Text(
                                    _remainingLabel,
                                    style: const TextStyle(
                                      fontFamily: 'Lato',
                                      fontWeight: FontWeight.w800,
                                      fontSize: 28,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: _openWayModal,
                          child: Container(
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              color: const Color(0xFF13C764),
                              borderRadius: BorderRadius.circular(38),
                            ),
                            alignment: AlignmentDirectional.center,
                            child: Text(
                              t('way_btn'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Lato',
                                fontWeight: FontWeight.w800,
                                fontSize: 24,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsetsDirectional.fromSTEB(18, 24, 18, 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF050505),
                      borderRadius: BorderRadius.circular(34),
                      border: Border.all(
                        color: const Color(0xFF9A4DFF),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          t('advisor_title'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Lato',
                            fontWeight: FontWeight.w800,
                            fontSize: 26,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          t('advisor_subtitle'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Lato',
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 420,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        IgnorePointer(
                          child: Container(
                            width: 420,
                            height: 420,
                            decoration: const BoxDecoration(
                              gradient: RadialGradient(
                                center: Alignment.center,
                                radius: 0.5,
                                colors: [
                                  Color(0xFF8600AC),
                                  Color(0x008600AC),
                                ],
                                stops: [0.0, 1.0],
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 38),
                          child: FadeTransition(
                            opacity: _radialTextFade,
                            child: Text(
                              t(_radialTextKeys[_radialTextIndex]),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Lato',
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                height: 1.25,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  /// 4 BUTTONS
                  Padding(
                    padding:
                        const EdgeInsetsDirectional.symmetric(horizontal: 10),
                    child: Column(
                      children: [
                        /// ROW 1
                        Row(
                          children: [
                            /// TALBIYA
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                },
                                child: Container(
                                  height: 120,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(50),
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        'assets/icons/talbea.png',
                                        height: 50,
                                      ),
                                      const SizedBox(height: 10),
                                      const Text(
                                        "Talbiya",
                                        style: TextStyle(
                                          fontFamily: 'Montserrat',
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 16),

                            /// VIBE
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  HapticFeedback.mediumImpact();

                                  /// TODO: play nachit audio
                                },
                                child: Container(
                                  height: 120,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF8B00FF),
                                        Color.fromARGB(255, 73, 0, 137),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        'assets/icons/magic.png',
                                        height: 40,
                                      ),
                                      const SizedBox(height: 10),
                                      const Text(
                                        "Vibe",
                                        style: TextStyle(
                                          fontFamily: 'Montserrat',
                                          fontSize: 32,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        /// ROW 2
                        Row(
                          children: [
                            /// GUIDE
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  HapticFeedback.mediumImpact();

                                  /// TODO load in-car audio by lang
                                },
                                child: Container(
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00C43B),
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        'assets/icons/magic1.png',
                                        height: 40,
                                      ),
                                      const SizedBox(height: 10),
                                      const Text(
                                        "Guide",
                                        style: TextStyle(
                                          fontFamily: 'Montserrat',
                                          fontSize: 26,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 16),

                            /// ETHICS
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                },
                                child: Container(
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4C2208),
                                    borderRadius: BorderRadius.circular(50),
                                    border: Border.all(
                                      color: const Color(0xFFB06C2A),
                                      width: 2,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(
                                        Icons.check_circle_outline,
                                        size: 36,
                                        color: Colors.white,
                                      ),
                                      SizedBox(height: 10),
                                      Text(
                                        "Этика\nпути умры",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontFamily: 'Montserrat',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandCard extends StatelessWidget {
  final Widget leading;
  final String title;
  final String subtitle;

  const _BrandCard({
    required this.leading,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.start,
                  style: const TextStyle(
                    fontFamily: 'Lato',
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  textAlign: TextAlign.start,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Lato',
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                    height: 1.15,
                    color: Colors.black.withOpacity(0.65),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WayModalSheet extends StatelessWidget {
  final List<TravelRouteOption> options;
  final String Function(String key) t;

  const _WayModalSheet({
    required this.options,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final byCar = options.where((e) => e.groupKey == 'incar_by_car').toList();
    final byTrain =
        options.where((e) => e.groupKey == 'incar_by_train').toList();

    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF070707),
          borderRadius: BorderRadiusDirectional.only(
            topStart: Radius.circular(40),
            topEnd: Radius.circular(40),
          ),
        ),
        padding: const EdgeInsetsDirectional.fromSTEB(20, 18, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: 74,
              height: 74,
              decoration: const BoxDecoration(
                color: Color(0xFF8BFF62),
                shape: BoxShape.circle,
              ),
              alignment: AlignmentDirectional.center,
              child: const Icon(
                CupertinoIcons.arrow_right,
                size: 34,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF7BFF55),
                borderRadius: BorderRadius.circular(26),
              ),
              child: Stack(
                children: [
                  PositionedDirectional(
                    start: 6,
                    top: 6,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFF8BFF62),
                        shape: BoxShape.circle,
                      ),
                      alignment: AlignmentDirectional.center,
                      child: const Icon(
                        CupertinoIcons.arrow_right,
                        size: 22,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const PositionedDirectional(
                    end: 16,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Text(
                        '4:29',
                        style: TextStyle(
                          fontFamily: 'Lato',
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              t('incar_question'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Lato',
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                t('incar_by_car'),
                textAlign: TextAlign.start,
                style: const TextStyle(
                  fontFamily: 'Lato',
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 14),
            ...byCar.map(
              (e) => Padding(
                padding: const EdgeInsetsDirectional.only(bottom: 12),
                child: _RouteOptionTile(
                  label: t(e.titleKey),
                  onTap: () => Navigator.pop(context, e),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                t('incar_by_train'),
                textAlign: TextAlign.start,
                style: const TextStyle(
                  fontFamily: 'Lato',
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 14),
            ...byTrain.map(
              (e) => Padding(
                padding: const EdgeInsetsDirectional.only(bottom: 12),
                child: _RouteOptionTile(
                  label: t(e.titleKey),
                  onTap: () => Navigator.pop(context, e),
                ),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4E1F),
                  borderRadius: BorderRadius.circular(30),
                ),
                alignment: AlignmentDirectional.center,
                child: Text(
                  t('close_btn'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Lato',
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              t('way_modal_footer'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Lato',
                fontWeight: FontWeight.w500,
                fontSize: 12,
                color: Colors.white.withOpacity(0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteOptionTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _RouteOptionTile({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final parts = label.split('|');
    final left = parts.isNotEmpty ? parts.first.trim() : label;
    final right = parts.length > 1 ? parts.last.trim() : '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 58,
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(29),
        ),
        child: Row(
          children: [
            Text(
              left,
              textAlign: TextAlign.start,
              style: const TextStyle(
                fontFamily: 'Lato',
                fontWeight: FontWeight.w500,
                fontSize: 16,
                color: Color(0xFF3A3A4A),
              ),
            ),
            const Spacer(),
            Expanded(
              child: Container(
                height: 1,
                color: Colors.black.withOpacity(0.08),
              ),
            ),
            const Spacer(),
            Text(
              right,
              textAlign: TextAlign.start,
              style: const TextStyle(
                fontFamily: 'Lato',
                fontWeight: FontWeight.w500,
                fontSize: 18,
                color: Color(0xFF3A3A4A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TravelRouteOption {
  final String titleKey;
  final String groupKey;
  final Duration duration;

  const TravelRouteOption({
    required this.titleKey,
    required this.groupKey,
    required this.duration,
  });
}
