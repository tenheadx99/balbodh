import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/audio/audio_service.dart';
import '../../core/audio/sound_effect_service.dart';

class TraceGame extends StatefulWidget {
  const TraceGame({super.key});

  @override
  State<TraceGame> createState() => _TraceGameState();
}

class _TraceGameState extends State<TraceGame> {
  final AudioService _audio = AudioService();
  final SoundEffectService _sfx = SoundEffectService();

  final List<Offset> _points = [];
  final Set<int> _completedNumbers = {};
  int _currentNumber = 1;
  int _stars = 0;
  double _coverage = 0.0;
  bool _showingSuccess = false;
  bool _allDone = false;

  @override
  void initState() {
    super.initState();
    _speakNumber();
  }

  void _speakNumber() {
    _audio.speakEnglish('Trace number $_currentNumber');
  }

  List<Offset> _digitWaypoints(int n, Offset center, double size) {
    final r = size * 0.4;
    final segs = <Offset>[];
    void add(double x, double y) => segs.add(Offset(center.dx + x * r, center.dy + y * r));

    switch (n % 10) {
      case 1:
        add(0, -1); add(0, 1);
        break;
      case 2:
        add(0.8, -1); add(-0.8, -1); add(-0.8, 0);
        add(0.8, 0); add(0.8, 1); add(-0.8, 1);
        break;
      case 3:
        add(-0.8, -1); add(0.8, -1); add(0.8, 0);
        add(-0.5, 0); add(0.8, 0); add(0.8, 1); add(-0.8, 1);
        break;
      case 4:
        add(-0.8, -1); add(-0.8, 0); add(0.8, 0);
        add(0.8, -1); add(0.8, 1);
        break;
      case 5:
        add(0.8, -1); add(-0.8, -1); add(-0.8, -0.2);
        add(0.8, -0.2); add(0.8, 0.6); add(-0.8, 0.6);
        add(-0.8, 1); add(0.8, 1);
        break;
      case 6:
        add(0.8, -1); add(-0.8, -1); add(-0.8, 0);
        add(0.8, 0); add(0.8, 1); add(-0.8, 1); add(-0.8, 0.5);
        break;
      case 7:
        add(-0.8, -1); add(0.8, -1); add(0.8, -0.4);
        add(0.4, 0.2); add(0.4, 1);
        break;
      case 8:
        add(0, -1); add(0.8, -0.4); add(0, 0);
        add(0.8, 0.4); add(0, 1); add(-0.8, 0.4);
        add(0, 0); add(-0.8, -0.4); add(0, -1);
        break;
      case 9:
        add(0, 1); add(0.8, 1); add(0.8, 0);
        add(-0.8, 0); add(-0.8, -1); add(0, -1);
        add(0.5, -1); add(0.8, -0.7);
        break;
      case 0:
        add(-0.7, -1); add(0.7, -1); add(0.7, 1);
        add(-0.7, 1); add(-0.7, -1);
        break;
    }
    return segs;
  }

  List<Offset> _getFullPath(int number, Offset center, double size) {
    final path = <Offset>[];
    if (number < 10) {
      path.addAll(_digitWaypoints(number, center, size));
    } else {
      final tens = number ~/ 10;
      final ones = number % 10;
      final tensCenter = Offset(center.dx - size * 0.25, center.dy);
      final onesCenter = Offset(center.dx + size * 0.25, center.dy);
      path.addAll(_digitWaypoints(tens, tensCenter, size * 0.6));
      path.addAll(_digitWaypoints(ones, onesCenter, size * 0.6));
    }
    return path;
  }

