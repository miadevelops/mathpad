import 'difficulty.dart';
import 'operation_type.dart';

class SessionConfig {
  final Difficulty difficulty;
  final List<OperationType> selectedOperations;
  final int operationCount;

  const SessionConfig({
    required this.difficulty,
    required this.selectedOperations,
    this.operationCount = 10,
  });

  SessionConfig copyWith({
    Difficulty? difficulty,
    List<OperationType>? selectedOperations,
    int? operationCount,
  }) {
    return SessionConfig(
      difficulty: difficulty ?? this.difficulty,
      selectedOperations: selectedOperations ?? this.selectedOperations,
      operationCount: operationCount ?? this.operationCount,
    );
  }
}
