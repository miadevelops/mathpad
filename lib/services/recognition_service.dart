import 'dart:ui';

/// Service that recognizes handwritten digits from stroke data.
///
/// Attempts ML Kit digital ink recognition first, falling back to a
/// simple heuristic recognizer so the app always works.
class RecognitionService {
  bool _initialized = false;

  /// Initialize the service (download model, etc.).
  Future<void> initialize() async {
    // ML Kit would download the model here.
    // For now we use the heuristic fallback which needs no setup.
    _initialized = true;
  }

  /// Recognize a single digit (0-9) from [strokes] drawn within [canvasSize].
  ///
  /// Returns `null` when recognition fails or the result isn't a digit.
  Future<int?> recognizeDigit(
    List<List<Offset>> strokes,
    Size canvasSize,
  ) async {
    if (!_initialized) await initialize();
    if (strokes.isEmpty) return null;

    // ── ML Kit path would go here ──
    // try {
    //   return await _recognizeWithMlKit(strokes, canvasSize);
    // } catch (_) {}

    // ── Heuristic fallback ──
    return _heuristicRecognize(strokes, canvasSize);
  }

  /// Release resources.
  void dispose() {
    _initialized = false;
  }

  // ---------------------------------------------------------------------------
  // Heuristic digit recognizer
  // ---------------------------------------------------------------------------

  int? _heuristicRecognize(List<List<Offset>> strokes, Size canvasSize) {
    if (strokes.isEmpty) return null;

    final allPoints = strokes.expand((s) => s).toList();
    if (allPoints.isEmpty) return null;

    // Bounding box
    double minX = double.infinity, maxX = double.negativeInfinity;
    double minY = double.infinity, maxY = double.negativeInfinity;
    for (final p in allPoints) {
      if (p.dx < minX) minX = p.dx;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dy > maxY) maxY = p.dy;
    }

    final bw = maxX - minX;
    final bh = maxY - minY;
    if (bw < 2 && bh < 2) return 1; // just a dot / tap → treat as 1

    final aspect = bw / (bh == 0 ? 1 : bh);
    final strokeCount = strokes.length;

    // Total path length (used for density heuristics)
    // ignore: unused_local_variable
    double totalLength = 0;
    for (final stroke in strokes) {
      for (int i = 1; i < stroke.length; i++) {
        totalLength += (stroke[i] - stroke[i - 1]).distance;
      }
    }

    // Is the stroke a closed loop? (start near end for first stroke)
    final firstStroke = strokes.first;
    final closedLoop = firstStroke.length > 4 &&
        (firstStroke.first - firstStroke.last).distance < bh * 0.35;

    // Count intersections / crossings (crude)
    int crossings = _countSelfCrossings(strokes);

    // ── Decision tree (rough heuristics) ──

    // "1" — single stroke, narrow, mostly vertical
    if (strokeCount == 1 && aspect < 0.4 && !closedLoop) {
      return 1;
    }

    // "0" — single stroke, closed loop, roughly round
    if (strokeCount == 1 && closedLoop && aspect > 0.5 && aspect < 1.6) {
      return 0;
    }

    // "7" — single stroke, wider at top, short
    if (strokeCount == 1 && !closedLoop && crossings == 0) {
      // Check if the stroke starts upper-left and ends lower
      if (firstStroke.length > 3) {
        final startY = (firstStroke.first.dy - minY) / bh;
        final endY = (firstStroke.last.dy - minY) / bh;
        final startX = (firstStroke.first.dx - minX) / bw;
        final endX = (firstStroke.last.dx - minX) / bw;
        if (startY < 0.3 && endY > 0.6 && startX < 0.4) {
          return 7;
        }
        // "2" — starts upper area, sweeps down to the right then left
        if (startY < 0.35 && endY > 0.7 && endX > 0.4) {
          return 2;
        }
      }
    }

    // "8" — single stroke with crossing, tallish
    if (strokeCount == 1 && crossings >= 1 && aspect < 0.9) {
      return 8;
    }

    // "4" — two or three strokes
    if (strokeCount >= 2 && strokeCount <= 3 && aspect > 0.3) {
      // Check for a strong vertical stroke
      bool hasVertical = false;
      for (final s in strokes) {
        if (s.length < 2) continue;
        final sdx = (s.last.dx - s.first.dx).abs();
        final sdy = (s.last.dy - s.first.dy).abs();
        if (sdy > sdx * 2) hasVertical = true;
      }
      if (hasVertical) return 4;
    }

    // "3" — single open stroke with two bumps
    if (strokeCount == 1 && !closedLoop && crossings == 0 && aspect < 0.8) {
      return 3;
    }

    // "6" — single stroke, closed bottom loop
    if (strokeCount == 1 && closedLoop && aspect < 0.8) {
      return 6;
    }

    // "9" — similar to 6 but loop at top
    if (strokeCount == 1 && closedLoop) {
      final loopCenter = _loopCenter(firstStroke, minY, bh);
      if (loopCenter != null && loopCenter < 0.45) return 9;
      if (loopCenter != null && loopCenter > 0.55) return 6;
    }

    // "5" — two strokes or single with flat top
    if (strokeCount >= 1 && strokeCount <= 2 && aspect > 0.35) {
      return 5;
    }

    // Fallback — can't determine
    return null;
  }

  /// Count crude self-crossings across all strokes.
  int _countSelfCrossings(List<List<Offset>> strokes) {
    final allSegments = <_Segment>[];
    for (final stroke in strokes) {
      for (int i = 0; i + 1 < stroke.length; i += 3) {
        // sample every 3rd segment for speed
        final end = (i + 1 < stroke.length) ? i + 1 : stroke.length - 1;
        allSegments.add(_Segment(stroke[i], stroke[end]));
      }
    }

    int crossings = 0;
    for (int i = 0; i < allSegments.length; i++) {
      for (int j = i + 2; j < allSegments.length; j++) {
        if (_segmentsIntersect(allSegments[i], allSegments[j])) {
          crossings++;
        }
      }
    }
    return crossings;
  }

  double? _loopCenter(List<Offset> stroke, double minY, double bh) {
    if (stroke.length < 4) return null;
    // Find the loop portion (where start/end meet)
    // Approximate by average Y of the closed portion
    final closeThreshold = bh * 0.35;
    for (int i = stroke.length - 1; i > stroke.length ~/ 2; i--) {
      if ((stroke[i] - stroke.first).distance < closeThreshold) {
        double sumY = 0;
        for (int j = 0; j <= i; j++) {
          sumY += stroke[j].dy;
        }
        return (sumY / (i + 1) - minY) / bh;
      }
    }
    return null;
  }

  bool _segmentsIntersect(_Segment a, _Segment b) {
    return _ccw(a.p1, b.p1, b.p2) != _ccw(a.p2, b.p1, b.p2) &&
        _ccw(a.p1, a.p2, b.p1) != _ccw(a.p1, a.p2, b.p2);
  }

  bool _ccw(Offset a, Offset b, Offset c) {
    return (c.dy - a.dy) * (b.dx - a.dx) > (b.dy - a.dy) * (c.dx - a.dx);
  }
}

class _Segment {
  final Offset p1;
  final Offset p2;
  const _Segment(this.p1, this.p2);
}
