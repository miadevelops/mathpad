import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Visual state of the drawing canvas.
enum CanvasState { empty, drawing, recognized }

/// A drawing surface where kids write a single digit with finger or Apple Pencil.
///
/// Strokes are exported as `List<List<Offset>>` via [onDrawingComplete],
/// which fires after an 800 ms pause in drawing activity.
class DrawingCanvas extends StatefulWidget {
  /// Called after the user pauses drawing for ~800 ms.
  final ValueChanged<List<List<Offset>>>? onDrawingComplete;

  /// Externally-driven visual state (parent sets [CanvasState.recognized]).
  final CanvasState state;

  /// Digit to overlay when [state] is [CanvasState.recognized].
  final int? recognizedDigit;

  /// Stroke width for the drawing pen.
  final double strokeWidth;

  /// Stroke color.
  final Color strokeColor;

  /// Called when the canvas is cleared by the user.
  final VoidCallback? onCleared;

  const DrawingCanvas({
    super.key,
    this.onDrawingComplete,
    this.state = CanvasState.empty,
    this.recognizedDigit,
    this.strokeWidth = 8.0,
    this.strokeColor = const Color(0xFF2D3436),
    this.onCleared,
  });

  @override
  State<DrawingCanvas> createState() => DrawingCanvasState();
}

class DrawingCanvasState extends State<DrawingCanvas> {
  final List<List<Offset>> _strokes = [];
  final List<List<int>> _timestamps = [];
  List<Offset>? _currentStroke;
  List<int>? _currentTimestamps;
  Timer? _debounce;

  /// Clear all strokes programmatically.
  void clear() {
    _debounce?.cancel();
    setState(() {
      _strokes.clear();
      _timestamps.clear();
      _currentStroke = null;
      _currentTimestamps = null;
    });
    widget.onCleared?.call();
  }

  /// Current strokes (read-only copy).
  List<List<Offset>> get strokes =>
      _strokes.map((s) => List<Offset>.from(s)).toList();

  /// Timestamps in milliseconds for each point (parallel to [strokes]).
  List<List<int>> get timestamps =>
      _timestamps.map((t) => List<int>.from(t)).toList();

  // ── Gesture handlers ────────────────────────────────────

  void _onPanStart(DragStartDetails details) {
    _debounce?.cancel();
    final point = details.localPosition;
    setState(() {
      _currentStroke = [point];
      _currentTimestamps = [DateTime.now().millisecondsSinceEpoch];
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_currentStroke == null) return;
    setState(() {
      _currentStroke!.add(details.localPosition);
      _currentTimestamps!.add(DateTime.now().millisecondsSinceEpoch);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_currentStroke == null || _currentStroke!.isEmpty) return;
    setState(() {
      _strokes.add(List<Offset>.from(_currentStroke!));
      _timestamps.add(List<int>.from(_currentTimestamps!));
      _currentStroke = null;
      _currentTimestamps = null;
    });
    _startDebounce();
  }

  void _startDebounce() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () {
      if (_strokes.isNotEmpty) {
        widget.onDrawingComplete?.call(strokes);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  // ── Build ───────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bool isEmpty = _strokes.isEmpty && _currentStroke == null;
    final effectiveState =
        widget.state == CanvasState.recognized ? widget.state
        : isEmpty ? CanvasState.empty
        : CanvasState.drawing;

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 152, minHeight: 190),
      child: AspectRatio(
        aspectRatio: 0.8, // slightly taller than wide
        child: Stack(
          children: [
            // Canvas area
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: GestureDetector(
                  onPanStart: _onPanStart,
                  onPanUpdate: _onPanUpdate,
                  onPanEnd: _onPanEnd,
                  child: CustomPaint(
                    painter: _CanvasPainter(
                      strokes: _strokes,
                      currentStroke: _currentStroke,
                      strokeWidth: widget.strokeWidth,
                      strokeColor: widget.strokeColor,
                    ),
                    child: Container(color: Colors.transparent),
                  ),
                ),
              ),
            ),

            // Placeholder "?" when empty
            if (effectiveState == CanvasState.empty)
              Positioned.fill(
                child: IgnorePointer(
                  child: Center(
                    child: Text(
                      '?',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w300,
                        color: AppTheme.textSecondary.withValues(alpha: 0.25),
                      ),
                    ),
                  ),
                ),
              ),

            // Clear button (top-right corner)
            if (effectiveState == CanvasState.drawing)
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: clear,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.textSecondary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: AppTheme.textSecondary.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Custom Painter ────────────────────────────────────────

class _CanvasPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset>? currentStroke;
  final double strokeWidth;
  final Color strokeColor;

  _CanvasPainter({
    required this.strokes,
    this.currentStroke,
    required this.strokeWidth,
    required this.strokeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas, size);
    _drawStrokes(canvas, size);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFE8ECF0)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Horizontal guide lines (3 evenly spaced)
    for (int i = 1; i <= 3; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Center vertical line
    final cx = size.width / 2;
    canvas.drawLine(Offset(cx, 0), Offset(cx, size.height), gridPaint);
  }

  void _drawStrokes(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = strokeColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      _drawSingleStroke(canvas, stroke, paint);
    }
    if (currentStroke != null && currentStroke!.isNotEmpty) {
      _drawSingleStroke(canvas, currentStroke!, paint);
    }
  }

  void _drawSingleStroke(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.length < 2) {
      if (points.length == 1) {
        canvas.drawCircle(points.first, strokeWidth / 2, paint..style = PaintingStyle.fill);
        paint.style = PaintingStyle.stroke;
      }
      return;
    }

    final path = ui.Path();
    path.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      // Smooth with quadratic bezier using midpoint
      if (i < points.length - 1) {
        final mid = Offset(
          (points[i].dx + points[i + 1].dx) / 2,
          (points[i].dy + points[i + 1].dy) / 2,
        );
        path.quadraticBezierTo(points[i].dx, points[i].dy, mid.dx, mid.dy);
      } else {
        path.lineTo(points[i].dx, points[i].dy);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CanvasPainter old) => true;
}
