import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/audio/audio_service.dart';
import '../../core/audio/sound_effect_service.dart';
import '../../models/number_letter.dart';
import '../../services/progress_service.dart';

class TraceGame extends StatefulWidget {
  const TraceGame({super.key});

  @override
  State<TraceGame> createState() => _TraceGameState();
}

class _TraceGameState extends State<TraceGame> {
  final AudioService _audio = AudioService();
  final SoundEffectService _sfx = SoundEffectService();
  final ProgressService _progress = ProgressService();

  final List<Offset> _points = [];
  final Set<int> _completedNumbers = {};
  int _currentNumber = 1;
  int _stars = 0;
  double _coverage = 0.0;
  bool _showingSuccess = false;
  bool _allDone = false;

  double _traceW = 300;
  double _traceH = 300;
  final List<Offset> _samplePoints = [];

  @override
  void initState() {
    super.initState();
    _speakNumber();
  }

  void _speakNumber() {
    final word = NumberLetter.wordFor(_currentNumber);
    _audio.speakEnglish('Trace number $word');
  }

  /// Generates sample points that lie on the actual rendered strokes of [number]
  /// by rasterising the digit text and sampling pixels from the text painter.
  /// We use a dense grid approach: lay a grid over the digit bounding box and
  /// pick points that are likely on a stroke (centre of the glyph area).
  void _generateSamplePoints(double w, double h, int number) {
    _samplePoints.clear();

    // Lay out the digit with the same style used in _TracePainter
    final fontSize = w * 0.50;
    final tp = TextPainter(
      text: TextSpan(
        text: '$number',
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          color: Colors.black,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout(maxWidth: w);

    final glyphW = tp.width;
    final glyphH = tp.height;
    final left = (w - glyphW) / 2;
    final top = (h - glyphH) / 2;

    // Divide the glyph rect into a grid and record all interior cells
    const cols = 10;
    const rows = 10;
    final cellW = glyphW / cols;
    final cellH = glyphH / rows;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final cx = left + (c + 0.5) * cellW;
        final cy = top + (r + 0.5) * cellH;
        _samplePoints.add(Offset(cx, cy));
      }
    }
  }

  double _calcCoverage(List<Offset> drawn) {
    if (drawn.length < 5 || _samplePoints.isEmpty) return 0.0;

    // Tolerance: how close a drawn point must be to a sample point to "cover" it.
    // Use ~8% of the trace width so it scales with screen size.
    final tolerance = _traceW * 0.08;
    int covered = 0;

    for (final sp in _samplePoints) {
      for (final dp in drawn) {
        if ((dp - sp).distance < tolerance) {
          covered++;
          break;
        }
      }
    }
    return covered / _samplePoints.length;
  }

  void _onDraw(Offset point) {
    if (_showingSuccess || _allDone) return;

    _points.add(point);

    // Recalculate coverage every 3 points for responsiveness
    if (_points.length % 3 == 0) {
      _coverage = _calcCoverage(_points);
      if (_coverage >= 0.55) {
        // Threshold: 55% of the glyph grid covered
        _onComplete();
        return;
      }
    }
    setState(() {});
  }

