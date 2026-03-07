import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Controller to trigger confetti bursts programmatically.
class ConfettiController extends ChangeNotifier {
  int _fireCount = 0;
  int get fireCount => _fireCount;

  /// Fire a confetti burst.
  void fire() {
    _fireCount++;
    notifyListeners();
  }
}

/// A confetti burst overlay. Place inside a [Stack] on top of screen content.
///
/// Fires colorful particles that burst upward from center-bottom, arc outward
/// with gravity, rotate, and fade out over ~2 seconds.
class ConfettiOverlay extends StatefulWidget {
  final ConfettiController controller;

  const ConfettiOverlay({super.key, required this.controller});

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with TickerProviderStateMixin {
  final List<_ConfettiBurst> _bursts = [];

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onFire);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onFire);
    for (final burst in _bursts) {
      burst.controller.dispose();
    }
    super.dispose();
  }

  void _onFire() {
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    final burst = _ConfettiBurst(
      controller: controller,
      particles: _generateParticles(),
    );

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          setState(() {
            _bursts.remove(burst);
          });
          controller.dispose();
        }
      }
    });

    setState(() {
      _bursts.add(burst);
    });

    controller.forward();
  }

  List<_Particle> _generateParticles() {
    final rng = math.Random();
    const colors = [
      Color(0xFF4A90D9), // blue
      Color(0xFFFF9F43), // orange
      Color(0xFFFFD93D), // yellow
      Color(0xFF6BCB77), // green
      Color(0xFFFF6B6B), // red
      Color(0xFFAB83FF), // purple
      Color(0xFF45D0FF), // cyan
      Color(0xFFFF69B4), // pink
    ];

    return List.generate(60, (_) {
      // Burst angle: mostly upward (-30° to -150° from horizontal)
      final angle = -math.pi / 6 - rng.nextDouble() * (2 * math.pi / 3);
      final speed = 300.0 + rng.nextDouble() * 500.0;

      return _Particle(
        color: colors[rng.nextInt(colors.length)],
        isCircle: rng.nextBool(),
        size: 4.0 + rng.nextDouble() * 8.0,
        velocityX: math.cos(angle) * speed * (rng.nextBool() ? 1 : -1),
        velocityY: math.sin(angle) * speed,
        rotation: rng.nextDouble() * math.pi * 2,
        rotationSpeed: (rng.nextDouble() - 0.5) * 12.0,
        offsetX: (rng.nextDouble() - 0.5) * 40,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_bursts.isEmpty) return const SizedBox.shrink();

    return IgnorePointer(
      child: Stack(
        children: _bursts.map((burst) {
          return AnimatedBuilder(
            animation: burst.controller,
            builder: (context, _) {
              return CustomPaint(
                size: Size.infinite,
                painter: _ConfettiPainter(
                  particles: burst.particles,
                  progress: burst.controller.value,
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}

class _ConfettiBurst {
  final AnimationController controller;
  final List<_Particle> particles;

  _ConfettiBurst({required this.controller, required this.particles});
}

class _Particle {
  final Color color;
  final bool isCircle;
  final double size;
  final double velocityX;
  final double velocityY;
  final double rotation;
  final double rotationSpeed;
  final double offsetX;

  const _Particle({
    required this.color,
    required this.isCircle,
    required this.size,
    required this.velocityX,
    required this.velocityY,
    required this.rotation,
    required this.rotationSpeed,
    required this.offsetX,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  static const double _gravity = 900.0; // pixels/s²

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final originX = size.width / 2;
    final originY = size.height * 0.85;
    final t = progress * 2.0; // time in seconds (duration is 2s)
    // Fade out in last 30%
    final opacity = progress > 0.7
        ? ((1.0 - progress) / 0.3).clamp(0.0, 1.0)
        : 1.0;

    for (final p in particles) {
      final x = originX + p.offsetX + p.velocityX * t;
      final y = originY + p.velocityY * t + 0.5 * _gravity * t * t;
      final rot = p.rotation + p.rotationSpeed * t;

      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rot);

      if (p.isCircle) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * 0.6,
          ),
          paint,
        );
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) =>
      old.progress != progress;
}
