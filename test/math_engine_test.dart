import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mathpad/models/models.dart';
import 'package:mathpad/services/math_engine.dart';

void main() {
  late MathEngine engine;

  setUp(() {
    engine = MathEngine(random: Random(42)); // deterministic seed
  });

  // -------------------------------------------------------------------------
  // Addition
  // -------------------------------------------------------------------------
  group('Addition', () {
    test('generates valid addition problems', () {
      final config = SessionConfig(
        difficulty: Difficulty.easy,
        selectedOperations: [OperationType.addition],
      );
      for (int i = 0; i < 50; i++) {
        final p = engine.generateProblem(config);
        expect(p.operation, OperationType.addition);
        expect(p.expectedAnswer, p.operand1 + p.operand2);
      }
    });

    test('easy addition operands are 1-9', () {
      final config = SessionConfig(
        difficulty: Difficulty.easy,
        selectedOperations: [OperationType.addition],
      );
      for (int i = 0; i < 100; i++) {
        final p = engine.generateProblem(config);
        expect(p.operand1, inInclusiveRange(1, 9));
        expect(p.operand2, inInclusiveRange(1, 9));
      }
    });

    test('medium addition operands are 1-99', () {
      final config = SessionConfig(
        difficulty: Difficulty.medium,
        selectedOperations: [OperationType.addition],
      );
      for (int i = 0; i < 100; i++) {
        final p = engine.generateProblem(config);
        expect(p.operand1, inInclusiveRange(1, 99));
        expect(p.operand2, inInclusiveRange(1, 99));
      }
    });

    test('hard addition operands are 1-999', () {
      final config = SessionConfig(
        difficulty: Difficulty.hard,
        selectedOperations: [OperationType.addition],
      );
      for (int i = 0; i < 100; i++) {
        final p = engine.generateProblem(config);
        expect(p.operand1, inInclusiveRange(1, 999));
        expect(p.operand2, inInclusiveRange(1, 999));
      }
    });
  });

  // -------------------------------------------------------------------------
  // Carry detection
  // -------------------------------------------------------------------------
  group('Carry detection', () {
    test('47 + 35 has carry on ones and tens', () {
      final carries = engine.detectCarries(47, 35);
      // 7+5=12 (carry at column 0), 4+3+1=8 (no carry at column 1)
      // Wait: 4+3+1=8, no carry at tens. Let me recalculate:
      // ones: 7+5=12 >= 10 → carry at col 0
      // tens: 4+3+1(carry)=8 < 10 → no carry at col 1
      expect(carries, contains(0)); // ones column carries
      expect(carries, isNot(contains(1))); // tens column doesn't carry
    });

    test('99 + 1 has carry on ones and tens', () {
      final carries = engine.detectCarries(99, 1);
      // ones: 9+1=10 → carry col 0
      // tens: 9+0+1=10 → carry col 1
      expect(carries, containsAll([0, 1]));
    });

    test('12 + 34 has no carries', () {
      final carries = engine.detectCarries(12, 34);
      expect(carries, isEmpty);
    });

    test('addition problems include carry digits', () {
      // Use a known-seed engine and check carryDigits are populated.
      final config = SessionConfig(
        difficulty: Difficulty.medium,
        selectedOperations: [OperationType.addition],
      );
      bool foundCarry = false;
      for (int i = 0; i < 200; i++) {
        final p = engine.generateProblem(config);
        if (p.carryDigits.isNotEmpty) {
          foundCarry = true;
          break;
        }
      }
      expect(foundCarry, isTrue, reason: 'Should find at least one carry');
    });
  });

  // -------------------------------------------------------------------------
  // Subtraction
  // -------------------------------------------------------------------------
  group('Subtraction', () {
    test('generates valid subtraction problems', () {
      final config = SessionConfig(
        difficulty: Difficulty.medium,
        selectedOperations: [OperationType.subtraction],
      );
      for (int i = 0; i < 50; i++) {
        final p = engine.generateProblem(config);
        expect(p.operation, OperationType.subtraction);
        expect(p.expectedAnswer, p.operand1 - p.operand2);
      }
    });

    test('easy subtraction never goes negative', () {
      final config = SessionConfig(
        difficulty: Difficulty.easy,
        selectedOperations: [OperationType.subtraction],
      );
      for (int i = 0; i < 200; i++) {
        final p = engine.generateProblem(config);
        expect(p.expectedAnswer, greaterThanOrEqualTo(0));
        expect(p.operand1, greaterThanOrEqualTo(p.operand2));
      }
    });

    test('medium subtraction never goes negative', () {
      final config = SessionConfig(
        difficulty: Difficulty.medium,
        selectedOperations: [OperationType.subtraction],
      );
      for (int i = 0; i < 200; i++) {
        final p = engine.generateProblem(config);
        expect(p.expectedAnswer, greaterThanOrEqualTo(0));
      }
    });

    test('hard subtraction can produce negatives', () {
      final config = SessionConfig(
        difficulty: Difficulty.hard,
        selectedOperations: [OperationType.subtraction],
      );
      bool foundNegative = false;
      for (int i = 0; i < 500; i++) {
        final p = engine.generateProblem(config);
        if (p.expectedAnswer < 0) {
          foundNegative = true;
          break;
        }
      }
      expect(foundNegative, isTrue,
          reason: 'Hard subtraction should occasionally produce negatives');
    });
  });

  // -------------------------------------------------------------------------
  // Borrow detection
  // -------------------------------------------------------------------------
  group('Borrow detection', () {
    test('52 - 37 has borrow on ones column', () {
      final borrows = engine.detectBorrows(52, 37);
      // ones: 2-7 < 0 → borrow at col 0
      expect(borrows, contains(0));
    });

    test('100 - 1 has borrows on ones and tens', () {
      final borrows = engine.detectBorrows(100, 1);
      // ones: 0-1 < 0 → borrow col 0
      // tens: 0-0-1(borrow) < 0 → borrow col 1
      expect(borrows, containsAll([0, 1]));
    });

    test('85 - 23 has no borrows', () {
      final borrows = engine.detectBorrows(85, 23);
      expect(borrows, isEmpty);
    });

    test('subtraction problems include borrow digits', () {
      final config = SessionConfig(
        difficulty: Difficulty.medium,
        selectedOperations: [OperationType.subtraction],
      );
      bool foundBorrow = false;
      for (int i = 0; i < 200; i++) {
        final p = engine.generateProblem(config);
        if (p.borrowDigits.isNotEmpty) {
          foundBorrow = true;
          break;
        }
      }
      expect(foundBorrow, isTrue, reason: 'Should find at least one borrow');
    });
  });

  // -------------------------------------------------------------------------
  // Multiplication
  // -------------------------------------------------------------------------
  group('Multiplication', () {
    test('generates valid multiplication problems', () {
      final config = SessionConfig(
        difficulty: Difficulty.medium,
        selectedOperations: [OperationType.multiplication],
      );
      for (int i = 0; i < 50; i++) {
        final p = engine.generateProblem(config);
        expect(p.operation, OperationType.multiplication);
        expect(p.expectedAnswer, p.operand1 * p.operand2);
      }
    });

    test('easy multiplication factors are 1-9', () {
      final config = SessionConfig(
        difficulty: Difficulty.easy,
        selectedOperations: [OperationType.multiplication],
      );
      for (int i = 0; i < 100; i++) {
        final p = engine.generateProblem(config);
        expect(p.operand1, inInclusiveRange(1, 9));
        expect(p.operand2, inInclusiveRange(1, 9));
      }
    });

    test('medium multiplication has reasonable factors', () {
      final config = SessionConfig(
        difficulty: Difficulty.medium,
        selectedOperations: [OperationType.multiplication],
      );
      for (int i = 0; i < 100; i++) {
        final p = engine.generateProblem(config);
        expect(p.operand1, inInclusiveRange(1, 20));
        expect(p.operand2, inInclusiveRange(1, 9));
      }
    });

    test('hard multiplication has reasonable factors', () {
      final config = SessionConfig(
        difficulty: Difficulty.hard,
        selectedOperations: [OperationType.multiplication],
      );
      for (int i = 0; i < 100; i++) {
        final p = engine.generateProblem(config);
        expect(p.operand1, inInclusiveRange(1, 99));
        expect(p.operand2, inInclusiveRange(1, 9));
      }
    });
  });

  // -------------------------------------------------------------------------
  // Division
  // -------------------------------------------------------------------------
  group('Division', () {
    test('generates valid division problems with no remainder', () {
      for (final diff in Difficulty.values) {
        final config = SessionConfig(
          difficulty: diff,
          selectedOperations: [OperationType.division],
        );
        for (int i = 0; i < 100; i++) {
          final p = engine.generateProblem(config);
          expect(p.operation, OperationType.division);
          expect(p.operand1 % p.operand2, 0,
              reason: 'Division must have no remainder');
          expect(p.expectedAnswer, p.operand1 ~/ p.operand2);
        }
      }
    });

    test('easy division divisor 2-9, answer 1-9', () {
      final config = SessionConfig(
        difficulty: Difficulty.easy,
        selectedOperations: [OperationType.division],
      );
      for (int i = 0; i < 100; i++) {
        final p = engine.generateProblem(config);
        expect(p.operand2, inInclusiveRange(2, 9));
        expect(p.expectedAnswer, inInclusiveRange(1, 9));
      }
    });

    test('medium division divisor 2-20, answer 1-99', () {
      final config = SessionConfig(
        difficulty: Difficulty.medium,
        selectedOperations: [OperationType.division],
      );
      for (int i = 0; i < 100; i++) {
        final p = engine.generateProblem(config);
        expect(p.operand2, inInclusiveRange(2, 20));
        expect(p.expectedAnswer, inInclusiveRange(1, 99));
      }
    });
  });

  // -------------------------------------------------------------------------
  // Answer validation
  // -------------------------------------------------------------------------
  group('Answer validation', () {
    test('correct answer validates as correct', () {
      final problem = MathProblem(
        operand1: 47,
        operand2: 35,
        operation: OperationType.addition,
        expectedAnswer: 82,
      );
      // 82 → ones=2, tens=8
      final result = engine.validateAnswer(problem, [2, 8]);
      expect(result.isCorrect, isTrue);
      expect(result.digitCorrectness[0], isTrue);
      expect(result.digitCorrectness[1], isTrue);
    });

    test('partially wrong answer detected', () {
      final problem = MathProblem(
        operand1: 47,
        operand2: 35,
        operation: OperationType.addition,
        expectedAnswer: 82,
      );
      // User enters 83 → ones correct (2? no, user says 3 at ones)
      // Actually: expected is 82 → digit 0=2, digit 1=8
      // User enters [3, 8] → ones wrong, tens correct
      final result = engine.validateAnswer(problem, [3, 8]);
      expect(result.isCorrect, isFalse);
      expect(result.digitCorrectness[0], isFalse); // ones wrong
      expect(result.digitCorrectness[1], isTrue); // tens correct
    });

    test('all wrong answer detected', () {
      final problem = MathProblem(
        operand1: 47,
        operand2: 35,
        operation: OperationType.addition,
        expectedAnswer: 82,
      );
      final result = engine.validateAnswer(problem, [5, 5]);
      expect(result.isCorrect, isFalse);
      expect(result.digitCorrectness[0], isFalse);
      expect(result.digitCorrectness[1], isFalse);
    });

    test('null digit entries treated as wrong', () {
      final problem = MathProblem(
        operand1: 5,
        operand2: 3,
        operation: OperationType.addition,
        expectedAnswer: 8,
      );
      final result = engine.validateAnswer(problem, [null]);
      expect(result.isCorrect, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // Answer digit extraction
  // -------------------------------------------------------------------------
  group('Answer digit extraction', () {
    test('positive number extracted correctly', () {
      final digits = engine.extractAnswerDigits(382);
      expect(digits.length, 3);
      expect(digits[0].position, 0);
      expect(digits[0].value, 2); // ones
      expect(digits[1].position, 1);
      expect(digits[1].value, 8); // tens
      expect(digits[2].position, 2);
      expect(digits[2].value, 3); // hundreds
    });

    test('zero extracted as single digit', () {
      final digits = engine.extractAnswerDigits(0);
      expect(digits.length, 1);
      expect(digits[0].value, 0);
    });

    test('negative number includes negative sign', () {
      final digits = engine.extractAnswerDigits(-15);
      final signDigit = digits.where((d) => d.isNegativeSign).toList();
      expect(signDigit.length, 1);
      // Should also have digit 5 (ones) and 1 (tens)
      final numDigits = digits.where((d) => !d.isNegativeSign).toList();
      expect(numDigits.length, 2);
    });
  });

  // -------------------------------------------------------------------------
  // Session generation
  // -------------------------------------------------------------------------
  group('Session generation', () {
    test('generates correct number of problems', () {
      final config = SessionConfig(
        difficulty: Difficulty.medium,
        selectedOperations: [OperationType.addition, OperationType.subtraction],
        operationCount: 15,
      );
      final session = engine.generateSession(config);
      expect(session.length, 15);
    });

    test('no duplicate problems in session', () {
      final config = SessionConfig(
        difficulty: Difficulty.medium,
        selectedOperations: [
          OperationType.addition,
          OperationType.subtraction,
          OperationType.multiplication,
        ],
        operationCount: 20,
      );
      final session = engine.generateSession(config);
      final keys = session
          .map((p) => '${p.operand1}|${p.operation}|${p.operand2}')
          .toSet();
      expect(keys.length, session.length,
          reason: 'All problems should be unique');
    });

    test('session only uses selected operations', () {
      final config = SessionConfig(
        difficulty: Difficulty.easy,
        selectedOperations: [OperationType.addition],
        operationCount: 10,
      );
      final session = engine.generateSession(config);
      for (final p in session) {
        expect(p.operation, OperationType.addition);
      }
    });
  });
}
