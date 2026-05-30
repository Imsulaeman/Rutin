import 'dart:math' as math;

import 'package:flutter/material.dart';

class WaterProgressWidget extends StatelessWidget {
  const WaterProgressWidget({
    super.key,
    required this.current,
    required this.goal,
    this.trackColor,
    this.fillColor,
    this.size = 180,
    this.strokeWidth = 16,
    this.center,
  });

  final int current;
  final int goal;
  final Color? trackColor;
  final Color? fillColor;
  final double size;
  final double strokeWidth;

  /// Optional widget shown at the ring's center. Defaults to the
  /// glass-count label when null.
  final Widget? center;

  @override
  Widget build(BuildContext context) {
    final progress = goal > 0 ? (current / goal).clamp(0.0, 1.0) : 0.0;
    final cs = Theme.of(context).colorScheme;
    final resolvedTrack = trackColor ?? cs.primaryContainer;
    final resolvedFill  = fillColor  ?? cs.primary;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(size, size),
                painter: _ArcPainter(
                  progress: value,
                  trackColor: resolvedTrack,
                  fillColor: resolvedFill,
                  strokeWidth: strokeWidth,
                ),
              ),
              center ??
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$current',
                        style: TextStyle(
                          fontSize: size * 0.244,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.5,
                          color: resolvedFill,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'dari $goal gelas',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
            ],
          ),
        );
      },
    );
  }
}

class _ArcPainter extends CustomPainter {
  const _ArcPainter({
    required this.progress,
    required this.trackColor,
    required this.fillColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color trackColor;
  final Color fillColor;
  final double strokeWidth;

  static const _startAngle = math.pi * 0.75;
  static const _sweepAngle = math.pi * 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, _startAngle, _sweepAngle, false, trackPaint);

    if (progress > 0.01) {
      canvas.drawArc(rect, _startAngle, _sweepAngle * progress, false, fillPaint);
    }
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.progress != progress ||
      old.fillColor != fillColor ||
      old.trackColor != trackColor ||
      old.strokeWidth != strokeWidth;
}
