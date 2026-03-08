import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/models.dart';
import '../services/settings_service.dart';
import '../services/history_service.dart';
import '../theme/app_theme.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen>
    with TickerProviderStateMixin {
  static bool _firstLaunch = true;
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;

  // Per-letter bounce controllers for "MathPad"
  static const _title = 'MathPad';
  late final List<AnimationController> _letterControllers;
  late final List<Animation<double>> _letterBounce;
  late final List<Animation<double>> _letterFade;

  SessionConfig? _config;
  HistoryStats? _stats;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    // Per-letter staggered bounce
    _letterControllers = List.generate(_title.length, (i) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );
    });

    _letterBounce = _letterControllers.map((c) {
      return TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.15), weight: 45),
        TweenSequenceItem(tween: Tween(begin: 1.15, end: 0.90), weight: 20),
        TweenSequenceItem(tween: Tween(begin: 0.90, end: 1.05), weight: 15),
        TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 20),
      ]).animate(CurvedAnimation(parent: c, curve: Curves.easeOut));
    }).toList();

    _letterFade = _letterControllers.map((c) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: c, curve: const Interval(0.0, 0.5)),
      );
    }).toList();

    // Start rest of UI immediately
    _controller.forward();

    // Stagger each letter by 80ms, with 1s delay only on first launch
    final initialDelay = _firstLaunch ? 1000 : 0;
    _firstLaunch = false;

    for (var i = 0; i < _title.length; i++) {
      Future.delayed(Duration(milliseconds: initialDelay + 80 * i), () {
        if (mounted) _letterControllers[i].forward();
      });
    }

    _loadData();
  }

  Future<void> _loadData() async {
    final config = await SettingsService.instance.load();
    final stats = await HistoryService.instance.getTotalStats();
    if (mounted) {
      setState(() {
        _config = config;
        _stats = stats;
      });
    }
  }

  @override
  void dispose() {
    for (final c in _letterControllers) {
      c.dispose();
    }
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
            const _MathSymbolsBackground(),

            // Top-right icons
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 28, left: 16, right: 16, bottom: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.emoji_events_outlined, size: 28),
                      tooltip: 'Achievements',
                      onPressed: () => context.go('/achievements'),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.history, size: 28),
                      tooltip: 'History',
                      onPressed: () => context.go('/history'),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.settings_outlined, size: 28),
                      tooltip: 'Settings',
                      onPressed: () async {
                        await context.push('/settings');
                        // Reload settings when returning
                        _loadData();
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Main content
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Per-letter staggered bounce title
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(_title.length, (i) {
                      return AnimatedBuilder(
                        animation: _letterBounce[i],
                        builder: (context, child) => Opacity(
                          opacity: _letterFade[i].value,
                          child: Transform.scale(
                            scale: _letterBounce[i].value,
                            child: child,
                          ),
                        ),
                        child: Text(
                          _title[i],
                          style: GoogleFonts.comicNeue(
                            fontSize: 72,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryBlue,
                            letterSpacing: 2,
                          ),
                        ),
                      );
                    }),
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

                  // Level display
                  if (_stats != null && _stats!.totalXP > 0) ...[
                    const SizedBox(height: 16),
                    FadeTransition(
                      opacity: _fadeIn,
                      child: _LevelBadge(stats: _stats!),
                    ),
                  ],

                  const SizedBox(height: 48),

                  // START button
                  FadeTransition(
                    opacity: _fadeIn,
                    child: _StartButton(
                      onPressed: () => context.go('/exercise'),
                    ),
                  ),

                  // Current config summary
                  if (_config != null) ...[
                    const SizedBox(height: 20),
                    FadeTransition(
                      opacity: _fadeIn,
                      child: _ConfigSummary(config: _config!),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  final HistoryStats stats;
  const _LevelBadge({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Level ${stats.level}',
          style: GoogleFonts.comicNeue(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppTheme.primaryBlue,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 160,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: stats.levelProgress,
              backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.12),
              valueColor: const AlwaysStoppedAnimation(AppTheme.primaryBlue),
              minHeight: 8,
            ),
          ),
        ),
        if (stats.currentStreak > 0) ...[
          const SizedBox(height: 8),
          Text(
            '${stats.currentStreak} session streak',
            style: GoogleFonts.comicNeue(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.accentOrange,
            ),
          ),
        ],
      ],
    );
  }
}

class _ConfigSummary extends StatelessWidget {
  final SessionConfig config;
  const _ConfigSummary({required this.config});

  @override
  Widget build(BuildContext context) {
    final ops = config.selectedOperations.map((o) => o.symbol).join(' ');
    return Text(
      '${config.difficulty.label}  ·  $ops  ·  ${config.operationCount} problems',
      style: GoogleFonts.comicNeue(
        fontSize: 16,
        color: AppTheme.textSecondary,
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

// ── Background symbols (radial fade + size) ──────────────
class _MathSymbolsBackground extends StatefulWidget {
  const _MathSymbolsBackground();

  @override
  State<_MathSymbolsBackground> createState() =>
      _MathSymbolsBackgroundState();
}

class _MathSymbolsBackgroundState extends State<_MathSymbolsBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final center = Offset(size.width / 2, size.height / 2);
    final maxDist = center.distance;
    final rng = math.Random(42);
    const symbols = [
      '+', '−', '×', '÷', '=',
      '1', '2', '3', '4', '5', '6', '7', '8', '9', '0',
      '?', '%',
    ];

    const pastelColors = [
      Color(0xFF5B8DEF), // blue
      Color(0xFFEF7B5B), // coral / orange
      Color(0xFF6BC98F), // green
      Color(0xFFBB6BD9), // purple
      Color(0xFFE06B9E), // pink
      Color(0xFFE8A84C), // amber
    ];

    // Pre-generate per-symbol random values so they're stable across frames
    final items = List.generate(84, (_) {
      final baseX = rng.nextDouble() * size.width;
      final baseY = rng.nextDouble() * size.height;
      final driftAngle = rng.nextDouble() * 2 * math.pi;
      final driftSpeed = 12.0 + rng.nextDouble() * 20;
      final baseFontSize = 18.0 + rng.nextDouble() * 20;
      final color = pastelColors[rng.nextInt(pastelColors.length)];

      // Compute static radial values from base position (no per-frame layout)
      final dist =
          (Offset(baseX, baseY) - center).distance / maxDist;
      final clampedDist = dist.clamp(0.0, 1.0);
      final alpha = 0.06 + clampedDist * 0.34;
      final fontSize = baseFontSize * (0.5 + clampedDist * 1.8);

      return (
        baseX: baseX,
        baseY: baseY,
        driftAngle: driftAngle,
        driftSpeed: driftSpeed,
        fontSize: fontSize,
        color: color.withValues(alpha: alpha),
      );
    });

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final t = _anim.value;

        return IgnorePointer(
          child: Stack(
            children: List.generate(84, (i) {
              final symbol = symbols[i % symbols.length];
              final item = items[i];

              // Slow sinusoidal drift (paint-only via Transform)
              final drift = math.sin(t * 2 * math.pi) * item.driftSpeed;
              final dx = math.cos(item.driftAngle) * drift;
              final dy = math.sin(item.driftAngle) * drift;

              return Positioned(
                left: item.baseX,
                top: item.baseY,
                child: Transform.translate(
                  offset: Offset(dx, dy),
                  child: Text(
                    symbol,
                    style: GoogleFonts.comicNeue(
                      fontSize: item.fontSize,
                      fontWeight: FontWeight.w700,
                      color: item.color,
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
