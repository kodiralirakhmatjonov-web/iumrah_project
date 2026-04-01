import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iumrah_project/core/localization/translations_store.dart';
import 'package:iumrah_project/core/navigation/premium_route.dart';
import 'package:iumrah_project/home/after_umrah_page.dart';
import 'package:iumrah_project/home/widgets/app_header.dart';

class BarbershopPage extends StatefulWidget {
  const BarbershopPage({super.key});

  @override
  State<BarbershopPage> createState() => _BarbershopPageState();
}

class _BarbershopPageState extends State<BarbershopPage>
    with TickerProviderStateMixin {
  // ===== ASSETS =====
  // Если у тебя пути отличаются — поменяй только эти 3 строки.
  static const String _barbershopImage = 'assets/images/barbershop_image.png';
  static const String _barberLogo = 'assets/images/barber_logo.png';
  static const String _globusLogo = 'assets/images/globus_logo.png';

  // ===== COLORS =====
  static const Color _bg = Colors.black;
  static const Color _white = Colors.white;
  static const Color _whiteSoft = Color(0xFFEDEDED);
  static const Color _greenCore = Color(0xFF8DFF18);
  static const Color _greenMid = Color(0xFF70E000);

  // ===== DYNAMIC TEXT TIMING =====
  static const Duration _textHoldDuration = Duration(seconds: 10);
  static const Duration _textFadeOutDuration = Duration(seconds: 1);
  static const Duration _textPauseDuration = Duration(seconds: 1);
  static const Duration _textFadeInDuration = Duration(seconds: 1);

  late final AnimationController _pageController;
  late final AnimationController _glowController;

  bool _textVisible = true;
  double _textOffsetY = 0;
  int _textIndex = 0;

  String _readKey(String key) {
    final raw = TranslationsStore.get(key).trim();

    if (raw.isEmpty) return '';
    if (raw == key) return '';
    if (raw == '[$key]') return '';
    if (raw == '{$key}') return '';
    if (raw == '{{$key}}') return '';

    return raw;
  }

  String t(String key, String fallback) {
    final value = _readKey(key);
    return value.isEmpty ? fallback : value;
  }

  String tFirst(List<String> keys, String fallback) {
    for (final key in keys) {
      final value = _readKey(key);
      if (value.isNotEmpty) return value;
    }
    return fallback;
  }

  List<_DynamicAdviceState> get _dynamicStates => [
        _DynamicAdviceState(
          title: t('barbershop_block1_title', 'Что делать?'),
          body: t(
            'barbershop_text1',
            'Сделать бритьё или укоротить волосы\n'
                '(мужчина — желательно бритьё полностью,\n'
                'женщина — только подстричь чуть-чуть)',
          ),
        ),
        _DynamicAdviceState(
          title: t('barbershop_block10_title', 'СОВЕТЫ'),
          body: t(
            'barbershop_text3',
            'Идите только в официальные барбершопы.\n'
                'Не брейтесь у случайных людей на улице.\n'
                'Проверьте, что лезвие новое и одноразовое.\n'
                'Для женщин — стричь хотя бы кончик волос.',
          ),
        ),
      ];

  @override
  void initState() {
    super.initState();

    _pageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    _pageController.forward();
    _runTextLoop();
  }

  Future<void> _runTextLoop() async {
    while (mounted) {
      await Future.delayed(_textHoldDuration);
      if (!mounted) return;

      setState(() {
        _textVisible = false;
        _textOffsetY = -0.03;
      });

      await Future.delayed(_textFadeOutDuration);
      if (!mounted) return;

      await Future.delayed(_textPauseDuration);
      if (!mounted) return;

      setState(() {
        _textIndex = (_textIndex + 1) % _dynamicStates.length;
        _textOffsetY = 0.03;
      });

      await Future.delayed(const Duration(milliseconds: 16));
      if (!mounted) return;

      setState(() {
        _textVisible = true;
        _textOffsetY = 0;
      });

      await Future.delayed(_textFadeInDuration);
      if (!mounted) return;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pageOpacity = CurvedAnimation(
      parent: _pageController,
      curve: Curves.easeOutCubic,
    );

    final pageSlide = Tween<Offset>(
      begin: const Offset(0, 0.02),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _pageController,
        curve: Curves.easeOutCubic,
      ),
    );

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: pageOpacity,
          child: SlideTransition(
            position: pageSlide,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(26, 8, 26, 0),
                  child: AppHeader(
                    isDarkBackground: false,
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 12),

                        // ===== HERO IMAGE =====
                        // Без обрезки, во всю ширину, прилипает к бокам.
                        Image.asset(
                          'assets/images/barber_image.png',
                          width: double.infinity,
                          fit: BoxFit.fitWidth,
                          alignment: AlignmentDirectional.topCenter,
                        ),

                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                            24,
                            22,
                            24,
                            28,
                          ),
                          child: Column(
                            children: [
                              // ===== LOGO =====
                              // Без рамки, просто сам логотип.
                              Image.asset(
                                _barberLogo,
                                height: 145,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.content_cut_rounded,
                                  color: Colors.white54,
                                  size: 34,
                                ),
                              ),

                              const SizedBox(height: 18),

                              const Text(
                                '30 DEGREES MAKKAH',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _white,
                                  fontSize: 20,
                                  fontFamily: 'Lato',
                                  fontWeight: FontWeight.w800,
                                  height: 1.0,
                                  letterSpacing: -0.2,
                                ),
                              ),

                              const SizedBox(height: 15),

                              Text(
                                'PREMIUM GROOMING FOR PILGRIMS',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Lato',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  height: 1.15,
                                ),
                              ),

                              const SizedBox(height: 50),

                              // ===== DYNAMIC GREEN GLOW =====
                              _DynamicGlowBlock(
                                controller: _glowController,
                                title: _dynamicStates[_textIndex].title,
                                body: _dynamicStates[_textIndex].body,
                                textVisible: _textVisible,
                                textOffsetY: _textOffsetY,
                              ),

                              const SizedBox(height: 50),

                              _SectionTitle(
                                text: tFirst(
                                  ['barbershop_block2_title'],
                                  'Преимущества',
                                ),
                              ),

                              const SizedBox(height: 12),

                              Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(
                                  t(
                                    'barbershop_text2',
                                    'Расстояние: например 120 м, 2 минуты пешком.\n'
                                        'Расположение: Под часовой башни (Clock Tower Makkah)\n'
                                        'Рейтинг (4.8)',
                                  ),
                                  textAlign: TextAlign.start,
                                  style: const TextStyle(
                                    color: _whiteSoft,
                                    fontSize: 14.8,
                                    fontWeight: FontWeight.w600,
                                    height: 1.42,
                                    letterSpacing: -0.12,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 50),

                              _SectionTitle(
                                text: t(
                                  'barbershop_block8_title',
                                  'Сервис и цена',
                                ),
                              ),

                              const SizedBox(height: 14),

                              _PriceRow(
                                title: t('barbershop_block9_item1', 'Бритва'),
                                price: '20 SAR',
                              ),
                              const SizedBox(height: 10),

                              _PriceRow(
                                title: t(
                                  'barbershop_block9_item2',
                                  'Машинка для стрижки',
                                ),
                                price: '15 SAR',
                              ),
                              const SizedBox(height: 10),

                              _PriceRow(
                                title: t(
                                  'barbershop_block9_item3',
                                  'Ножницы для стрижки',
                                ),
                                price: '20 SAR',
                              ),
                              const SizedBox(height: 10),

                              _PriceRow(
                                title: t(
                                  'barbershop_block9_item4',
                                  'Подравнивание бороды',
                                ),
                                price: '20 SAR',
                              ),

                              const SizedBox(height: 50),

                              SizedBox(
                                width: double.infinity,
                                height: 62,
                                child: _PremiumCompleteButton(
                                  text: tFirst(
                                    [
                                      'complete button',
                                      'barbershop_block11_button'
                                    ],
                                    'ГОТОВО',
                                  ),
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    Navigator.of(context).push(
                                      PremiumRoute.push(
                                        const AfterUmrahPage(),
                                      ),
                                    );
                                  },
                                ),
                              ),

                              const SizedBox(height: 80),

                              Opacity(
                                opacity: 0.35,
                                child: Image.asset(
                                  'assets/images/globus_logo.png',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ],
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
      ),
    );
  }
}

