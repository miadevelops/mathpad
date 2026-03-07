class DigitAnswer {
  /// Zero-based index of the digit position (0 = ones, 1 = tens, etc.)
  final int digitIndex;

  /// The value recognized from handwriting input.
  final int recognizedValue;

  /// Whether this digit matches the expected answer digit.
  final bool isCorrect;

  const DigitAnswer({
    required this.digitIndex,
    required this.recognizedValue,
    required this.isCorrect,
  });
}
