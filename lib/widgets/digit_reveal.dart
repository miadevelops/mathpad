import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Result state for coloring the revealed digit.
enum DigitResult { neutral, correct, incorrect }

/// Animates from hand-drawn ink strokes to a typed digit.
///
/// Phase 1: ink strokes visible.
/// Phase 2: strokes fade out while typed digit scales in with a bounce.
class DigitReveal extends StatefulWidget {
  /// The strokes to render as ink.
  final List<List<Offset>> strokes;

  /// The recognised digit to reveal.
  final int digit;

  /// Correctness — drives the digit color.
  final DigitResult result;

  /// Stroke width used when rendering ink.
  final double strokeWidth;

  /// Stroke color for ink.
  final Color strokeColor;

  /// Total animation duration.
  final Duration duration;

  /// Called when the reveal animation completes.
  final VoidCallback? onComplete;

  const DigitReveal({
    super.key,
    required this.strokes,
    required this.digit,
    this.result = DigitResult.neutral,
    this.strokeWidth = 8.0,
    this.strokeColor = const Color(0xFF2D3436),
    this.duration = const Duration(milliseconds: 600),
    this.onComplete,
  });

  @override
  State<DigitReveal> createState() => _DigitRevealState();
}

class _DigitRevealState extends State<DigitReveal>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _inkOpacity;
  late Animation<double> _digitOpacity;
  late Animation<double> _digitScale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    // Ink fades out in the first 60% of the animation.
    _inkOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    // Digit fades in from 30%-80%.
    _digitOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.8, curve: Curves.easeIn),
      ),
    );

    // Digit scales from 0.6 → 1.0 with a slight overshoot (bounce).
    _digitScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.elasticOut),
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _digitColor {
    switch (widget.result) {
      case DigitResult.correct:
        return AppTheme.successGreen;
      case DigitResult.incorrect:
        return AppTheme.errorRed;
      case DigitResult.neutral:
        return AppTheme.textPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: [
            // Ink layer
            Positioned.fill(
              child: Opacity(
                opacity: _inkOpacity.value,
                child: CustomPaint(
                  painter: _StrokePainter(
                    strokes: widget.strokes,
                    strokeWidth: widget.strokeWidth,
                    strokeColor: widget.strokeColor,
                  ),
                ),
              ),
            ),

            // Typed digit layer
            Positioned.fill(
              child: Center(
                child: Opacity(
                  opacity: _digitOpacity.value,
                  child: Transform.scale(
                    scale: _digitScale.value,
                    child: Text(
                      '${widget.digit}',
                      style: Theme.of(context)
                          .textTheme
                          .displayLarge
                          ?.copyWith(
                            color: _digitColor,
                            fontSize: 56,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Stroke painter (reused for the ink layer) ──────────────

class _StrokePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final double strokeWidth;
  final Color strokeColor;

  _StrokePainter({
    required this.strokes,
    required this.strokeWidth,
    required this.strokeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = strokeColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;
      if (stroke.length == 1) {
        canvas.drawCircle(
          stroke.first,
          strokeWidth / 2,
          paint..style = PaintingStyle.fill,
        );
        paint.style = PaintingStyle.stroke;
        continue;
      }

      final path = ui.Path();
      path.moveTo(stroke.first.dx, stroke.first.dy);
      for (int i = 1; i < stroke.length; i++) {
        if (i < stroke.length - 1) {
          final mid = Offset(
            (stroke[i].dx + stroke[i + 1].dx) / 2,
            (stroke[i].dy + stroke[i + 1].dy) / 2,
          );
          path.quadraticBezierTo(
            stroke[i].dx, stroke[i].dy,
            mid.dx, mid.dy,
          );
        } else {
          path.lineTo(stroke[i].dx, stroke[i].dy);
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StrokePainter old) => true;
}