  List<Offset> _sampleGuidePath(int number, Offset center, double size,
      {double spacing = 8}) {
    final waypoints = _getFullPath(number, center, size);
    if (waypoints.isEmpty) return [];

    final sampled = <Offset>[];
    for (int i = 0; i < waypoints.length - 1; i++) {
      final a = waypoints[i];
      final b = waypoints[i + 1];
      final dist = (b - a).distance;
      final steps = (dist / spacing).ceil().clamp(1, 50);
      for (int s = 0; s <= steps; s++) {
        final t = s / steps;
        sampled.add(Offset(
          a.dx + (b.dx - a.dx) * t,
          a.dy + (b.dy - a.dy) * t,
        ));
      }
    }
    return sampled;
  }

  double _calcCoverage(List<Offset> guidePath, List<Offset> drawn) {
    if (guidePath.isEmpty || drawn.length < 3) return 0.0;

    const tolerance = 30.0;
    int covered = 0;

    for (final gp in guidePath) {
      for (final dp in drawn) {
        if ((dp - gp).distance < tolerance) {
          covered++;
          break;
        }
      }
    }
    return covered / guidePath.length;
  }

  void _onDraw(Offset point) {
    if (_showingSuccess || _allDone) return;

    setState(() => _points.add(point));

    if (_points.length % 3 != 0) return;

    if (_currentNumber > 20) return;
    final center = Offset(
      MediaQuery.of(context).size.width / 2,
      MediaQuery.of(context).size.height / 2.5,
    );
    final size = MediaQuery.of(context).size.shortestSide;
    final guidePath = _sampleGuidePath(_currentNumber, center, size);

    _coverage = _calcCoverage(guidePath, _points);

    if (_coverage >= 0.65) {
      _onComplete();
    }
  }

