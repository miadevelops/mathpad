import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _bounceScale;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _bounceScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.12), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.12, end: 0.95), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE8F0FE),
              AppTheme.background,
              Color(0xFFFFF4E6),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Scattered math symbols
            const _MathSymbolsBackground(),

            // Main content
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Bouncing title
                  AnimatedBuilder(
                    animation: _bounceScale,
                    builder: (context, child) => Transform.scale(
                      scale: _bounceScale.value,
                      child: child,
                    ),
                    child: Text(
                      'MathPad',
                      style: GoogleFonts.comicNeue(
                        fontSize: 72,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryBlue,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedBuilder(
                    animation: _fadeIn,
                    builder: (context, child) => Opacity(
                      opacity: _fadeIn.value,
                      child: child,
                    ),
                    child: Text(
                      'Practice makes perfect!',
                      style: GoogleFonts.comicNeue(
                        fontSize: 24,
                        fontWeight: FontWeight.w400,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 64),

                  // START button
                  FadeTransition(
                    opacity: _fadeIn,
                    child: _StartButton(
                      onPressed: () => context.go('/config'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Start Button ──────────────────────────────────────────
class _StartButton extends StatefulWidget {
  final VoidCallback onPressed;
  const _StartButton({required this.onPressed});

  @override
  State<_StartButton> createState() => _StartButtonState();
}

class _StartButtonState extends State<_StartButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
      lowerBound: 0.97,
      upperBound: 1.03,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) => Transform.scale(
        scale: _pulse.value,
        child: child,
      ),
      child: SizedBox(
        width: 280,
        height: 80,
        child: ElevatedButton(
          onPressed: widget.onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accentOrange,
            foregroundColor: Colors.white,
            shape: const StadiumBorder(),
            elevation: 4,
            shadowColor: AppTheme.accentOrange.withValues(alpha: 0.4),
            textStyle: GoogleFonts.comicNeue(
              fontSize: 32,
              fontWeight: FontWeight.w700,
            ),
          ),
          child: const Text('START'),
        ),
      ),
    );
  }
}

// ── Background symbols ────────────────────────────────────
class _MathSymbolsBackground extends StatelessWidget {
  const _MathSymbolsBackground();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final rng = math.Random(42); // deterministic layout
    const symbols = [
      '+', '−', '×', '÷', '=',
      '1', '2', '3', '4', '5', '6', '7', '8', '9', '0',
      '?', '%',
    ];

    return IgnorePointer(
      child: Stack(
        children: List.generate(28, (i) {
          final symbol = symbols[i % symbols.length];
          final x = rng.nextDouble() * size.width;
          final y = rng.nextDouble() * size.height;
          final rotation = (rng.nextDouble() - 0.5) * 0.6;
          final fontSize = 24.0 + rng.nextDouble() * 28;

          return Positioned(
            left: x,
            top: y,
            child: Transform.rotate(
              angle: rotation,
              child: Text(
                symbol,
                style: GoogleFonts.comicNeue(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryBlue.withValues(alpha: 0.07),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
