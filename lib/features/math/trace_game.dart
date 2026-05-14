import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/audio/audio_service.dart';

class TraceGame extends StatefulWidget {
  const TraceGame({super.key});

  @override
  State<TraceGame> createState() => _TraceGameState();
}

class _TraceGameState extends State<TraceGame> {
  final AudioService _audio = AudioService();
  final List<Offset> _points = [];
  final Set<int> _completedNumbers = {};
  int _currentNumber = 1;
  int _stars = 0;

  @override
  void initState() {
    super.initState();
    _speakNumber();
  }

  void _speakNumber() {
    _audio.speakEnglish('Trace number $_currentNumber');
  }

  void _checkCompletion() {
    if (_points.length > 20) {
      _completedNumbers.add(_currentNumber);
      _stars++;
      _audio.speakEnglish('Great! Number $_currentNumber!');

      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        setState(() {
          _points.clear();
          if (_currentNumber < 20) {
            _currentNumber++;
            _speakNumber();
          } else {
            _audio.speakEnglish('You did it! All numbers!');
          }
        });
      });
    }
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
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('⭐', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 4),
                Text(
                  '$_stars',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberDisplay() {
    return Column(
      children: [
        Text(
          _currentNumber > 20 ? '🎉 All Done!' : 'Trace $_currentNumber',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        if (_currentNumber <= 20)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Draw over the dotted line',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textDark.withValues(alpha: 0.6),
              ),
            ),
          ),
        const SizedBox(height: 8),
        if (_currentNumber <= 20)
          Text(
            '$_currentNumber',
            style: TextStyle(
              fontSize: 72,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark.withValues(alpha: 0.2),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
      ],
    );
  }

  Widget _buildTracePad() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
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
              return GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _points.add(details.localPosition);
                  });
                  _checkCompletion();
                },
                onPanEnd: (_) {
                  // Keep points visible
                },
                child: CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: _TracePainter(
                    points: _points,
                    number: _currentNumber,
                    completedNumbers: _completedNumbers,
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton.icon(
            onPressed: () {
              setState(() => _points.clear());
            },
            icon: const Icon(Icons.clear, color: AppColors.textDark),
            label: const Text('Clear',
                style: TextStyle(color: AppColors.textDark)),
          ),
          const SizedBox(width: 24),
          if (_currentNumber > 1 && _currentNumber <= 20)
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _currentNumber--;
                  _points.clear();
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
  final Set<int> completedNumbers;

  _TracePainter({
    required this.points,
    required this.number,
    required this.completedNumbers,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final dashedPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);

    final digitPoints = _getDigitPoints(number, center, size.shortestSide * 0.3);
    for (int i = 0; i < digitPoints.length - 1; i++) {
      final p = digitPoints[i];
      final q = digitPoints[i + 1];
      path.moveTo(p.dx, p.dy);
      path.addPolygon([p, q], false);
    }

    canvas.drawPath(path, dashedPaint);

    if (points.isEmpty) return;

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
      ..color = AppColors.accent.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], glowPaint);
    }
  }

  List<Offset> _getDigitPoints(int n, Offset center, double r) {
    final list = <Offset>[];
    switch (n % 10) {
      case 0:
        list.addAll(_rectPath(
            Offset(center.dx - r, center.dy - r),
            Offset(center.dx + r, center.dy + r)));
        break;
      case 1:
        list.add(Offset(center.dx, center.dy - r));
        list.add(Offset(center.dx, center.dy + r));
        break;
      case 2:
        list.add(Offset(center.dx - r * 0.5, center.dy - r));
        list.add(Offset(center.dx + r * 0.5, center.dy - r));
        list.add(Offset(center.dx + r * 0.7, center.dy - r * 0.2));
        list.add(Offset(center.dx - r * 0.5, center.dy + r * 0.3));
        list.add(Offset(center.dx + r * 0.5, center.dy + r));
        list.add(Offset(center.dx - r * 0.5, center.dy + r));
        break;
      case 3:
        list.add(Offset(center.dx - r * 0.5, center.dy - r));
        list.add(Offset(center.dx + r * 0.5, center.dy - r));
        list.add(Offset(center.dx + r * 0.3, center.dy));
        list.add(Offset(center.dx + r * 0.5, center.dy));
        list.add(Offset(center.dx + r * 0.5, center.dy + r));
        list.add(Offset(center.dx - r * 0.5, center.dy + r));
        break;
      case 4:
        list.add(Offset(center.dx - r * 0.5, center.dy - r));
        list.add(Offset(center.dx - r * 0.5, center.dy));
        list.add(Offset(center.dx + r * 0.5, center.dy));
        list.add(Offset(center.dx + r * 0.5, center.dy - r));
        list.add(Offset(center.dx + r * 0.5, center.dy + r));
        break;
      case 5:
        list.add(Offset(center.dx + r * 0.5, center.dy - r));
        list.add(Offset(center.dx - r * 0.5, center.dy - r));
        list.add(Offset(center.dx - r * 0.5, center.dy));
        list.add(Offset(center.dx + r * 0.5, center.dy));
        list.add(Offset(center.dx + r * 0.5, center.dy + r));
        list.add(Offset(center.dx - r * 0.5, center.dy + r));
        break;
      case 6:
        list.addAll(_getDigitPoints(5, center, r));
        list.add(Offset(center.dx - r * 0.5, center.dy));
        break;
      case 7:
        list.add(Offset(center.dx - r * 0.5, center.dy - r));
        list.add(Offset(center.dx + r * 0.5, center.dy - r));
        list.add(Offset(center.dx + r * 0.3, center.dy + r));
        break;
      case 8:
        list.addAll(_rectPath(
            Offset(center.dx - r * 0.6, center.dy - r),
            Offset(center.dx + r * 0.6, center.dy + r)));
        break;
      case 9:
        list.addAll(_getDigitPoints(5, center, r));
        list.add(Offset(center.dx - r * 0.5, center.dy));
        break;
    }
    return list;
  }

  List<Offset> _rectPath(Offset tl, Offset br) {
    return [
      tl,
      Offset(br.dx, tl.dy),
      br,
      Offset(tl.dx, br.dy),
      tl,
    ];
  }

  @override
  bool shouldRepaint(covariant _TracePainter oldDelegate) => true;
}
