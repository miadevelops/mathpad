enum Difficulty {
  easy,
  medium,
  hard;

  String get label {
    switch (this) {
      case Difficulty.easy:
        return 'Easy';
      case Difficulty.medium:
        return 'Medium';
      case Difficulty.hard:
        return 'Hard';
    }
  }

  String get emoji {
    switch (this) {
      case Difficulty.easy:
        return '⭐';
      case Difficulty.medium:
        return '⭐⭐';
      case Difficulty.hard:
        return '⭐⭐⭐';
    }
  }
}
