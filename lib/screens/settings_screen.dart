import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/models.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Difficulty _difficulty = Difficulty.easy;
  Set<OperationType> _operations = {
    OperationType.addition,
    OperationType.subtraction,
  };
  int _problemCount = 10;
  bool _loaded = false;

  static const _problemCounts = [5, 10, 15, 20];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final config = await SettingsService.instance.load();
    setState(() {
      _difficulty = config.difficulty;
      _operations = config.selectedOperations.toSet();
      _problemCount = config.operationCount;
      _loaded = true;
    });
  }

  Future<void> _save() async {
    final config = SessionConfig(
      difficulty: _difficulty,
      selectedOperations: _operations.toList(),
      operationCount: _problemCount,
    );
    await SettingsService.instance.save(config);
  }

  bool _isOpAvailable(OperationType op) {
    if (_difficulty == Difficulty.easy) {
      return op == OperationType.addition || op == OperationType.subtraction;
    }
    return true;
  }

  void _setDifficulty(Difficulty d) {
    setState(() {
      _difficulty = d;
      if (d == Difficulty.easy) {
        _operations.removeAll([
          OperationType.multiplication,
          OperationType.division,
        ]);
        if (_operations.isEmpty) {
          _operations = {OperationType.addition};
        }
      }
    });
    _save();
  }

  void _toggleOperation(OperationType op) {
    if (!_isOpAvailable(op)) return;
    setState(() {
      if (_operations.contains(op)) {
        if (_operations.length > 1) _operations.remove(op);
      } else {
        _operations.add(op);
      }
    });
    _save();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE8F0FE), AppTheme.background],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, size: 32),
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Settings',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          _SectionLabel(label: 'Difficulty'),
                          const SizedBox(height: 12),
                          _DifficultyRow(
                            selected: _difficulty,
                            onSelect: _setDifficulty,
                          ),
                          const SizedBox(height: 36),
                          _SectionLabel(label: 'Operations'),
                          const SizedBox(height: 12),
                          _OperationsRow(
                            selected: _operations,
                            isAvailable: _isOpAvailable,
                            onToggle: _toggleOperation,
                          ),
                          const SizedBox(height: 36),
                          _SectionLabel(label: 'Number of Problems'),
                          const SizedBox(height: 12),
                          _ProblemCountSelector(
                            counts: _problemCounts,
                            selected: _problemCount,
                            onSelect: (c) {
                              setState(() => _problemCount = c);
                              _save();
                            },
                          ),
                          const SizedBox(height: 48),
                          Center(
                            child: Text(
                              'Settings are saved automatically',
                              style: GoogleFonts.comicNeue(
                                fontSize: 16,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 48),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Reusing the same widgets from the old config screen
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label, style: Theme.of(context).textTheme.titleLarge);
  }
}

class _DifficultyRow extends StatelessWidget {
  final Difficulty selected;
  final ValueChanged<Difficulty> onSelect;

  const _DifficultyRow({required this.selected, required this.onSelect});

  static const _descriptions = {
    Difficulty.easy: 'Small numbers, no carrying',
    Difficulty.medium: 'Bigger numbers with carrying',
    Difficulty.hard: 'Challenge mode!',
  };

  static const _colors = {
    Difficulty.easy: AppTheme.successGreen,
    Difficulty.medium: AppTheme.accentYellow,
    Difficulty.hard: AppTheme.errorRed,
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      children: Difficulty.values.map((d) {
        final isSelected = d == selected;
        final color = _colors[d]!;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: _TapScaleCard(
              onTap: () => onSelect(d),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.15)
                      : AppTheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                  border: Border.all(
                    color: isSelected ? color : Colors.grey.shade200,
                    width: isSelected ? 3 : 1.5,
                  ),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: color.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(d.emoji, style: const TextStyle(fontSize: 28)),
                    const SizedBox(height: 8),
                    Text(
                      d.label,
                      style: GoogleFonts.comicNeue(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _descriptions[d]!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.comicNeue(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _OperationsRow extends StatelessWidget {
  final Set<OperationType> selected;
  final bool Function(OperationType) isAvailable;
  final ValueChanged<OperationType> onToggle;

  const _OperationsRow({
    required this.selected,
    required this.isAvailable,
    required this.onToggle,
  });

  static const _emojis = {
    OperationType.addition: '➕',
    OperationType.subtraction: '➖',
    OperationType.multiplication: '✖️',
    OperationType.division: '➗',
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      children: OperationType.values.map((op) {
        final available = isAvailable(op);
        final active = selected.contains(op) && available;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: _TapScaleCard(
              onTap: available ? () => onToggle(op) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: active
                      ? AppTheme.primaryBlue.withValues(alpha: 0.12)
                      : available
                          ? AppTheme.surface
                          : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                  border: Border.all(
                    color: active
                        ? AppTheme.primaryBlue
                        : Colors.grey.shade200,
                    width: active ? 3 : 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      _emojis[op]!,
                      style: TextStyle(
                        fontSize: 36,
                        color: available ? null : Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      op.label,
                      style: GoogleFonts.comicNeue(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: available
                            ? AppTheme.textPrimary
                            : Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ProblemCountSelector extends StatelessWidget {
  final List<int> counts;
  final int selected;
  final ValueChanged<int> onSelect;

  const _ProblemCountSelector({
    required this.counts,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
      ),
      child: Row(
        children: counts.map((c) {
          final isSelected = c == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(c),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: AppTheme.minTouchTarget,
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$c',
                  style: GoogleFonts.comicNeue(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TapScaleCard extends StatefulWidget {
  final VoidCallback? onTap;
  final Widget child;

  const _TapScaleCard({required this.onTap, required this.child});

  @override
  State<_TapScaleCard> createState() => _TapScaleCardState();
}

class _TapScaleCardState extends State<_TapScaleCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 0.05,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) => Transform.scale(
          scale: 1.0 - _ctrl.value,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}
