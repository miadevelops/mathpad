import 'dart:math';

import '../models/models.dart';

/// Result of validating a user's digit-by-digit answer.
class AnswerValidation {
  /// Per-digit correctness, indexed by digit position (0 = ones).
  final Map<int, bool> digitCorrectness;

  /// Whether the entire answer is correct.
  final bool isCorrect;

  const AnswerValidation({
    required this.digitCorrectness,
    required this.isCorrect,
  });
}

/// Represents a single digit of the expected answer.
class AnswerDigit {
  /// Position index (0 = ones, 1 = tens, …).
  final int position;

  /// The digit value (0-9), or -1 to indicate a negative sign.
  final int value;

  /// Whether this entry represents the negative sign rather than a digit.
  final bool isNegativeSign;

  const AnswerDigit({
    required this.position,
    required this.value,
    this.isNegativeSign = false,
  });
}

class MathEngine {
  final Random _random;

  MathEngine({Random? random}) : _random = random ?? Random();

  // ---------------------------------------------------------------------------
  // Problem generation
  // ---------------------------------------------------------------------------

  /// Generate a single [MathProblem] based on [config].
  MathProblem generateProblem(SessionConfig config) {
    final op = config.selectedOperations[
        _random.nextInt(config.selectedOperations.length)];

    switch (op) {
      case OperationType.addition:
        return _generateAddition(config.difficulty);
      case OperationType.subtraction:
        return _generateSubtraction(config.difficulty);
      case OperationType.multiplication:
        return _generateMultiplication(config.difficulty);
      case OperationType.division:
        return _generateDivision(config.difficulty);
    }
  }

  /// Generate a full session of problems, avoiding exact duplicates.
  List<MathProblem> generateSession(SessionConfig config) {
    final problems = <MathProblem>[];
    final seen = <String>{};
    int attempts = 0;
    final maxAttempts = config.operationCount * 20;

    while (problems.length < config.operationCount && attempts < maxAttempts) {
      attempts++;
      final p = generateProblem(config);
      final key = '${p.operand1}|${p.operation}|${p.operand2}';
      if (seen.add(key)) {
        problems.add(p);
      }
    }

    // If we couldn't fill without duplicates (unlikely), pad with whatever.
    while (problems.length < config.operationCount) {
      problems.add(generateProblem(config));
    }

    return problems;
  }

  // ---------------------------------------------------------------------------
  // Validation
  // ---------------------------------------------------------------------------

  /// Validate user-entered digits against [problem]'s expected answer.
  ///
  /// [digitAnswers] is indexed by digit position (0 = ones, 1 = tens, …).
  /// A null entry means the user left that box blank (treated as wrong).
  AnswerValidation validateAnswer(
    MathProblem problem,
    List<int?> digitAnswers,
  ) {
    final expectedDigits = extractAnswerDigits(problem.expectedAnswer);
    final digitCorrectness = <int, bool>{};
    bool allCorrect = true;

    for (final ad in expectedDigits) {
      if (ad.isNegativeSign) continue; // negative sign handled separately
      final idx = ad.position;
      final userDigit = idx < digitAnswers.length ? digitAnswers[idx] : null;
      final correct = userDigit == ad.value;
      digitCorrectness[idx] = correct;
      if (!correct) allCorrect = false;
    }

    // If answer is negative, check that the user indicated negative somehow.
    // For now, we consider overall correctness based on digit match only.

    return AnswerValidation(
      digitCorrectness: digitCorrectness,
      isCorrect: allCorrect,
    );
  }

  // ---------------------------------------------------------------------------
  // Answer digit extraction
  // ---------------------------------------------------------------------------

  /// Break [answer] into individual digits with positions.
  ///
  /// Position 0 = ones, 1 = tens, etc.
  /// Negative answers include an [AnswerDigit] with [isNegativeSign] = true.
  List<AnswerDigit> extractAnswerDigits(int answer) {
    final digits = <AnswerDigit>[];
    final isNegative = answer < 0;
    int absVal = answer.abs();

    if (absVal == 0) {
      digits.add(const AnswerDigit(position: 0, value: 0));
    } else {
      int pos = 0;
      while (absVal > 0) {
        digits.add(AnswerDigit(position: pos, value: absVal % 10));
        absVal ~/= 10;
        pos++;
      }
    }

    if (isNegative) {
      digits.add(AnswerDigit(
        position: digits.length,
        value: -1,
        isNegativeSign: true,
      ));
    }

    return digits;
  }

  // ---------------------------------------------------------------------------
  // Carry / borrow detection
  // ---------------------------------------------------------------------------

