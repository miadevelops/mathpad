import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  Difficulty _difficulty = Difficulty.easy;
  Set<OperationType> _operations = {
    OperationType.addition,
    OperationType.subtraction,
  };
  int _problemCount = 10;

  static const _problemCounts = [5, 10, 15, 20];

  bool _isOpAvailable(OperationType op) {
    if (_difficulty == Difficulty.easy) {
      return op == OperationType.addition || op == OperationType.subtraction;
    }
    return true;
  }

  void _setDifficulty(Difficulty d) {
    setState(() {
      _difficulty = d;
      // Remove unavailable ops
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
  }

  void _go() {
    final config = SessionConfig(
      difficulty: _difficulty,
      selectedOperations: _operations.toList(),
      operationCount: _problemCount,
    );
    context.go('/exercise', extra: config);
  }

  @override
  Widget build(BuildContext context) {
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
              // Top bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, size: 32),
                      onPressed: () => context.go('/'),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Set Up Your Practice',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                  ],
                ),
              ),

              // Scrollable content
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

                          // ── Difficulty ─────────────────
                          _SectionLabel(label: 'Difficulty'),
                          const SizedBox(height: 12),
                          _DifficultyRow(
                            selected: _difficulty,
                            onSelect: _setDifficulty,
                          ),

                          const SizedBox(height: 36),

                          // ── Operations ─────────────────
                          _SectionLabel(label: 'Operations'),
                          const SizedBox(height: 12),
                          _OperationsRow(
                            selected: _operations,
                            isAvailable: _isOpAvailable,
                            onToggle: _toggleOperation,
                          ),

                          const SizedBox(height: 36),

                          // ── Problem Count ──────────────
                          _SectionLabel(label: 'Number of Problems'),
                          const SizedBox(height: 12),
                          _ProblemCountSelector(
                            counts: _problemCounts,
                            selected: _problemCount,
                            onSelect: (c) =>
                                setState(() => _problemCount = c),
                          ),

                          const SizedBox(height: 48),

                          // ── GO button ──────────────────
                          Center(
                            child: SizedBox(
                              width: 260,
                              height: 72,
                              child: ElevatedButton(
                                onPressed: _go,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.accentOrange,
                                  foregroundColor: Colors.white,
                                  shape: const StadiumBorder(),
                                  elevation: 4,
                                  shadowColor: AppTheme.accentOrange
                                      .withValues(alpha: 0.4),
                                  textStyle: GoogleFonts.comicNeue(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                child: const Text("LET'S GO!"),
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

// ── Section Label ─────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label, style: Theme.of(context).textTheme.titleLarge);
  }
}

// ── Difficulty Row ────────────────────────────────────────
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
                    color: isSelected
                        ? color
                        : Colors.grey.shade200,
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

// ── Operations Row ────────────────────────────────────────
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
                        : available
                            ? Colors.grey.shade200
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

// ── Problem Count Selector ────────────────────────────────
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

// ── Tap Scale Card (reusable) ─────────────────────────────
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
