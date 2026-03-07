import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';

class ResultsScreen extends StatelessWidget {
  final SessionResult? result;

  const ResultsScreen({super.key, this.result});

  @override
  Widget build(BuildContext context) {
    if (result == null) {
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

    final r = result!;
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
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Great Job!',
                      style: GoogleFonts.comicNeue(
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _StatRow(
                        label: 'Correct (1st try)',
                        value: '${r.correctOnFirstTryCount}'),
                    _StatRow(
                        label: 'Correct (retry)',
                        value: '${r.correctOnRetryCount}'),
                    _StatRow(
                        label: 'Skipped',
                        value: '${r.skippedCount}'),
                    _StatRow(
                        label: 'Total',
                        value:
                            '${r.totalCorrect} / ${r.totalProblems}'),
                    const SizedBox(height: 16),
                    _StatRow(
                        label: 'Time',
                        value: _formatDuration(r.duration)),
                    const SizedBox(height: 48),
                    ElevatedButton(
                      onPressed: () => context.go('/'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentOrange,
                        minimumSize: const Size(240, 64),
                        textStyle: GoogleFonts.comicNeue(
                            fontSize: 24, fontWeight: FontWeight.w700),
                      ),
                      child: const Text('Play Again'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final mins = d.inMinutes;
    final secs = d.inSeconds % 60;
    return '${mins}m ${secs}s';
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.comicNeue(
                  fontSize: 20, color: AppTheme.textSecondary)),
          Text(value,
              style: GoogleFonts.comicNeue(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
        ],
      ),
    );
  }
}