  /// Detect carry columns for addition: column indices where sum >= 10.
  List<int> detectCarries(int a, int b) {
    final carries = <int>[];
    int carry = 0;
    int col = 0;
    int va = a;
    int vb = b;

    while (va > 0 || vb > 0 || carry > 0) {
      final sum = (va % 10) + (vb % 10) + carry;
      if (sum >= 10) {
        carries.add(col);
        carry = 1;
      } else {
        carry = 0;
      }
      va ~/= 10;
      vb ~/= 10;
      col++;
    }

    return carries;
  }

  /// Detect carry values for multiplication (a × b, where b is single-digit).
  /// Returns a map of column index → carry value produced by that column.
  /// E.g. 47 × 8: column 0 produces carry 5, column 1 produces carry 3.
  Map<int, int> detectMultiplicationCarries(int a, int b) {
    final carries = <int, int>{};
    int carry = 0;
    int col = 0;
    int va = a.abs();
    final vb = b.abs();

    while (va > 0 || carry > 0) {
      final product = (va % 10) * vb + carry;
      final newCarry = product ~/ 10;
      if (newCarry > 0) {
        carries[col] = newCarry;
      }
      carry = newCarry;
      va ~/= 10;
      col++;
    }

    return carries;
  }

  /// Detect borrow columns for subtraction (a - b).
  List<int> detectBorrows(int a, int b) {
    final borrows = <int>[];
    int va = a.abs();
    int vb = b.abs();

    // Ensure we're computing borrows for the larger - smaller direction.
    if (va < vb) {
      final tmp = va;
      va = vb;
      vb = tmp;
    }

    int borrow = 0;
    int col = 0;

    while (va > 0 || vb > 0) {
      final digitA = va % 10;
      final digitB = vb % 10;
      final diff = digitA - digitB - borrow;
      if (diff < 0) {
        borrows.add(col);
        borrow = 1;
      } else {
        borrow = 0;
      }
      va ~/= 10;
      vb ~/= 10;
      col++;
    }

    return borrows;
  }

  // ---------------------------------------------------------------------------
  // Private generation helpers
  // ---------------------------------------------------------------------------

  MathProblem _generateAddition(Difficulty difficulty) {
    final range = _operandRange(difficulty);
    final a = _randInRange(range.min, range.max);
    final b = _randInRange(range.min, range.max);
    final answer = a + b;
    return MathProblem(
      operand1: a,
      operand2: b,
      operation: OperationType.addition,
      expectedAnswer: answer,
      carryDigits: detectCarries(a, b),
    );
  }

  MathProblem _generateSubtraction(Difficulty difficulty) {
    final range = _operandRange(difficulty);
    int a = _randInRange(range.min, range.max);
    int b = _randInRange(range.min, range.max);

    // For easy/medium, ensure non-negative result.
    if (difficulty != Difficulty.hard && a < b) {
      final tmp = a;
      a = b;
      b = tmp;
    }

    final answer = a - b;
    return MathProblem(
      operand1: a,
      operand2: b,
      operation: OperationType.subtraction,
      expectedAnswer: answer,
      borrowDigits: detectBorrows(a, b),
    );
  }

  MathProblem _generateMultiplication(Difficulty difficulty) {
    late int a;
    late int b;

    switch (difficulty) {
      case Difficulty.easy:
        a = _randInRange(1, 9);
        b = _randInRange(1, 9);
        break;
      case Difficulty.medium:
        a = _randInRange(1, 20);
        b = _randInRange(1, 9);
        break;
      case Difficulty.hard:
        a = _randInRange(1, 99);
        b = _randInRange(1, 9);
        break;
    }

    return MathProblem(
      operand1: a,
      operand2: b,
      operation: OperationType.multiplication,
      expectedAnswer: a * b,
      carryValues: detectMultiplicationCarries(a, b),
    );
  }

  MathProblem _generateDivision(Difficulty difficulty) {
    late int divisor;
    late int answer;

    switch (difficulty) {
      case Difficulty.easy:
        divisor = _randInRange(2, 9);
        answer = _randInRange(1, 9);
        break;
      case Difficulty.medium:
        divisor = _randInRange(2, 20);
        answer = _randInRange(1, 99);
        break;
      case Difficulty.hard:
        divisor = _randInRange(2, 50);
        answer = _randInRange(1, 999);
        break;
    }

    final dividend = answer * divisor;
    return MathProblem(
      operand1: dividend,
      operand2: divisor,
      operation: OperationType.division,
      expectedAnswer: answer,
    );
  }

  // ---------------------------------------------------------------------------
  // Utilities
  // ---------------------------------------------------------------------------

  _OperandRange _operandRange(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return const _OperandRange(1, 9);
      case Difficulty.medium:
        return const _OperandRange(1, 99);
      case Difficulty.hard:
        return const _OperandRange(1, 999);
    }
  }

  int _randInRange(int min, int max) => min + _random.nextInt(max - min + 1);
}

class _OperandRange {
  final int min;
  final int max;
  const _OperandRange(this.min, this.max);
}
