import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/models.dart';
import '../services/math_engine.dart';
import '../services/recognition_service.dart';
import '../theme/app_theme.dart';
import '../widgets/confetti_overlay.dart';
import '../widgets/digit_reveal.dart';
import '../widgets/drawing_canvas.dart';

/// The core gameplay screen: presents math problems one by one,
/// lets kids draw answers digit-by-digit, validates, and tracks results.
class ExerciseScreen extends StatefulWidget {
  const ExerciseScreen({super.key});

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen>
    with TickerProviderStateMixin {
  // ── Services ──
  final MathEngine _engine = MathEngine();
  final RecognitionService _recognitionService = RecognitionService();
  final ConfettiController _confettiController = ConfettiController();

  // ── Session state ──
  late List<MathProblem> _problems;
  int _currentIndex = 0;
  int _correctCount = 0;
  DateTime? _sessionStart;
  bool _initialized = false;

  // ── Per-problem state ──
  late List<AnswerDigit> _answerDigits; // sorted display order (left→right)
  late List<int?> _recognizedValues; // indexed same as _answerDigits
  late List<List<List<Offset>>?> _digitStrokes; // strokes for reveal
  late List<GlobalKey<DrawingCanvasState>> _canvasKeys;
  late List<_DigitBoxState> _boxStates;
  bool _hasNegativeSign = false;
  bool _isFirstAttempt = true;
  bool _showCarries = false;
  bool _showingResult = false; // true while showing correct/skip feedback

  // ── Problem results tracking ──
  final List<ProblemResult> _results = [];

  // ── Animations ──
  AnimationController? _slideController;
  AnimationController? _bannerController;
  AnimationController? _shakeController;
  late Animation<Offset> _slideOutOffset;
  Animation<double>? _bannerScale;
  Animation<double>? _shakeOffset;

  // ── Post-action state ──
  _PostSubmitMode _postSubmitMode = _PostSubmitMode.none;

  @override
  void initState() {
    super.initState();
    _recognitionService.initialize();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final config =
          GoRouterState.of(context).extra as SessionConfig?;
      if (config == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.go('/');
        });
        return;
      }
      _problems = _engine.generateSession(config);
      _sessionStart = DateTime.now();
      _setupProblem(_problems[0]);
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _recognitionService.dispose();
    _confettiController.dispose();
    _slideController?.dispose();
    _bannerController?.dispose();
    _shakeController?.dispose();
    super.dispose();
  }

  // ── Problem setup ──

  void _setupProblem(MathProblem problem) {
    final rawDigits = _engine.extractAnswerDigits(problem.expectedAnswer);
    // Filter out negative sign entry; track it separately.
    final numericDigits =
        rawDigits.where((d) => !d.isNegativeSign).toList();
    _hasNegativeSign = rawDigits.any((d) => d.isNegativeSign);

    // Sort by position descending so index 0 = leftmost (highest place value).
    numericDigits.sort((a, b) => b.position.compareTo(a.position));
    _answerDigits = numericDigits;

    _recognizedValues = List.filled(_answerDigits.length, null);
    _digitStrokes = List.filled(_answerDigits.length, null);
    _canvasKeys = List.generate(
        _answerDigits.length, (_) => GlobalKey<DrawingCanvasState>());
    _boxStates =
        List.filled(_answerDigits.length, _DigitBoxState.empty);
    _isFirstAttempt = true;
    _showCarries = false;
    _showingResult = false;
    _postSubmitMode = _PostSubmitMode.none;
  }

  // ── Drawing / recognition ──

  Future<void> _onDrawingComplete(
      int boxIndex, List<List<Offset>> strokes) async {
    if (_showingResult) return;
    final timestamps = _canvasKeys[boxIndex].currentState?.timestamps;
    final digit = await _recognitionService.recognizeDigit(
      strokes,
      const Size(160, 200), // approximate canvas size
      timestamps: timestamps,
    );
    if (!mounted) return;
    setState(() {
      _recognizedValues[boxIndex] = digit;
      _digitStrokes[boxIndex] = strokes;
      _boxStates[boxIndex] =
          digit != null ? _DigitBoxState.revealed : _DigitBoxState.empty;
    });
  }

  void _clearBox(int boxIndex) {
    if (_showingResult) return;
    _canvasKeys[boxIndex].currentState?.clear();
    setState(() {
      _recognizedValues[boxIndex] = null;
      _digitStrokes[boxIndex] = null;
      _boxStates[boxIndex] = _DigitBoxState.empty;
    });
  }

  // ── Submit ──

  bool get _allBoxesFilled =>
      _recognizedValues.every((v) => v != null);

  void _onSubmit() {
    if (!_allBoxesFilled || _showingResult) return;

    // Build digit list indexed by position (0=ones) for validateAnswer.
    final maxPos =
        _answerDigits.map((d) => d.position).reduce(math.max);
    final digitAnswers = List<int?>.filled(maxPos + 1, null);
    for (int i = 0; i < _answerDigits.length; i++) {
      digitAnswers[_answerDigits[i].position] = _recognizedValues[i];
    }

    final validation =
        _engine.validateAnswer(_problems[_currentIndex], digitAnswers);

    if (validation.isCorrect) {
      _handleCorrect();
    } else {
      _handleWrong(validation);
    }
  }

  void _handleCorrect() {
    _confettiController.fire();
    setState(() {
      _showingResult = true;
      for (int i = 0; i < _boxStates.length; i++) {
        _boxStates[i] = _DigitBoxState.correct;
      }
      _showCarries = true;
      _postSubmitMode = _PostSubmitMode.correct;
    });

    // Banner animation
    _bannerController?.dispose();
    _bannerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _bannerScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _bannerController!, curve: Curves.elasticOut),
    );
    _bannerController!.forward();

    // Record result
    _results.add(ProblemResult(
      problem: _problems[_currentIndex],
      correctOnFirstTry: _isFirstAttempt,
      correctOnRetry: !_isFirstAttempt,
    ));

    _correctCount++;

    // Auto-advance
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) _advanceToNext();
    });
  }

  void _handleWrong(AnswerValidation validation) {
    _isFirstAttempt = false;

    // Mark each box correct/incorrect
    setState(() {
      _showingResult = true;
      for (int i = 0; i < _answerDigits.length; i++) {
        final pos = _answerDigits[i].position;
        final correct = validation.digitCorrectness[pos] ?? false;
        _boxStates[i] =
            correct ? _DigitBoxState.correct : _DigitBoxState.incorrect;
      }
      _postSubmitMode = _PostSubmitMode.wrong;
    });

    // Shake wrong boxes
    _shakeController?.dispose();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeOffset = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController!, curve: Curves.linear),
    );
    _shakeController!.forward();
  }

  void _onTryAgain() {
    setState(() {
      _showingResult = false;
      _postSubmitMode = _PostSubmitMode.none;
      for (int i = 0; i < _boxStates.length; i++) {
        if (_boxStates[i] == _DigitBoxState.incorrect) {
          _clearBox(i);
        }
      }
    });
  }

  void _onSkip() {
    // Record as skipped
    _results.add(ProblemResult(
      problem: _problems[_currentIndex],
      skipped: true,
    ));

    // Reveal correct answer
    setState(() {
      _showingResult = true;
      _postSubmitMode = _PostSubmitMode.skipped;
      for (int i = 0; i < _answerDigits.length; i++) {
        _recognizedValues[i] = _answerDigits[i].value;
        _boxStates[i] = _DigitBoxState.revealed;
      }
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _advanceToNext();
    });
  }

  void _advanceToNext() {
    if (_currentIndex + 1 >= _problems.length) {
      // Session complete
      final duration = DateTime.now().difference(_sessionStart!);
      final sessionResult =
          SessionResult(results: _results, duration: duration);
      context.go('/results', extra: sessionResult);
      return;
    }

    // Slide transition
    _slideController?.dispose();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideOutOffset = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-1.2, 0),
    ).animate(CurvedAnimation(
        parent: _slideController!, curve: Curves.easeInBack));

    _slideController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _currentIndex++;
          _setupProblem(_problems[_currentIndex]);
        });
        // Reset slide so the new problem appears normally.
        _slideController?.reset();
      }
    });

    setState(() {
      _showingResult = false;
      _postSubmitMode = _PostSubmitMode.none;
    });
    _slideController!.forward();
  }

  // ── Quit confirmation ──

  Future<void> _confirmQuit() async {
    final quit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text('Quit Practice?',
            style: GoogleFonts.comicNeue(
                fontWeight: FontWeight.w700, fontSize: 24)),
        content: Text('Your progress won\'t be saved.',
            style: GoogleFonts.comicNeue(fontSize: 18)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Keep Going',
                style: GoogleFonts.comicNeue(
                    fontWeight: FontWeight.w700, fontSize: 18)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Quit',
                style: GoogleFonts.comicNeue(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: AppTheme.errorRed)),
          ),
        ],
      ),
    );
    if (quit == true && mounted) {
      context.go('/');
    }
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    final problem = _problems[_currentIndex];
    final progress = (_currentIndex + 1) / _problems.length;

    return Scaffold(
      body: Stack(
        children: [
          Container(
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
                  // ── Top bar ──
                  _buildTopBar(progress),

                  // ── Main content ──
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1330),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: _buildProblemArea(problem),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── Bottom buttons ──
                  _buildBottomButtons(),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: ConfettiOverlay(controller: _confettiController),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(double progress) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 24, 0),
      child: Row(
        children: [
          // Quit button
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 32),
            onPressed: _confirmQuit,
            tooltip: 'Quit',
          ),
          const SizedBox(width: 12),

          // Progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Problem ${_currentIndex + 1} of ${_problems.length}',
                  style: GoogleFonts.comicNeue(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress),
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOut,
                    builder: (_, value, _) => LinearProgressIndicator(
                      value: value,
                      minHeight: 10,
                      backgroundColor:
                          AppTheme.primaryBlue.withValues(alpha: 0.12),
                      valueColor: const AlwaysStoppedAnimation(
                          AppTheme.primaryBlue),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Score
          Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: AppTheme.successGreen, size: 28),
              const SizedBox(width: 4),
              Text(
                '$_correctCount',
                style: GoogleFonts.comicNeue(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.successGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProblemArea(MathProblem problem) {
    final isSliding =
        _slideController != null && _slideController!.isAnimating;

    Widget content = _buildVerticalArithmetic(problem);

    if (isSliding) {
      content = SlideTransition(
        position: _slideOutOffset,
        child: content,
      );
    }

    // Correct banner overlay
    if (_postSubmitMode == _PostSubmitMode.correct &&
        _bannerScale != null) {
      content = Stack(
        clipBehavior: Clip.none,
        children: [
          content,
          Positioned(
            top: -10,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedBuilder(
                animation: _bannerScale!,
                builder: (_, child) => Transform.scale(
                  scale: _bannerScale!.value,
                  child: child,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.successGreen,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color:
                            AppTheme.successGreen.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    'Correct!',
                    style: GoogleFonts.comicNeue(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return content;
  }

  Widget _buildVerticalArithmetic(MathProblem problem) {
    // Figure out the max number of digit columns needed.
    final op1Str = problem.operand1.abs().toString();
    final op2Str = problem.operand2.abs().toString();
    final ansDigitCount = _answerDigits.length;
    final maxCols =
        math.max(math.max(op1Str.length, op2Str.length), ansDigitCount);

    // Add 1 extra column on the left for the operator symbol.
    final totalCols = maxCols + 1;

    const boxSize = 160.0; // digit box width
    const boxSpacing = 17.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Carry indicators ──
        if (_showCarries && problem.carryDigits.isNotEmpty)
          _buildCarryRow(problem, maxCols, boxSize, boxSpacing, totalCols),

        // ── First operand row ──
        _buildOperandRow(
          digits: op1Str,
          maxCols: maxCols,
          totalCols: totalCols,
          boxSize: boxSize,
          boxSpacing: boxSpacing,
        ),

        const SizedBox(height: 11),

        // ── Second operand row (with operator) ──
        _buildOperandRow(
          digits: op2Str,
          maxCols: maxCols,
          totalCols: totalCols,
          boxSize: boxSize,
          boxSpacing: boxSpacing,
          operator: problem.operation.symbol,
        ),

        const SizedBox(height: 11),

        // ── Separator line ──
        SizedBox(
          width: totalCols * (boxSize + boxSpacing),
          child: const Divider(
            thickness: 7,
            color: AppTheme.textPrimary,
            height: 23,
          ),
        ),

        const SizedBox(height: 15),

        // ── Answer row ──
        _buildAnswerRow(boxSize, boxSpacing, maxCols, totalCols),
      ],
    );
  }

  Widget _buildCarryRow(MathProblem problem, int maxCols, double boxSize,
      double boxSpacing, int totalCols) {
    // carryDigits contains column indices where the column sum >= 10.
    // A carry at column i means column i+1 receives a +1.
    // We show "1" above column i+1 (the receiving column).
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: SizedBox(
        width: totalCols * (boxSize + boxSpacing),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Operator column placeholder
            SizedBox(width: boxSize + boxSpacing),
            ...List.generate(maxCols, (displayIdx) {
              // displayIdx 0 = leftmost (highest place value)
              final col = maxCols - 1 - displayIdx;
              // Show "1" above this column if (col-1) carried.
              final showAbove = col > 0 && problem.carryDigits.contains(col - 1);
              return SizedBox(
                width: boxSize + boxSpacing,
                child: Center(
                  child: showAbove
                      ? Text(
                          '1',
                          style: GoogleFonts.comicNeue(
                          fontSize: 46,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary
                                .withValues(alpha: 0.5),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildOperandRow({
    required String digits,
    required int maxCols,
    required int totalCols,
    required double boxSize,
    required double boxSpacing,
    String? operator,
  }) {
    // Right-align: pad left with empty cells.
    final padCount = maxCols - digits.length;

    return SizedBox(
      width: totalCols * (boxSize + boxSpacing),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Operator column (leftmost)
          SizedBox(
            width: boxSize + boxSpacing,
            child: Center(
              child: Text(
                operator ?? '',
                style: GoogleFonts.comicNeue(
                  fontSize: 103,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ),
          ),
          // Padding columns
          ...List.generate(
            padCount,
            (_) => SizedBox(width: boxSize + boxSpacing),
          ),
          // Digit columns
          ...digits.split('').map((ch) {
            return SizedBox(
              width: boxSize + boxSpacing,
              child: Center(
                child: Text(
                  ch,
                  style: GoogleFonts.courierPrime(
                    fontSize: 114,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAnswerRow(
      double boxSize, double boxSpacing, int maxCols, int totalCols) {
    final padCount = maxCols - _answerDigits.length;

    return SizedBox(
      width: totalCols * (boxSize + boxSpacing),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Operator column — negative sign or empty
          SizedBox(
            width: boxSize + boxSpacing,
            child: Center(
              child: _hasNegativeSign
                  ? Text(
                      '−',
                      style: GoogleFonts.comicNeue(
                        fontSize: 103,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.errorRed,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          // Padding
          ...List.generate(
            padCount,
            (_) => SizedBox(width: boxSize + boxSpacing),
          ),
          // Drawing boxes
          ...List.generate(_answerDigits.length, (i) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: boxSpacing / 2),
              child: _buildDigitBox(i, boxSize),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDigitBox(int index, double boxSize) {
    final state = _boxStates[index];
    final strokes = _digitStrokes[index];
    final digit = _recognizedValues[index];

    // Box colors based on state
    Color borderColor = AppTheme.primaryBlue.withValues(alpha: 0.3);
    Color bgColor = Colors.white;
    if (state == _DigitBoxState.correct) {
      borderColor = AppTheme.successGreen;
      bgColor = AppTheme.successGreen.withValues(alpha: 0.08);
    } else if (state == _DigitBoxState.incorrect) {
      borderColor = AppTheme.errorRed;
      bgColor = AppTheme.errorRed.withValues(alpha: 0.08);
    }

    Widget child;

    if (state == _DigitBoxState.revealed && strokes != null && digit != null) {
      // Show digit reveal animation
      final result = _boxStates[index] == _DigitBoxState.correct
          ? DigitResult.correct
          : _boxStates[index] == _DigitBoxState.incorrect
              ? DigitResult.incorrect
              : DigitResult.neutral;
      child = SizedBox(
        width: boxSize,
        height: boxSize * 1.25,
        child: DigitReveal(
          strokes: strokes,
          digit: digit,
          result: result,
          strokeWidth: 13,
        ),
      );
    } else if (state == _DigitBoxState.correct && digit != null) {
      child = SizedBox(
        width: boxSize,
        height: boxSize * 1.25,
        child: Center(
          child: Text(
            '$digit',
            style: GoogleFonts.courierPrime(
              fontSize: 114,
              fontWeight: FontWeight.w700,
              color: AppTheme.successGreen,
            ),
          ),
        ),
      );
    } else if (state == _DigitBoxState.incorrect && digit != null) {
      // Shaking incorrect digit
      child = SizedBox(
        width: boxSize,
        height: boxSize * 1.25,
        child: _shakeOffset != null
            ? AnimatedBuilder(
                animation: _shakeOffset!,
                builder: (_, child) {
                  final t = _shakeOffset!.value;
                  // 3 oscillation cycles
                  final dx = math.sin(t * math.pi * 6) * 8;
                  return Transform.translate(
                      offset: Offset(dx, 0), child: child);
                },
                child: Center(
                  child: Text(
                    '$digit',
                    style: GoogleFonts.courierPrime(
                      fontSize: 114,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.errorRed,
                    ),
                  ),
                ),
              )
            : Center(
                child: Text(
                  '$digit',
                  style: GoogleFonts.courierPrime(
                    fontSize: 114,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.errorRed,
                  ),
                ),
              ),
      );
    } else if (_postSubmitMode == _PostSubmitMode.skipped && digit != null) {
      // Revealed correct answer after skip
      child = SizedBox(
        width: boxSize,
        height: boxSize * 1.25,
        child: Center(
          child: Text(
            '$digit',
            style: GoogleFonts.courierPrime(
              fontSize: 114,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
      );
    } else {
      // Empty — show drawing canvas
      child = SizedBox(
        width: boxSize,
        height: boxSize * 1.25,
        child: DrawingCanvas(
          key: _canvasKeys[index],
          onDrawingComplete: (strokes) =>
              _onDrawingComplete(index, strokes),
          strokeWidth: 13,
        ),
      );
    }

    // Wrap in tappable container for clearing recognized digits
    return GestureDetector(
      onTap: (state == _DigitBoxState.revealed && !_showingResult)
          ? () => _clearBox(index)
          : null,
      child: Container(
        width: boxSize,
        height: boxSize * 1.25,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: child,
      ),
    );
  }

  Widget _buildBottomButtons() {
    if (_postSubmitMode == _PostSubmitMode.wrong) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton(
              onPressed: _onSkip,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.textSecondary,
                side: const BorderSide(color: AppTheme.textSecondary),
                minimumSize: const Size(140, 56),
                textStyle: GoogleFonts.comicNeue(
                    fontSize: 20, fontWeight: FontWeight.w700),
              ),
              child: const Text('Skip'),
            ),
            const SizedBox(width: 20),
            ElevatedButton(
              onPressed: _onTryAgain,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentOrange,
                minimumSize: const Size(180, 56),
                textStyle: GoogleFonts.comicNeue(
                    fontSize: 20, fontWeight: FontWeight.w700),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_showingResult) {
      return const SizedBox(height: 80); // placeholder while animating
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Skip
          OutlinedButton(
            onPressed: _onSkip,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textSecondary,
              side: const BorderSide(color: AppTheme.textSecondary),
              minimumSize: const Size(120, 56),
              textStyle: GoogleFonts.comicNeue(
                  fontSize: 18, fontWeight: FontWeight.w700),
            ),
            child: const Text('Skip'),
          ),
          const SizedBox(width: 20),
          // Submit
          ElevatedButton(
            onPressed: _allBoxesFilled ? _onSubmit : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successGreen,
              disabledBackgroundColor:
                  AppTheme.successGreen.withValues(alpha: 0.3),
              minimumSize: const Size(200, 64),
              textStyle: GoogleFonts.comicNeue(
                  fontSize: 22, fontWeight: FontWeight.w700),
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ──

enum _DigitBoxState { empty, revealed, correct, incorrect }

enum _PostSubmitMode { none, correct, wrong, skipped }