  void _onComplete() {
    if (_showingSuccess) return; // guard against double-fire
    _showingSuccess = true;
    _completedNumbers.add(_currentNumber);
    _stars++;
    _sfx.playCorrect();
    final word = NumberLetter.wordFor(_currentNumber);
    _audio.speakEnglish('Great! Number $word!');

    // Record progress
    _progress.recordAttempt('math', '$_currentNumber', true);
    _progress.addStar('math');

    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() {
        _points.clear();
        _coverage = 0.0;
        _showingSuccess = false;
        if (_currentNumber < 20) {
          _currentNumber++;
          // Regenerate sample points for the new number
          _generateSamplePoints(_traceW, _traceH, _currentNumber);
          _speakNumber();
        } else {
          _allDone = true;
          _sfx.playFanfare();
          _audio.speakEnglish('You did it! All numbers 1 to 20!');
        }
      });
    });
  }

  @override
  void dispose() {
    _audio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE1BEE7), Color(0xFFF3E5F5)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              _buildNumberDisplay(),
              Expanded(child: _buildTracePad()),
              _buildControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final label = _allDone
        ? '🎉'
        : _showingSuccess
            ? '✅'
            : '📐 ${(_coverage * 100).toInt()}%';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back,
                size: 32, color: AppColors.textDark),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Spacer(),
          _badge('$_stars', '⭐'),
          const SizedBox(width: 8),
          _badge('$_currentNumber/20', '🔢'),
          const SizedBox(width: 8),
          _badge(label, ''),
        ],
      ),
    );
  }

  Widget _badge(String text, String emoji) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (emoji.isNotEmpty) ...[
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberDisplay() {
    if (_allDone) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            Text('🎉', style: TextStyle(fontSize: 48)),
            Text(
              'All Numbers 1-20\nMastered!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 2),
      child: Text(
        _showingSuccess ? 'Great!' : 'Finger paint over the number',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  Widget _buildTracePad() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            color: _showingSuccess
                ? AppColors.success.withValues(alpha: 0.15)
                : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (_allDone) {
                return const Center(
                  child: Text('🎉', style: TextStyle(fontSize: 80)),
                );
              }

              final w = constraints.maxWidth;
              final h = constraints.maxHeight;
              // Regenerate sample points whenever size or number changes
              if (w != _traceW || h != _traceH ||
                  _samplePoints.isEmpty) {
                _traceW = w;
                _traceH = h;
                _generateSamplePoints(w, h, _currentNumber);
              }

              return GestureDetector(
                onPanDown: (d) => _onDraw(d.localPosition),
                onPanUpdate: (d) => _onDraw(d.localPosition),
                child: RepaintBoundary(
                  child: CustomPaint(
                    size: Size(w, h),
                    painter: _TracePainter(
                      points: _points,
                      number: _currentNumber,
                      showingSuccess: _showingSuccess,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    if (_allDone) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.home),
          label: const Text('Go Home'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton.icon(
            onPressed: () => setState(() {
              _points.clear();
              _coverage = 0.0;
            }),
            icon: const Icon(Icons.clear, color: AppColors.textDark),
            label: const Text('Clear',
                style: TextStyle(color: AppColors.textDark)),
          ),
          const SizedBox(width: 24),
          if (_currentNumber > 1)
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _currentNumber--;
                  _points.clear();
                  _coverage = 0.0;
                  // Regenerate sample points for the new number
                  _generateSamplePoints(_traceW, _traceH, _currentNumber);
                });
                _speakNumber();
              },
              icon: const Icon(Icons.undo, color: AppColors.textDark),
              label: const Text('Back',
                  style: TextStyle(color: AppColors.textDark)),
            ),
        ],
      ),
    );
  }
}

class _TracePainter extends CustomPainter {
  final List<Offset> points;
  final int number;
  final bool showingSuccess;

  _TracePainter({
    required this.points,
    required this.number,
    required this.showingSuccess,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (number > 20) return;

    _drawDigitTemplate(canvas, size, number);
    _drawSampleDots(canvas, size, number);

    if (points.length >= 2) {
      _drawTrace(canvas);
    }

    if (showingSuccess) {
      _drawSuccessOverlay(canvas, size);
    }
  }

  void _drawDigitTemplate(Canvas canvas, Size size, int n) {
    final text = n > 20 ? '' : '$n';
    if (text.isEmpty) return;

    final fontSize = size.width * 0.50;

    final textStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      color: AppColors.textDark.withValues(alpha: 0.08),
    );

    final tp = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    tp.layout(maxWidth: size.width);

    final x = (size.width - tp.width) / 2;
    final y = (size.height - tp.height) / 2;

    canvas.save();
    canvas.translate(x, y);

    tp.paint(canvas, Offset.zero);

    canvas.restore();
  }

  void _drawSampleDots(Canvas canvas, Size size, int n) {
    final rng = Random(n * 37 + 42);
    final textScale = size.width * 0.55;
    final textW = textScale * _digitWidthFactor(n);
    final textH = textScale;
    final left = (size.width - textW) / 2;
    final top = (size.height - textH) / 2;

    final dotPaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 40; i++) {
      final x = left + rng.nextDouble() * textW;
      final y = top + rng.nextDouble() * textH;
      canvas.drawCircle(Offset(x, y), 3, dotPaint);
    }
  }

  double _digitWidthFactor(int n) {
    if (n < 10) return 0.55;
    return _digitWidthFactor(n % 10) + _digitWidthFactor(n ~/ 10) + 0.25;
  }

  void _drawTrace(Canvas canvas) {
    final tracePaint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], tracePaint);
    }

    final glowPaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], glowPaint);
    }
  }

  void _drawSuccessOverlay(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.success.withValues(alpha: 0.25);
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.shortestSide * 0.3,
      paint,
    );

    const text = '✓';
    final tp = TextPainter(
      text: const TextSpan(
        text: text,
        style: TextStyle(
          color: AppColors.success,
          fontSize: 64,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(
      canvas,
      Offset(
        size.width / 2 - tp.width / 2,
        size.height / 2 - tp.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _TracePainter oldDelegate) => true;
}
