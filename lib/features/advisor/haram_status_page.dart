import 'package:flutter/material.dart';
import 'package:iumrah_project/core/localization/translations_store.dart';
import 'package:iumrah_project/home/widgets/app_header.dart';

class HaramStatusPage extends StatefulWidget {
  const HaramStatusPage({super.key});

  @override
  State<HaramStatusPage> createState() => _HaramStatusPageState();
}

class _HaramStatusPageState extends State<HaramStatusPage>
    with TickerProviderStateMixin {
  static const Color _pageBg = Color(0xFF191919);
  static const Color _trackColor = Color(0xFF2A2A2A);
  static const Color _glowColor = Color(0xFFD72804);

  static const Duration _textHoldDuration = Duration(seconds: 10);
  static const Duration _textFadeOutDuration = Duration(seconds: 1);
  static const Duration _textPauseDuration = Duration(seconds: 1);
  static const Duration _textFadeInDuration = Duration(seconds: 1);

  late final AnimationController _pageController;
  late final AnimationController _barsController;
  late final AnimationController _glowController;

  bool _textVisible = true;
  double _textOffsetY = 0;
  int _textIndex = 0;

  String t(String key, String fallback) {
    final value = TranslationsStore.get(key);
    if (value.trim().isEmpty || value == key) return fallback;
    return value;
  }

  List<String> get _messages => [
        t(
          'haram status text',
          'В Рамадан\nперегруженность высокая\nбудь те осторожны !',
        ),
        t(
          'haram status text 2',
          'После 22:00\nнагрузка ниже\nэто более спокойное время',
        ),
      ];

  final List<_HaramStatusItem> _items = const [
    _HaramStatusItem(
      label: '4:00 - 7:00',
      progress: 0.78,
      color: Color.fromARGB(255, 255, 30, 0),
    ),
    _HaramStatusItem(
      label: '7:00 - 11:00',
      progress: 0.25,
      color: Color(0xFFABFF00),
    ),
    _HaramStatusItem(
      label: '11:00 - 14:00',
      progress: 0.46,
      color: Color(0xFFFFD400),
    ),
    _HaramStatusItem(
      label: '15:00 - 16:00',
      progress: 0.60,
      color: Color(0xFFFFA300),
    ),
    _HaramStatusItem(
      label: '17:00 - 18:00',
      progress: 0.70,
      color: Color(0xFFFF6A00),
    ),
    _HaramStatusItem(
      label: '18:00 - 21:00',
      progress: 0.82,
      color: Color.fromARGB(255, 255, 21, 0),
    ),
    _HaramStatusItem(
      label: '22:00 - 02:00',
      progress: 0.34,
      color: Color(0xFF9FFF00),
    ),
  ];

  @override
  void initState() {
    super.initState();

    _pageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _barsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);

    _pageController.forward();

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _barsController.forward();
    });

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
        _textIndex = (_textIndex + 1) % _messages.length;
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
    _barsController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(
      parent: _pageController,
      curve: Curves.easeOutCubic,
    );

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 23, 23, 23),
      body: SafeArea(
        child: FadeTransition(
          opacity: fade,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsetsDirectional.fromSTEB(24, 8, 24, 0),
                child: AppHeader(
                  isDarkBackground: false,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(24, 0, 24, 0),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 200,
                        child: Stack(
                          alignment: AlignmentDirectional.center,
                          children: [
                            AnimatedSlide(
                              offset: Offset(0, _textOffsetY),
                              duration: const Duration(seconds: 1),
                              curve: Curves.easeInOutCubic,
                              child: AnimatedOpacity(
                                opacity: _textVisible ? 1 : 0,
                                duration: const Duration(seconds: 1),
                                curve: Curves.easeInOutCubic,
                                child: Padding(
                                  padding:
                                      const EdgeInsetsDirectional.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Text(
                                    _messages[_textIndex],
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      height: 1.18,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: Column(
                          children: [
                            ...List.generate(
                              _items.length,
                              (index) => Padding(
                                padding: EdgeInsetsDirectional.only(
                                  bottom: index == _items.length - 1 ? 0 : 13,
                                ),
                                child: _HaramStatusBar(
                                  item: _items[index],
                                  index: index,
                                  controller: _barsController,
                                ),
                              ),
                            ),
                            const Spacer(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(24, 10, 24, 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).maybePop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: Text(
                      t('understand button', 'Понятно'),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HaramStatusBar extends StatelessWidget {
  const _HaramStatusBar({
    required this.item,
    required this.index,
    required this.controller,
  });

  final _HaramStatusItem item;
  final int index;
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    final double start = (index * 0.07).clamp(0.0, 0.6);
    final double end = (start + 0.45).clamp(0.0, 1.0);

    final Animation<double> animation = CurvedAnimation(
      parent: controller,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );

    return SizedBox(
      height: 54,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final current = item.progress * animation.value;

          return LayoutBuilder(
            builder: (context, constraints) {
              final fillWidth = constraints.maxWidth * current;

              return Stack(
                alignment: AlignmentDirectional.centerStart,
                children: [
                  Container(
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      color: _HaramStatusPageState._trackColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Container(
                    width: fillWidth,
                    height: 54,
                    decoration: BoxDecoration(
                      color: item.color,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: item.color.withOpacity(0.22),
                          blurRadius: 18,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: Center(
                      child: Text(
                        item.label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _HaramStatusItem {
  final String label;
  final double progress;
  final Color color;

  const _HaramStatusItem({
    required this.label,
    required this.progress,
    required this.color,
  });
}
