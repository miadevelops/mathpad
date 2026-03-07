import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/confetti_overlay.dart';

class ResultsScreen extends StatefulWidget {
  final SessionResult? result;

  const ResultsScreen({super.key, this.result});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen>
    with TickerProviderStateMixin {
  late final ConfettiController _confettiController;

  // Staggered entrance animations
  late final AnimationController _entranceController;
  late final List<Animation<double>> _fadeAnimations;
  late final List<Animation<Offset>> _slideAnimations;

  // Star animations
  late final AnimationController _starController;

  // Counter animations
  late final AnimationController _counterController;

  @override
  void initState() {
    super.initState();

    _confettiController = ConfettiController();

    // Staggered entrance: 6 elements, 200ms apart, each takes 400ms
    // Total: 200*5 + 400 = 1400ms
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _fadeAnimations = List.generate(6, (i) {
      final start = (i * 0.125).clamp(0.0, 1.0);
      final end = (start + 0.25).clamp(0.0, 1.0);
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _entranceController,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });

    _slideAnimations = List.generate(6, (i) {
      final start = (i * 0.125).clamp(0.0, 1.0);
      final end = (start + 0.25).clamp(0.0, 1.0);
      return Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _entranceController,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });

    // Star animation: 3 stars, 300ms stagger
    _starController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Counter animation
    _counterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Fire everything after a brief delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _confettiController.fire();
      _entranceController.forward();
      _starController.forward();
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) _counterController.forward();
      });
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _entranceController.dispose();
    _starController.dispose();
    _counterController.dispose();
    super.dispose();
  }

  int _starCount(SessionResult r) {
    final firstTryRate =
        r.totalProblems > 0 ? r.correctOnFirstTryCount / r.totalProblems : 0.0;
    if (firstTryRate > 0.9) return 3;
    if (firstTryRate > 0.6) return 2;
    return 1;
  }

  String _encouragingMessage(SessionResult r) {
    final firstTryRate =
        r.totalProblems > 0 ? r.correctOnFirstTryCount / r.totalProblems : 0.0;
    if (firstTryRate >= 1.0) return "Amazing! You're a math genius!";
    if (firstTryRate > 0.8) return 'Great job! Keep practicing!';
    if (firstTryRate > 0.5) return "Good effort! You're getting better!";
    return 'Practice makes perfect! Try again!';
  }

  String _formatDuration(Duration d) {
    final mins = d.inMinutes;
    final secs = d.inSeconds % 60;
    return '${mins}m ${secs}s';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.result == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('No results available',
                  style: Theme.of(context).textTheme.displayMedium),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text('Back to Menu'),
              ),
            ],
          ),
        ),
      );
    }

    final r = widget.result!;
    final stars = _starCount(r);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE8F0FE), AppTheme.background, Color(0xFFFFF4E6)],
          ),
        ),
        child: Stack(
          children: [
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Stars
                          _buildElement(0, _buildStars(stars)),
                          const SizedBox(height: 24),

                          // Encouraging message
                          _buildElement(
                            1,
                            Text(
                              _encouragingMessage(r),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.comicNeue(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                          ),
                          const SizedBox(height: 36),

                          // Stats
                          _buildElement(2, _buildStatRow(
                            icon: Icons.check_circle_rounded,
                            iconColor: AppTheme.successGreen,
                            label: 'correct on first try',
                            targetValue: r.correctOnFirstTryCount,
                            total: r.totalProblems,
                            showTotal: true,
                          )),
                          const SizedBox(height: 12),
                          _buildElement(3, _buildStatRow(
                            icon: Icons.refresh_rounded,
                            iconColor: AppTheme.accentOrange,
                            label: 'solved on retry',
                            targetValue: r.correctOnRetryCount,
                          )),
                          const SizedBox(height: 12),
                          _buildElement(4, _buildStatRow(
                            icon: Icons.skip_next_rounded,
                            iconColor: AppTheme.textSecondary,
                            label: 'skipped',
                            targetValue: r.skippedCount,
                          )),
                          const SizedBox(height: 12),
                          _buildElement(4, _buildTimeRow(r.duration)),
                          const SizedBox(height: 48),

                          // Buttons
                          _buildElement(5, _buildButtons()),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Confetti overlay
            Positioned.fill(
              child: ConfettiOverlay(controller: _confettiController),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildElement(int index, Widget child) {
    return FadeTransition(
      opacity: _fadeAnimations[index.clamp(0, 5)],
      child: SlideTransition(
        position: _slideAnimations[index.clamp(0, 5)],
        child: child,
      ),
    );
  }

  Widget _buildStars(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final earned = i < count;
        // Stagger: each star starts 0.25 apart in star controller
        final start = (i * 0.25).clamp(0.0, 1.0);
        final end = (start + 0.5).clamp(0.0, 1.0);
        final scaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _starController,
            curve: Interval(start, end, curve: Curves.elasticOut),
          ),
        );
        final rotateAnim = Tween<double>(begin: -0.3, end: 0.0).animate(
          CurvedAnimation(
            parent: _starController,
            curve: Interval(start, end, curve: Curves.elasticOut),
          ),
        );

        return AnimatedBuilder(
          animation: _starController,
          builder: (_, child) => Transform.scale(
            scale: scaleAnim.value,
            child: Transform.rotate(
              angle: rotateAnim.value,
              child: child,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(
              earned ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 72,
              color: earned ? AppTheme.accentYellow : Colors.grey.shade300,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required int targetValue,
    int? total,
    bool showTotal = false,
  }) {
    return AnimatedBuilder(
      animation: _counterController,
      builder: (_, _) {
        final currentValue =
            (targetValue * _counterController.value).round();
        final valueText = showTotal && total != null
            ? '$currentValue of $total'
            : '$currentValue';
        return Row(
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(width: 12),
            Text(
              valueText,
              style: GoogleFonts.comicNeue(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.comicNeue(
                fontSize: 20,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTimeRow(Duration duration) {
    return Row(
      children: [
        const Icon(Icons.timer_outlined,
            color: AppTheme.primaryBlue, size: 28),
        const SizedBox(width: 12),
        Text(
          'Time: ${_formatDuration(duration)}',
          style: GoogleFonts.comicNeue(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildButtons() {
    return Column(
      children: [
        SizedBox(
          width: 260,
          height: 64,
          child: ElevatedButton(
            onPressed: () => context.go('/config'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentOrange,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
              elevation: 4,
              shadowColor: AppTheme.accentOrange.withValues(alpha: 0.4),
              textStyle: GoogleFonts.comicNeue(
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: const Text('Play Again'),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: 260,
          height: 56,
          child: OutlinedButton(
            onPressed: () => context.go('/'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textSecondary,
              side: const BorderSide(
                  color: AppTheme.textSecondary, width: 2),
              shape: const StadiumBorder(),
              textStyle: GoogleFonts.comicNeue(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: const Text('Home'),
          ),
        ),
      ],
    );
  }
}
