import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

/// Persists session history and computes aggregate stats.
class HistoryService {
  HistoryService._();
  static final HistoryService instance = HistoryService._();

  static const _key = 'session_history';
  static const _maxRecords = 100;

  List<SessionRecord>? _cached;

  Future<List<SessionRecord>> getHistory() async {
    if (_cached != null) return _cached!;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      _cached = [];
      return _cached!;
    }
    _cached = SessionRecord.decodeList(raw);
    return _cached!;
  }

  Future<void> saveSession(SessionRecord record) async {
    final history = await getHistory();
    history.insert(0, record);
    // Keep max records
    while (history.length > _maxRecords) {
      history.removeLast();
    }
    _cached = history;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, SessionRecord.encodeList(history));
  }

  Future<HistoryStats> getTotalStats() async {
    final history = await getHistory();
    if (history.isEmpty) return const HistoryStats();

    int totalProblems = 0;
    int totalCorrect = 0;
    int totalXP = 0;
    final opsUsed = <OperationType>{};

    for (final r in history) {
      totalProblems += r.problemCount;
      totalCorrect += r.totalCorrect;
      totalXP += r.xpEarned;
      opsUsed.addAll(r.operations);
    }

    // Calculate streaks (>60% first-try accuracy)
    int currentStreak = 0;
    int bestStreak = 0;
    int streak = 0;

    // History is newest first, walk from oldest
    for (int i = history.length - 1; i >= 0; i--) {
      final r = history[i];
      final firstTryRate =
          r.problemCount > 0 ? r.correctFirstTry / r.problemCount : 0.0;
      if (firstTryRate > 0.6) {
        streak++;
        if (streak > bestStreak) bestStreak = streak;
      } else {
        streak = 0;
      }
    }
    currentStreak = streak;

    return HistoryStats(
      totalSessions: history.length,
      totalProblems: totalProblems,
      totalCorrect: totalCorrect,
      totalXP: totalXP,
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      operationsUsed: opsUsed,
    );
  }

  /// Count of first-try correct for a specific operation type across all sessions.
  /// For simplicity we track cumulative division correct in a separate key.
  Future<int> getDivisionCorrect() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('division_correct') ?? 0;
  }

  Future<void> addDivisionCorrect(int count) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt('division_correct') ?? 0;
    await prefs.setInt('division_correct', current + count);
  }
}
