import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

/// Tracks unlocked achievements in SharedPreferences.
class AchievementService {
  AchievementService._();
  static final AchievementService instance = AchievementService._();

  static const _prefix = 'achievement_';

  /// Returns achievement IDs that are unlocked with their unlock timestamps.
  Future<Map<AchievementId, DateTime>> getUnlocked() async {
    final prefs = await SharedPreferences.getInstance();
    final result = <AchievementId, DateTime>{};
    for (final a in AchievementId.values) {
      final ts = prefs.getInt('$_prefix${a.name}');
      if (ts != null) {
        result[a] = DateTime.fromMillisecondsSinceEpoch(ts);
      }
    }
    return result;
  }

  Future<void> _unlock(AchievementId id) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getInt('$_prefix${id.name}') != null) return; // already unlocked
    await prefs.setInt(
        '$_prefix${id.name}', DateTime.now().millisecondsSinceEpoch);
  }

  /// Check conditions after a session. Returns newly unlocked achievements.
  Future<List<Achievement>> checkNewAchievements(
    SessionRecord record,
    HistoryStats stats,
    int divisionCorrectTotal,
  ) async {
    final unlocked = await getUnlocked();
    final newlyUnlocked = <Achievement>[];

    Future<void> check(AchievementId id, bool condition) async {
      if (!unlocked.containsKey(id) && condition) {
        await _unlock(id);
        newlyUnlocked
            .add(Achievement.all.firstWhere((a) => a.id == id));
      }
    }

    // First Steps — at least 1 session
    await check(AchievementId.firstSteps, stats.totalSessions >= 1);

    // Perfect Score — 100% first try this session
    await check(
      AchievementId.perfectScore,
      record.problemCount > 0 &&
          record.correctFirstTry == record.problemCount,
    );

    // Speed Demon — 10+ problems in under 120 seconds
    await check(
      AchievementId.speedDemon,
      record.problemCount >= 10 && record.durationSeconds < 120,
    );

    // Persistence — 10 total sessions
    await check(AchievementId.persistence, stats.totalSessions >= 10);

    // Math Explorer — used all 4 operations
    await check(
      AchievementId.mathExplorer,
      stats.operationsUsed.length >= 4,
    );

    // Century Club — 100 total problems
    await check(AchievementId.centuryClub, stats.totalProblems >= 100);

    // Streak Master — 3+ current streak
    await check(AchievementId.streakMaster, stats.currentStreak >= 3);

    // Division Master — 10 division correct first-try cumulative
    await check(AchievementId.divisionMaster, divisionCorrectTotal >= 10);

    // Hard Mode Hero — hard difficulty, >70% first-try
    await check(
      AchievementId.hardModeHero,
      record.difficulty == Difficulty.hard &&
          record.problemCount > 0 &&
          (record.correctFirstTry / record.problemCount) > 0.7,
    );

    // Thousand Club — 1000 total XP
    await check(AchievementId.thousandClub, stats.totalXP >= 1000);

    return newlyUnlocked;
  }

  /// Get progress info for cumulative achievements.
  Future<Map<AchievementId, (int current, int target)>> getProgress(
      HistoryStats stats, int divisionCorrect) async {
    return {
      AchievementId.persistence: (stats.totalSessions, 10),
      AchievementId.centuryClub: (stats.totalProblems, 100),
      AchievementId.streakMaster: (stats.currentStreak, 3),
      AchievementId.divisionMaster: (divisionCorrect, 10),
      AchievementId.thousandClub: (stats.totalXP, 1000),
    };
  }
}
