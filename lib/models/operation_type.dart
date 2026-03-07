enum OperationType {
  addition,
  subtraction,
  multiplication,
  division;

  String get symbol {
    switch (this) {
      case OperationType.addition:
        return '+';
      case OperationType.subtraction:
        return '−';
      case OperationType.multiplication:
        return '×';
      case OperationType.division:
        return '÷';
    }
  }

  String get label {
    switch (this) {
      case OperationType.addition:
        return 'Addition';
      case OperationType.subtraction:
        return 'Subtraction';
      case OperationType.multiplication:
        return 'Multiplication';
      case OperationType.division:
        return 'Division';
    }
  }
}