class _DynamicGlowBlock extends StatelessWidget {
  const _DynamicGlowBlock({
    required this.controller,
    required this.title,
    required this.body,
    required this.textVisible,
    required this.textOffsetY,
  });

  final AnimationController controller;
  final String title;
  final String body;
  final bool textVisible;
  final double textOffsetY;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    return SizedBox(
      height: 360,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: AlignmentDirectional.center,
        children: [
          AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              final scale = 0.975 + (controller.value * 0.06);

              return Transform.scale(
                scale: scale,
                child: IgnorePointer(
                    child: OverflowBox(
                  maxWidth: screenWidth * 3, // ← сильно больше экрана
                  maxHeight: 500,
                  child: Container(
                    width: screenWidth * 2.2, // ← вот ключ
                    height: screenWidth * 2.2, // ← делаем КРУГ (равные стороны)
                    decoration: BoxDecoration(
                      shape: BoxShape.circle, // ← ВАЖНО: круг, не овал
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 0.5, // ← плотный центр
                        colors: [
                          Color(0xFF04D718), // ядро
                          Color(0xFF04D718).withOpacity(0.6),
                          Color(0xFF04D718).withOpacity(0.2),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.4, 0.7, 1.0],
                      ),
                    ),
                  ),
                )),
              );
            },
          ),
          AnimatedSlide(
            offset: Offset(0, textOffsetY),
            duration: const Duration(seconds: 1),
            curve: Curves.easeInOutCubic,
            child: AnimatedOpacity(
              opacity: textVisible ? 1 : 0,
              duration: const Duration(seconds: 1),
              curve: Curves.easeInOutCubic,
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _BarbershopPageState._white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.08,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      body,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _BarbershopPageState._white,
                        fontSize: 16.4,
                        fontWeight: FontWeight.w700,
                        height: 1.34,
                        letterSpacing: -0.14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Text(
        text,
        textAlign: TextAlign.start,
        style: const TextStyle(
          color: _BarbershopPageState._white,
          fontSize: 34,
          fontWeight: FontWeight.w800,
          height: 1.0,
          letterSpacing: -0.9,
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.title,
    required this.price,
  });

  final String title;
  final String price;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.start,
            style: const TextStyle(
              color: _BarbershopPageState._whiteSoft,
              fontSize: 17,
              fontWeight: FontWeight.w600,
              height: 1.0,
              letterSpacing: -0.9,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Text(
          price,
          textAlign: TextAlign.end,
          style: const TextStyle(
            color: _BarbershopPageState._white,
            fontSize: 15.7,
            fontWeight: FontWeight.w800,
            height: 1.15,
            letterSpacing: -0.12,
          ),
        ),
      ],
    );
  }
}

class _PremiumCompleteButton extends StatefulWidget {
  const _PremiumCompleteButton({
    required this.text,
    required this.onTap,
  });

  final String text;
  final VoidCallback onTap;

  @override
  State<_PremiumCompleteButton> createState() => _PremiumCompleteButtonState();
}

class _PremiumCompleteButtonState extends State<_PremiumCompleteButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 120),
          opacity: _pressed ? 0.92 : 1,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.16),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            alignment: AlignmentDirectional.center,
            child: Text(
              widget.text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                height: 1.0,
                letterSpacing: -0.9,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DynamicAdviceState {
  final String title;
  final String body;

  const _DynamicAdviceState({
    required this.title,
    required this.body,
  });
}
