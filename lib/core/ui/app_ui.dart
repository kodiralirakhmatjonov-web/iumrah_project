import 'package:flutter/material.dart';

/// Premium design system tokens for iUmrah Project.
/// Source: your confirmed numbers.
class AppUI {
  // ====== Layout / Spacing ======
  static const double padScreenX = 24; // screen horizontal padding
  static const double padBase = 16;
  static const double gapMain = 40; // main vertical gaps between blocks
  static const double padCard = 20;
  static const double gapField = 12;
  static const double padH = 24;
  static const double gap = 40;
  static const double cardPad = 20;

  static const double hButton = 60;

  static const double rCard = 50;
  static const double rButton = 50;

  // colors (оставь твои реальные, ниже пример)
  static const bg = Color(0xFFE6E6EF);
  static const black = Color(0xFF000000);
  static const softBlack = Color(0xFF1A1A1A);
  static const white = Color(0xFFFFFFFF);

  // advisor colors (у тебя они уже есть)
  static const advisorA = Color(0xFFB354BE);
  static const advisorB = Color(0xFF610084);

  // ====== Radii ======
  static const double rField = 30;
  static const double rImageCard = 50;

  // ====== Heights ======
  static const double hField = 60;
  static const double hSwitcher = 65;
  static const double hAdvisor = 75;

  // ====== Typography ======
  static const String font = 'Lato';
  static const double h1 = 32;
  static const double title = 20;
  static const double cardTitle = 20;
  static const double body = 14;

  // ====== Colors ======
  static const Color textSoft = Color(0xFF111111); // softer than pure black
  static const Color disabledGrey = Color(0xFFBDBDBD);
  static const Color fieldFill = Color(0xFFEAEAEA);
  static const Color errorRed = Color(0xFFD32F2F);

  static Color? get background => null; // non-neon red

  // ====== Shadows (soft iOS-like, use selectively) ======
  static List<BoxShadow> softShadow({
    double opacity = 0.10,
    double blur = 18,
    double spread = 0,
    Offset offset = const Offset(0, 10),
  }) {
    return [
      BoxShadow(
        color: Colors.black.withOpacity(opacity),
        blurRadius: blur,
        spreadRadius: spread,
        offset: offset,
      ),
    ];
  }
}

/// Premium press effect (iOS-like): subtle scale + opacity.
/// Wrap any tappable widget with PremiumTap.
class PremiumTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final Duration duration;

  const PremiumTap({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius,
    this.duration = const Duration(milliseconds: 140),
  });

  @override
  State<PremiumTap> createState() => _PremiumTapState();
}

class _PremiumTapState extends State<PremiumTap> {
  bool _down = false;

  void _set(bool v) {
    if (_down == v) return;
    setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? widget.onTap : null,
      onTapDown: enabled ? (_) => _set(true) : null,
      onTapCancel: enabled ? () => _set(false) : null,
      onTapUp: enabled ? (_) => _set(false) : null,
      child: AnimatedScale(
        scale: _down ? 0.985 : 1,
        duration: widget.duration,
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: _down ? 0.92 : 1,
          duration: widget.duration,
          curve: Curves.easeOutCubic,
          child: ClipRRect(
            borderRadius: widget.borderRadius ?? BorderRadius.zero,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Helper: advisor gradient text
class GradientText extends StatelessWidget {
  final String text;
  final TextStyle style;

  const GradientText(this.text, {super.key, required this.style});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (rect) => const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [AppUI.advisorA, AppUI.advisorB],
      ).createShader(rect),
      child: Text(
        text,
        style: style.copyWith(color: Colors.white),
      ),
    );
  }
}
