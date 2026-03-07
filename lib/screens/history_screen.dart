import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/models.dart';
import '../services/history_service.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<SessionRecord>? _history;
  HistoryStats? _stats;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final history = await HistoryService.instance.getHistory();
    final stats = await HistoryService.instance.getTotalStats();
    setState(() {
      _history = history;
      _stats = stats;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE8F0FE), AppTheme.background],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, size: 32),
                      onPressed: () => context.go('/'),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'History',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _history == null
                    ? const Center(child: CircularProgressIndicator())
                    : _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final stats = _stats!;
    final history = _history!;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Lifetime stats grid
              _StatsGrid(stats: stats),
              const SizedBox(height: 32),

              Text(
                'Recent Sessions',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),

              if (history.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(48),
                    child: Column(
                      children: [
                        Icon(Icons.history,
                            size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'No sessions yet!\nTap START to begin.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.comicNeue(
                            fontSize: 20,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...history.asMap().entries.map((entry) {
                  return _SessionCard(
                    record: entry.value,
                    index: entry.key,
                  );
                }),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final HistoryStats stats;
  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _StatCard(
          icon: Icons.play_circle_outline,
          label: 'Sessions',
          value: '${stats.totalSessions}',
          color: AppTheme.primaryBlue,
        ),
        _StatCard(
          icon: Icons.calculate_outlined,
          label: 'Problems',
          value: '${stats.totalProblems}',
          color: AppTheme.accentOrange,
        ),
        _StatCard(
          icon: Icons.percent,
          label: 'Accuracy',
          value: '${(stats.overallAccuracy * 100).round()}%',
          color: AppTheme.successGreen,
        ),
        _StatCard(
          icon: Icons.star_outline,
          label: 'Total XP',
          value: '${stats.totalXP}',
          color: AppTheme.accentYellow,
        ),
        _StatCard(
          icon: Icons.trending_up,
          label: 'Level',
          value: '${stats.level}',
          color: Color(0xFF9C27B0),
        ),
        _StatCard(
          icon: Icons.local_fire_department,
          label: 'Best Streak',
          value: '${stats.bestStreak}',
          color: Color(0xFFFF5722),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.comicNeue(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.comicNeue(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final SessionRecord record;
  final int index;

  const _SessionCard({required this.record, required this.index});

  static const _diffColors = {
    Difficulty.easy: AppTheme.successGreen,
    Difficulty.medium: AppTheme.accentYellow,
    Difficulty.hard: AppTheme.errorRed,
  };

  @override
  Widget build(BuildContext context) {
    final color = _diffColors[record.difficulty]!;
    final minutes = record.durationSeconds ~/ 60;
    final seconds = record.durationSeconds % 60;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            // Difficulty badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                record.difficulty.label,
                style: GoogleFonts.comicNeue(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Operations
            Row(
              children: record.operations
                  .map((op) => Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Text(op.symbol,
                            style: const TextStyle(fontSize: 18)),
                      ))
                  .toList(),
            ),
            const Spacer(),
            // Score
            Text(
              '${record.totalCorrect}/${record.problemCount}',
              style: GoogleFonts.comicNeue(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(width: 16),
            // Duration
            Text(
              '${minutes}m ${seconds}s',
              style: GoogleFonts.comicNeue(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(width: 12),
            // XP
            Text(
              '+${record.xpEarned}',
              style: GoogleFonts.comicNeue(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.accentYellow,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
