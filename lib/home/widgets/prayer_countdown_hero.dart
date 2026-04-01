import 'dart:math' as math;
import 'package:flutter/material.dart';

class PrayerCountdownHero extends StatelessWidget {
  const PrayerCountdownHero({
    super.key,
    required this.nextPrayerName,
    required this.statusText,
    required this.remainingText,
    required this.reverseProgress,
  });

  final String nextPrayerName;
  final String statusText;
  final String remainingText;
  final double reverseProgress;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        _CountdownRing(
          value: reverseProgress,
          timeText: remainingText,
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'left until',
                textAlign: TextAlign.start,
                style: TextStyle(
                  color: Color(0xFFB8BDC5),
                  fontSize: 17,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  nextPrayerName,
                  textAlign: TextAlign.start,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 66,
                    fontWeight: FontWeight.w900,
                    height: 0.95,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                statusText,
                textAlign: TextAlign.start,
                style: const TextStyle(
                  color: Color(0xFFA8F51C),
                  fontSize: 18,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CountdownRing extends StatelessWidget {
  const _CountdownRing({
    required this.value,
    required this.timeText,
  });

  final double value;
  final String timeText;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          CustomPaint(
            size: const Size(150, 150),
            painter: _CountdownRingPainter(progress: value),
          ),
          Container(
            width: 86,
            height: 86,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF08111B),
            ),
          ),
          Text(
            timeText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountdownRingPainter extends CustomPainter {
  const _CountdownRingPainter({
    required this.progress,
  });

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const double strokeWidth = 22;
    final Rect rect = Offset.zero & size;

    final Paint trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF365943);

    final Paint progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: math.pi * 3 / 2,
        colors: <Color>[
          Color(0xFFA8F51C),
          Color(0xFF9CF116),
          Color(0xFFA8F51C),
        ],
      ).createShader(rect);

    const double startAngle = -math.pi / 2;
    final double sweepAngle = math.pi * 2 * progress.clamp(0.0, 1.0);

    final Rect arcRect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );

    canvas.drawArc(
      arcRect,
      0,
      math.pi * 2,
      false,
      trackPaint,
    );

    canvas.drawArc(
      arcRect,
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CountdownRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
