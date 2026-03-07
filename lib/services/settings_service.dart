import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

/// Singleton service that persists and loads [SessionConfig] via SharedPreferences.
class SettingsService {
  SettingsService._();
  static final SettingsService instance = SettingsService._();

  static const _keyDifficulty = 'settings_difficulty';
  static const _keyOperations = 'settings_operations';
  static const _keyProblemCount = 'settings_problem_count';

  static final _defaultConfig = SessionConfig(
    difficulty: Difficulty.easy,
    selectedOperations: [OperationType.addition, OperationType.subtraction],
    operationCount: 10,
  );

  SessionConfig? _cached;

  /// Load the saved config (or defaults).
  Future<SessionConfig> load() async {
    if (_cached != null) return _cached!;

    final prefs = await SharedPreferences.getInstance();

    final diffIndex = prefs.getInt(_keyDifficulty);
    final opIndices = prefs.getStringList(_keyOperations);
    final count = prefs.getInt(_keyProblemCount);

    final difficulty = diffIndex != null && diffIndex < Difficulty.values.length
        ? Difficulty.values[diffIndex]
        : _defaultConfig.difficulty;

    final operations = opIndices != null && opIndices.isNotEmpty
        ? opIndices
            .map((s) => int.tryParse(s))
            .where((i) => i != null && i < OperationType.values.length)
            .map((i) => OperationType.values[i!])
            .toList()
        : _defaultConfig.selectedOperations;

    _cached = SessionConfig(
      difficulty: difficulty,
      selectedOperations:
          operations.isEmpty ? _defaultConfig.selectedOperations : operations,
      operationCount: count ?? _defaultConfig.operationCount,
    );

    return _cached!;
  }

  /// Persist the given config.
  Future<void> save(SessionConfig config) async {
    _cached = config;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyDifficulty, config.difficulty.index);
    await prefs.setStringList(
      _keyOperations,
      config.selectedOperations.map((op) => op.index.toString()).toList(),
    );
    await prefs.setInt(_keyProblemCount, config.operationCount);
  }
}
