import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/models.dart';
import '../services/achievement_service.dart';
import '../services/history_service.dart';
import '../theme/app_theme.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  Map<AchievementId, DateTime>? _unlocked;
  Map<AchievementId, (int, int)>? _progress;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final unlocked = await AchievementService.instance.getUnlocked();
    final stats = await HistoryService.instance.getTotalStats();
    final divCorrect = await HistoryService.instance.getDivisionCorrect();
    final progress =
        await AchievementService.instance.getProgress(stats, divCorrect);
    setState(() {
      _unlocked = unlocked;
      _progress = progress;
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
                      'Achievements',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const Spacer(),
                    if (_unlocked != null)
                      Text(
                        '${_unlocked!.length}/${Achievement.all.length}',
                        style: GoogleFonts.comicNeue(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: _unlocked == null
                    ? const Center(child: CircularProgressIndicator())
                    : _buildGrid(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 240,
        childAspectRatio: 0.85,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: Achievement.all.length,
      itemBuilder: (context, index) {
        final achievement = Achievement.all[index];
        final isUnlocked = _unlocked!.containsKey(achievement.id);
        final progress = _progress?[achievement.id];

        return _AchievementCard(
          achievement: achievement,
          isUnlocked: isUnlocked,
          unlockDate: _unlocked![achievement.id],
          progress: progress,
        );
      },
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final bool isUnlocked;
  final DateTime? unlockDate;
  final (int, int)? progress;

  const _AchievementCard({
    required this.achievement,
    required this.isUnlocked,
    this.unlockDate,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnlocked
            ? AppTheme.surface
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(
          color: isUnlocked
              ? achievement.color.withValues(alpha: 0.5)
              : Colors.grey.shade200,
          width: isUnlocked ? 2 : 1,
        ),
        boxShadow: [
          if (isUnlocked)
            BoxShadow(
              color: achievement.color.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isUnlocked
                  ? achievement.color.withValues(alpha: 0.15)
                  : Colors.grey.shade200,
            ),
            child: Icon(
              achievement.icon,
              size: 28,
              color: isUnlocked ? achievement.color : Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 10),
          // Name
          Text(
            achievement.name,
            textAlign: TextAlign.center,
            style: GoogleFonts.comicNeue(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isUnlocked ? AppTheme.textPrimary : Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 4),
          // Description or hint
          Text(
            isUnlocked ? achievement.description : achievement.hint,
            textAlign: TextAlign.center,
            style: GoogleFonts.comicNeue(
              fontSize: 12,
              color: isUnlocked ? AppTheme.textSecondary : Colors.grey.shade400,
            ),
          ),
          // Progress bar for cumulative achievements
          if (!isUnlocked && progress != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress!.$2 > 0
                    ? (progress!.$1 / progress!.$2).clamp(0.0, 1.0)
                    : 0.0,
                backgroundColor: Colors.grey.shade200,
                valueColor:
                    AlwaysStoppedAnimation(achievement.color.withValues(alpha: 0.5)),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${progress!.$1}/${progress!.$2}',
              style: GoogleFonts.comicNeue(
                fontSize: 11,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
