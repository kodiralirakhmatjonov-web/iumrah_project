import 'dart:math';
import 'package:flutter/material.dart';

class GreenWave extends StatefulWidget {
  const GreenWave({super.key, required bool expanded});

  @override
  State<GreenWave> createState() => _GreenWaveState();
}

class _GreenWaveState extends State<GreenWave>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          return CustomPaint(
            painter: _GreenWavePainter(_controller.value),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _GreenWavePainter extends CustomPainter {
  final double progress;
  _GreenWavePainter(this.progress);

  final List<Color> greens = const [
    Color(0xFF39FF14), // neon lime
    Color(0xFF2EFF00),
    Color(0xFF00FF66),
    Color(0xFF00E65C),
    Color(0xFF00CC52),
    Color(0xFF00B347),
    Color(0xFF00993D),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height * 0.45;
    final centerX = size.width / 2;

    // 🔥 боковое затемнение
    final vignette = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          Colors.black.withOpacity(0.6),
        ],
        stops: const [0.6, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final randomOffsets = [0.0, 1.3, 2.7, 0.8, 3.9, 5.2, 4.1, 6.0, 2.1, 4.8];

    for (int i = 0; i < greens.length; i++) {
      final paint = Paint()
        ..color = greens[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1; // тоньше линии

      final path = Path();

      final baseAmplitude = 25 + (i * 4);
      final frequency = 1.4 + (i * 0.07);
      final phaseShift = randomOffsets[i];

      for (double x = 0; x <= size.width; x++) {
        // 🔥 ослабление по краям
        final distanceFromCenter = 1 - ((x - centerX).abs() / centerX);

        final edgeFade = distanceFromCenter.clamp(0.0, 1.0);

        // 🔥 центральный всплеск
        final centerBoost = exp(
          -pow((x - centerX) / (size.width * 0.10), 2),
        );

        final dynamicAmplitude = baseAmplitude * edgeFade + (centerBoost * 40);

        final y = centerY +
            sin(
                  (x / size.width * 2 * pi * frequency) +
                      (progress * 2 * pi * 1.6) + // чуть быстрее
                      phaseShift,
                ) *
                dynamicAmplitude;

        if (x == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      canvas.drawPath(path, paint);
    }

    // затемнение по краям
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      vignette,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
