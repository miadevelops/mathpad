import 'operation_type.dart';

class MathProblem {
  final int operand1;
  final int operand2;
  final OperationType operation;
  final int expectedAnswer;

  /// Indices of digit positions that require carrying (addition/multiplication).
  final List<int> carryDigits;

  /// Indices of digit positions that require borrowing (subtraction).
  final List<int> borrowDigits;

  /// Column index → carry value for multiplication (e.g. {0: 5, 1: 3}).
  /// A carry at column i is shown above column i+1 (the receiving column).
  final Map<int, int> carryValues;

  const MathProblem({
    required this.operand1,
    required this.operand2,
    required this.operation,
    required this.expectedAnswer,
    this.carryDigits = const [],
    this.borrowDigits = const [],
    this.carryValues = const {},
  });

  /// Human-readable representation: "12 + 5 = 17"
  String get display =>
      '$operand1 ${operation.symbol} $operand2 = $expectedAnswer';
}
