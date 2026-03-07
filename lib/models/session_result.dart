import 'math_problem.dart';
import 'digit_answer.dart';

class ProblemResult {
  final MathProblem problem;
  final List<DigitAnswer> digitAnswers;
  final bool correctOnFirstTry;
  final bool correctOnRetry;
  final bool skipped;

  const ProblemResult({
    required this.problem,
    this.digitAnswers = const [],
    this.correctOnFirstTry = false,
    this.correctOnRetry = false,
    this.skipped = false,
  });
}

class SessionResult {
  final List<ProblemResult> results;
  final Duration duration;

  const SessionResult({
    required this.results,
    required this.duration,
  });

  int get correctOnFirstTryCount =>
      results.where((r) => r.correctOnFirstTry).length;

  int get correctOnRetryCount =>
      results.where((r) => r.correctOnRetry).length;

  int get skippedCount => results.where((r) => r.skipped).length;

  int get totalCorrect => correctOnFirstTryCount + correctOnRetryCount;

  int get totalProblems => results.length;

  double get accuracy =>
      totalProblems > 0 ? totalCorrect / totalProblems : 0.0;
}
