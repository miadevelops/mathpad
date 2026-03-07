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

  const MathProblem({
    required this.operand1,
    required this.operand2,
    required this.operation,
    required this.expectedAnswer,
    this.carryDigits = const [],
    this.borrowDigits = const [],
  });

  /// Human-readable representation: "12 + 5 = 17"
  String get display =>
      '$operand1 ${operation.symbol} $operand2 = $expectedAnswer';
}
