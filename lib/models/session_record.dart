import 'dart:convert';
import 'models.dart';

class SessionRecord {
  final DateTime date;
  final Difficulty difficulty;
  final List<OperationType> operations;
  final int problemCount;
  final int correctFirstTry;
  final int correctRetry;
  final int skipped;
  final int durationSeconds;
  final int xpEarned;

  const SessionRecord({
    required this.date,
    required this.difficulty,
    required this.operations,
    required this.problemCount,
    required this.correctFirstTry,
    required this.correctRetry,
    required this.skipped,
    required this.durationSeconds,
    required this.xpEarned,
  });

  int get totalCorrect => correctFirstTry + correctRetry;
  double get accuracy => problemCount > 0 ? totalCorrect / problemCount : 0.0;

  /// Calculate XP: 10 per first-try, 5 per retry, 0 for skipped.
  static int calculateXP(int firstTry, int retry) => firstTry * 10 + retry * 5;

  factory SessionRecord.fromResult(
      SessionResult result, Difficulty difficulty, List<OperationType> ops) {
    final xp = calculateXP(
        result.correctOnFirstTryCount, result.correctOnRetryCount);
    return SessionRecord(
      date: DateTime.now(),
      difficulty: difficulty,
      operations: ops,
      problemCount: result.totalProblems,
      correctFirstTry: result.correctOnFirstTryCount,
      correctRetry: result.correctOnRetryCount,
      skipped: result.skippedCount,
      durationSeconds: result.duration.inSeconds,
      xpEarned: xp,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'difficulty': difficulty.index,
        'operations': operations.map((o) => o.index).toList(),
        'problemCount': problemCount,
        'correctFirstTry': correctFirstTry,
        'correctRetry': correctRetry,
        'skipped': skipped,
        'durationSeconds': durationSeconds,
        'xpEarned': xpEarned,
      };

  factory SessionRecord.fromJson(Map<String, dynamic> json) => SessionRecord(
        date: DateTime.parse(json['date'] as String),
        difficulty: Difficulty.values[json['difficulty'] as int],
        operations: (json['operations'] as List)
            .map((i) => OperationType.values[i as int])
            .toList(),
        problemCount: json['problemCount'] as int,
        correctFirstTry: json['correctFirstTry'] as int,
        correctRetry: json['correctRetry'] as int,
        skipped: json['skipped'] as int,
        durationSeconds: json['durationSeconds'] as int,
        xpEarned: json['xpEarned'] as int,
      );

  static String encodeList(List<SessionRecord> records) =>
      jsonEncode(records.map((r) => r.toJson()).toList());

  static List<SessionRecord> decodeList(String json) =>
      (jsonDecode(json) as List)
          .map((e) => SessionRecord.fromJson(e as Map<String, dynamic>))
          .toList();
}

class HistoryStats {
  final int totalSessions;
  final int totalProblems;
  final int totalCorrect;
  final int totalXP;
  final int currentStreak;
  final int bestStreak;
  final Set<OperationType> operationsUsed;

  const HistoryStats({
    this.totalSessions = 0,
    this.totalProblems = 0,
    this.totalCorrect = 0,
    this.totalXP = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.operationsUsed = const {},
  });

  int get level => totalXP ~/ 500;
  double get levelProgress => (totalXP % 500) / 500.0;
  double get overallAccuracy =>
      totalProblems > 0 ? totalCorrect / totalProblems : 0.0;
}
