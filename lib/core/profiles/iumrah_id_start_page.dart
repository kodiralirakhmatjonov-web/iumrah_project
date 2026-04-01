import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IumrahIdStartPage extends StatefulWidget {
  const IumrahIdStartPage({super.key});

  @override
  State<IumrahIdStartPage> createState() => _IumrahIdStartPageState();
}

class _IumrahIdStartPageState extends State<IumrahIdStartPage>
    with TickerProviderStateMixin {
  static const String _logoAsset = 'assets/logo.png';

  late final AnimationController _flipController;
  late final AnimationController _glowController;

  bool _cardPressed = false;

  String _name = 'Aisha Miller';
  String _country = 'GERMANY';

  @override
  void initState() {
    super.initState();

    _flipController = AnimationController(
      vsync: this,
      value: 0,
      lowerBound: 0,
      upperBound: 1,
      duration: const Duration(milliseconds: 650),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _loadProfileOffline();
  }

  Future<void> _loadProfileOffline() async {
    final prefs = await SharedPreferences.getInstance();

    final storedName = prefs.getString('profile_name') ??
        prefs.getString('name') ??
        'Aisha Miller';

    final storedCountry = prefs.getString('profile_country') ??
        prefs.getString('country') ??
        'Germany';

    if (!mounted) return;

    setState(() {
      _name = storedName.trim().isEmpty ? 'Aisha Miller' : storedName.trim();
      _country = storedCountry.trim().isEmpty
          ? 'GERMANY'
          : storedCountry.trim().toUpperCase();
    });
  }

  void _setCardPressed(bool value) {
    if (_cardPressed == value) return;
    setState(() {
      _cardPressed = value;
    });
  }

  void _animateToSide(double target, {double velocity = 0}) {
    final simulation = SpringSimulation(
      const SpringDescription(
        mass: 0.95,
        stiffness: 320,
        damping: 26,
      ),
      _flipController.value,
      target,
      velocity,
    );

    _flipController.animateWith(simulation);
  }

  void _toggleCard() {
    HapticFeedback.lightImpact();
    final target = _flipController.value >= 0.5 ? 0.0 : 1.0;
    _animateToSide(target);
  }

  @override
  void dispose() {
    _flipController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          const Positioned.fill(child: _PageBackground()),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double contentWidth = constraints.maxWidth;
                final double contentHeight = constraints.maxHeight;

                final double logoWidth = math.min(contentWidth * 0.60, 236);
                final double cardWidth = math.min(contentWidth - 52, 308);
                final double cardHeight = math.min(cardWidth * 0.58, 182);
                final double buttonWidth = math.min(contentWidth - 64, 304);

                return Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(24, 8, 24, 20),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 118,
                        child: Align(
                          alignment: AlignmentDirectional.bottomCenter,
                          child: _TopLogo(
                            assetPath: _logoAsset,
                            width: logoWidth,
                          ),
                        ),
                      ),
                      const SizedBox(height: 34),
                      Expanded(
                        child: Align(
                          alignment: AlignmentDirectional.topCenter,
                          child: _buildInteractiveCard(cardWidth, cardHeight),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _PremiumPillButton(
                        text: 'Закрыть',
                        width: buttonWidth,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).maybePop();
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveCard(double cardWidth, double cardHeight) {
    final double glowWidth = cardWidth + 72;
    final double glowHeight = cardHeight + 130;

    return SizedBox(
      width: glowWidth,
      height: glowHeight,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapDown: (_) => _setCardPressed(true),
        onTapCancel: () => _setCardPressed(false),
        onTapUp: (_) => _setCardPressed(false),
        onTap: _toggleCard,
        onHorizontalDragStart: (_) {
          _flipController.stop();
          _setCardPressed(false);
        },
        onHorizontalDragUpdate: (details) {
          final delta = (details.primaryDelta ?? 0) / cardWidth;
          _flipController.value =
              (_flipController.value - (delta * 1.15)).clamp(0.0, 1.0);
        },
        onHorizontalDragEnd: (details) {
          final velocity = (details.primaryVelocity ?? 0) / 1000;
          final bool fastSwipe = velocity.abs() > 0.35;

          final double target;
          if (fastSwipe) {
            target = velocity < 0 ? 1.0 : 0.0;
          } else {
            target = _flipController.value >= 0.5 ? 1.0 : 0.0;
          }

          _animateToSide(
            target,
            velocity: -velocity * 0.35,
          );
        },
        child: AnimatedScale(
          scale: _cardPressed ? 0.988 : 1,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          child: Stack(
            alignment: AlignmentDirectional.center,
            clipBehavior: Clip.none,
            children: [
              IgnorePointer(
                child: AnimatedBuilder(
                  animation: _glowController,
                  builder: (context, child) {
                    final double scale =
                        0.988 + (_glowController.value * 0.026);
                    final double opacity =
                        0.88 + (_glowController.value * 0.10);

                    return Transform.scale(
                      scale: scale,
                      child: Opacity(
                        opacity: opacity,
                        child: _CardAura(
                          width: glowWidth,
                          height: glowHeight,
                        ),
                      ),
                    );
                  },
                ),
              ),
              AnimatedBuilder(
                animation: _flipController,
                builder: (context, child) {
                  final double angle = _flipController.value * math.pi;
                  final bool showBack = angle > math.pi / 2;

                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0018)
                      ..rotateY(angle),
                    child: showBack
                        ? Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()..rotateY(math.pi),
                            child: _IdCardBack(
                              width: cardWidth,
                              height: cardHeight,
                            ),
                          )
                        : _IdCardFront(
                            width: cardWidth,
                            height: cardHeight,
                            name: _name,
                            country: _country,
                          ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageBackground extends StatelessWidget {
  const _PageBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: ColoredBox(color: Colors.black),
        ),
        PositionedDirectional(
          top: -110,
          start: -40,
          end: -40,
          child: IgnorePointer(
            child: Container(
              height: 300,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.92),
                  radius: 1.08,
                  colors: [
                    const Color(0xFF2A3E72).withOpacity(0.44),
                    const Color(0xFF16203A).withOpacity(0.22),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.46, 1.0],
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: AlignmentDirectional.topCenter,
                  end: AlignmentDirectional.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.018),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.12),
                  ],
                  stops: const [0.0, 0.18, 0.72, 1.0],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CardAura extends StatelessWidget {
  const _CardAura({
    required this.width,
    required this.height,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF131313),
      body: Stack(children: [
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.0, -0.4),
                radius: 0.6,
                colors: [
                  Color(0x99FFBD07),
                  Color(0x00FFBD07),
                ],
                stops: [0.0, 1.0],
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _TopLogo extends StatelessWidget {
  const _TopLogo({
    required this.assetPath,
    required this.width,
  });

  final String assetPath;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Stack(
        alignment: AlignmentDirectional.center,
        children: [
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Opacity(
              opacity: 0.24,
              child: Image.asset(
                assetPath,
                width: width,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
          Image.asset(
            assetPath,
            width: width,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) {
              return const Text(
                'iumrah\nPROJECT',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  height: 0.92,
                  letterSpacing: -0.5,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _IdCardFront extends StatelessWidget {
  const _IdCardFront({
    required this.width,
    required this.height,
    required this.name,
    required this.country,
  });

  final double width;
  final double height;
  final String name;
  final String country;

  @override
  Widget build(BuildContext context) {
    return _IdCardChrome(
      width: width,
      height: height,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(20, 18, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'iumrah ID',
              textAlign: TextAlign.start,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.35,
                height: 1,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              textAlign: TextAlign.start,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              country,
              textAlign: TextAlign.start,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.18,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IdCardBack extends StatelessWidget {
  const _IdCardBack({
    required this.width,
    required this.height,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return _IdCardChrome(
      width: width,
      height: height,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(20, 18, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'iumrah ID',
              textAlign: TextAlign.start,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.35,
                height: 1,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'powered by iumrah project',
              textAlign: TextAlign.start,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.16,
                height: 1.05,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IdCardChrome extends StatelessWidget {
  const _IdCardChrome({
    required this.width,
    required this.height,
    required this.child,
  });

  final double width;
  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(24);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF020305),
        borderRadius: radius,
        border: Border.all(
          color: const Color(0xFF35F3FF),
          width: 1.7,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF35F3FF).withOpacity(0.14),
            blurRadius: 18,
            spreadRadius: 0.4,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.44),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0xFF030508),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: AlignmentDirectional.topStart,
                      end: AlignmentDirectional.bottomEnd,
                      colors: [
                        Colors.white.withOpacity(0.035),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.34],
                    ),
                  ),
                ),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}

class _PremiumPillButton extends StatefulWidget {
  const _PremiumPillButton({
    required this.text,
    required this.width,
    required this.onTap,
  });

  final String text;
  final double width;
  final VoidCallback onTap;

  @override
  State<_PremiumPillButton> createState() => _PremiumPillButtonState();
}

class _PremiumPillButtonState extends State<_PremiumPillButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.selectionClick();
        setState(() {
          _pressed = true;
        });
      },
      onTapCancel: () {
        setState(() {
          _pressed = false;
        });
      },
      onTapUp: (_) {
        setState(() {
          _pressed = false;
        });
      },
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.988 : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: _pressed ? 0.94 : 1,
          duration: const Duration(milliseconds: 110),
          child: Container(
            width: widget.width,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F6),
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 1),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.20),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            alignment: AlignmentDirectional.center,
            child: Text(
              widget.text,
              textAlign: TextAlign.start,
              style: const TextStyle(
                color: Color(0xFFA7A7AC),
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.15,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