  void _onComplete() {
    _showingSuccess = true;
    _completedNumbers.add(_currentNumber);
    _stars++;
    _sfx.playCorrect();
    _audio.speakEnglish('Great! Number $_currentNumber!');

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() {
        _points.clear();
        _coverage = 0.0;
        _showingSuccess = false;
        if (_currentNumber < 20) {
          _currentNumber++;
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
          _buildBadge('$_stars', '⭐'),
          const SizedBox(width: 8),
          _buildBadge('$_currentNumber/20', '🔢'),
          const SizedBox(width: 8),
          _buildBadge('${(_coverage * 100).toInt()}%', '📐'),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, String emoji) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
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
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text('🎉', style: TextStyle(fontSize: 48)),
            SizedBox(height: 8),
            Text(
              'All Numbers 1-20\nMastered!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Text(
            'Trace $_currentNumber',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Finger trace over the dotted line',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textDark.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 4),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: _coverage.clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 200),
            builder: (context, value, _) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: value,
                  backgroundColor: Colors.white.withValues(alpha: 0.5),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    value > 0.5 ? AppColors.success : AppColors.accent,
                  ),
                  minHeight: 8,
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${(_coverage * 100).toInt()}% traced',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textDark.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTracePad() {
    return Padding(
      padding: const EdgeInsets.all(20),
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
              return GestureDetector(
                onPanDown: (d) {
                  _onDraw(d.localPosition);
                },
                onPanUpdate: (d) {
                  _onDraw(d.localPosition);
                },
                child: RepaintBoundary(
                  child: CustomPaint(
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                    painter: _TracePainter(
                      points: _points,
                      number: _currentNumber,
                      coverage: _coverage,
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
  final double coverage;
  final bool showingSuccess;

  _TracePainter({
    required this.points,
    required this.number,
    required this.coverage,
    required this.showingSuccess,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (number > 20) return;

    final center = Offset(size.width / 2, size.height / 2);
    final r = min(size.width, size.height) * 0.35;

    final waypoints = _getDigitWaypoints(number, center, r);

    _drawGuideLine(canvas, waypoints, size);
    _drawStartMarker(canvas, waypoints);
    if (points.length >= 2) {
      _drawTrace(canvas);
    }
    if (showingSuccess) {
      _drawSuccessOverlay(canvas, size);
    }
  }

  List<Offset> _getDigitWaypoints(int n, Offset center, double r) {
    final segs = <Offset>[];
    void add(double x, double y) => segs.add(Offset(center.dx + x * r, center.dy + y * r));

    switch (n % 10) {
      case 1: add(0, -1); add(0, 1); break;
      case 2:
        add(0.8, -1); add(-0.8, -1); add(-0.8, 0);
        add(0.8, 0); add(0.8, 1); add(-0.8, 1);
        break;
      case 3:
        add(-0.8, -1); add(0.8, -1); add(0.8, 0);
        add(-0.5, 0); add(0.8, 0); add(0.8, 1); add(-0.8, 1);
        break;
      case 4:
        add(-0.8, -1); add(-0.8, 0); add(0.8, 0);
        add(0.8, -1); add(0.8, 1);
        break;
      case 5:
        add(0.8, -1); add(-0.8, -1); add(-0.8, -0.2);
        add(0.8, -0.2); add(0.8, 0.6); add(-0.8, 0.6);
        add(-0.8, 1); add(0.8, 1);
        break;
      case 6:
        add(0.8, -1); add(-0.8, -1); add(-0.8, 0);
        add(0.8, 0); add(0.8, 1); add(-0.8, 1); add(-0.8, 0.5);
        break;
      case 7:
        add(-0.8, -1); add(0.8, -1); add(0.8, -0.4);
        add(0.4, 0.2); add(0.4, 1);
        break;
      case 8:
        add(0, -1); add(0.8, -0.4); add(0, 0);
        add(0.8, 0.4); add(0, 1); add(-0.8, 0.4);
        add(0, 0); add(-0.8, -0.4); add(0, -1);
        break;
      case 9:
        add(0, 1); add(0.8, 1); add(0.8, 0);
        add(-0.8, 0); add(-0.8, -1); add(0, -1);
        add(0.5, -1); add(0.8, -0.7);
        break;
      case 0:
        add(-0.7, -1); add(0.7, -1); add(0.7, 1);
        add(-0.7, 1); add(-0.7, -1);
        break;
    }
    return segs;
  }

  void _drawGuideLine(Canvas canvas, List<Offset> waypoints, Size size) {
    if (waypoints.isEmpty) return;

    final paint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < waypoints.length - 1; i++) {
      final a = waypoints[i];
      final b = waypoints[i + 1];
      _drawDashedLine(canvas, a, b, paint);
    }
  }

  void _drawDashedLine(Canvas canvas, Offset a, Offset b, Paint paint) {
    final dx = b.dx - a.dx;
    final dy = b.dy - a.dy;
    final dist = sqrt(dx * dx + dy * dy);
    if (dist < 1) return;

    const dashLen = 8.0;
    const gapLen = 6.0;
    final total = dashLen + gapLen;
    final steps = (dist / total).ceil();

    for (int i = 0; i < steps; i++) {
      final t0 = (i * total) / dist;
      final t1 = min((i * total + dashLen) / dist, 1.0);
      canvas.drawLine(
        Offset(a.dx + dx * t0, a.dy + dy * t0),
        Offset(a.dx + dx * t1, a.dy + dy * t1),
        paint,
      );
    }
  }

  void _drawStartMarker(Canvas canvas, List<Offset> waypoints) {
    if (waypoints.isEmpty) return;

    final start = waypoints.first;
    final paint = Paint()
      ..color = AppColors.success
      ..style = PaintingStyle.fill;

    canvas.drawCircle(start, 10, paint);

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(start, 10, borderPaint);

    final textPainter = TextPainter(
      text: const TextSpan(
        text: '▶',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(start.dx - textPainter.width / 2,
          start.dy - textPainter.height / 2),
    );
  }

  void _drawTrace(Canvas canvas) {
    final tracePaint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], tracePaint);
    }

    final glowPaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], glowPaint);
    }
  }

  void _drawSuccessOverlay(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.success.withValues(alpha: 0.3);

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
