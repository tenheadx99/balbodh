import 'dart:async';
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

class _TraceGameState extends State<TraceGame> with SingleTickerProviderStateMixin {
  final AudioService _audio = AudioService();
  final SoundEffectService _sfx = SoundEffectService();
  final ProgressService _progress = ProgressService();
  final Random _random = Random();

  final List<Offset> _points = [];
  final List<_TraceSparkle> _sparkles = [];
  final Set<int> _completedNumbers = {};
  int _currentNumber = 1;
  int _stars = 0;
  double _coverage = 0.0;
  bool _showingSuccess = false;
  bool _allDone = false;

  double _traceW = 300;
  double _traceH = 300;
  final List<Offset> _samplePoints = [];

  // Ticker for real-time trace sparkle physics
  late AnimationController _tickerController;

  @override
  void initState() {
    super.initState();
    _speakNumber();

    _tickerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_updateSparkles);
    _tickerController.repeat();
  }

  void _updateSparkles() {
    if (!mounted) return;
    setState(() {
      for (final s in _sparkles) {
        s.x += s.vx;
        s.y += s.vy;
        s.vy += 0.15; // soft gravity
        s.life -= 0.05;
      }
      _sparkles.removeWhere((s) => s.life <= 0);
    });
  }

  void _speakNumber() {
    final word = NumberLetter.wordFor(_currentNumber);
    _audio.speakEnglish('Trace number $word');
  }

  void _generateSamplePoints(double w, double h, int number) {
    _samplePoints.clear();

    final fontSize = w * 0.55;
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

    const cols = 12;
    const rows = 12;
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

    final tolerance = _traceW * 0.09;
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

    // Spawn cute glittering stars under user's finger!
    for (int i = 0; i < 2; i++) {
      final angle = _random.nextDouble() * 2 * pi;
      final speed = 0.5 + _random.nextDouble() * 1.8;
      _sparkles.add(_TraceSparkle(
        x: point.dx,
        y: point.dy,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed - 0.5,
        color: Colors.amberAccent.shade200,
      ));
    }

    if (_points.length % 3 == 0) {
      _coverage = _calcCoverage(_points);
      if (_coverage >= 0.52) {
        _onComplete();
        return;
      }
    }
    setState(() {});
  }

  void _onComplete() {
    if (_showingSuccess) return; 
    _showingSuccess = true;
    _completedNumbers.add(_currentNumber);
    _stars++;
    _sfx.playCorrect();
    final word = NumberLetter.wordFor(_currentNumber);
    _audio.speakEnglish('Great! Number $word!');

    _progress.recordAttempt('math', '$_currentNumber', true);
    _progress.addStar('math');

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      setState(() {
        _points.clear();
        _coverage = 0.0;
        _showingSuccess = false;
        if (_currentNumber < 20) {
          _currentNumber++;
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
    _tickerController.dispose();
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
            colors: [Color(0xFFEDE7F6), Color(0xFFD1C4E9)], // Beautiful play study lavender colors
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
            icon: const Icon(Icons.arrow_back, size: 32, color: AppColors.textDark),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
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
              fontWeight: FontWeight.w900,
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
        _showingSuccess ? 'Great Job!' : '🎨 Trace inside the path with your finger!',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: AppColors.textDark.withValues(alpha: 0.75),
        ),
      ),
    );
  }

  Widget _buildTracePad() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1B5E20), // School green chalkboard texture
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFF8D6E63), width: 8), // Elegant wood frame border
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
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
              
              if (w != _traceW || h != _traceH || _samplePoints.isEmpty) {
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
                      sparkles: _sparkles,
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
            label: const Text('Clear board', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 24),
          if (_currentNumber > 1)
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _currentNumber--;
                  _points.clear();
                  _coverage = 0.0;
                  _generateSamplePoints(_traceW, _traceH, _currentNumber);
                });
                _speakNumber();
              },
              icon: const Icon(Icons.undo, color: AppColors.textDark),
              label: const Text('Previous', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }
}

class _TraceSparkle {
  double x;
  double y;
  double vx;
  double vy;
  double life = 1.0;
  Color color;

  _TraceSparkle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
  });
}

class _TracePainter extends CustomPainter {
  final List<Offset> points;
  final List<_TraceSparkle> sparkles;
  final int number;
  final bool showingSuccess;

  _TracePainter({
    required this.points,
    required this.sparkles,
    required this.number,
    required this.showingSuccess,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (number > 20) return;

    _drawChalkTemplate(canvas, size, number);

    // Draw the continuous crayon line
    if (points.length >= 2) {
      _drawRainbowCrayonTrace(canvas);
    }

    // Draw dynamic sparkling stars under finger
    _drawSparkles(canvas);

    if (showingSuccess) {
      _drawSuccessCheckmark(canvas, size);
    }
  }

  void _drawChalkTemplate(Canvas canvas, Size size, int n) {
    final text = '$n';
    final fontSize = size.width * 0.58;

    final textStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      color: Colors.white.withValues(alpha: 0.12), // faint template guidelines on chalkboard
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

  void _drawRainbowCrayonTrace(Canvas canvas) {
    // Elegant glow trace
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    // Dynamic rainbow crayon cycling path
    final tracePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (int i = 0; i < points.length - 1; i++) {
      // Dynamic HSV brush color transition
      final hue = (i * 3.0) % 360;
      final brushColor = HSVColor.fromAHSV(1.0, hue, 0.85, 0.95).toColor();

      glowPaint.color = brushColor.withValues(alpha: 0.3);
      tracePaint.color = brushColor;

      canvas.drawLine(points[i], points[i + 1], glowPaint);
      canvas.drawLine(points[i], points[i + 1], tracePaint);
    }
  }

  void _drawSparkles(Canvas canvas) {
    final starPaint = Paint()..style = PaintingStyle.fill;
    
    for (final s in sparkles) {
      starPaint.color = s.color.withValues(alpha: s.life.clamp(0.0, 1.0));
      
      // Draw standard beautiful 4-point star sparkles
      final path = Path();
      final radius = 6.0 * s.life;
      path.moveTo(s.x, s.y - radius);
      path.quadraticBezierTo(s.x, s.y, s.x + radius, s.y);
      path.quadraticBezierTo(s.x, s.y, s.x, s.y + radius);
      path.quadraticBezierTo(s.x, s.y, s.x - radius, s.y);
      path.quadraticBezierTo(s.x, s.y, s.x, s.y - radius);
      path.close();
      
      canvas.drawPath(path, starPaint);
    }
  }

  void _drawSuccessCheckmark(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.success.withValues(alpha: 0.28);
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.shortestSide * 0.32,
      paint,
    );

    const text = '✓';
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: AppColors.success,
          fontSize: 84,
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
