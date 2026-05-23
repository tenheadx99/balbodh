import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/audio/audio_service.dart';
import '../../core/audio/sound_effect_service.dart';
import '../../services/progress_service.dart';

class CrayonCanvasGame extends StatefulWidget {
  const CrayonCanvasGame({super.key});

  @override
  State<CrayonCanvasGame> createState() => _CrayonCanvasGameState();
}

class _CrayonCanvasGameState extends State<CrayonCanvasGame> with TickerProviderStateMixin {
  final AudioService _audio = AudioService();
  final SoundEffectService _sfx = SoundEffectService();
  final ProgressService _progress = ProgressService();

  final List<DrawingStroke> _strokes = [];
  DrawingStroke? _currentStroke;

  Color _selectedColor = const Color(0xFFFF4D4D);
  double _strokeWidth = 10.0;
  bool _isRainbow = false;
  int _stars = 0;

  String _currentTemplate = '⭐ Star';
  late AnimationController _sparkleController;

  final List<Map<String, dynamic>> _templates = [
    {'name': '⭐ Star', 'icon': '⭐', 'sound': 'Let\'s color the star!'},
    {'name': '❤️ Heart', 'icon': '❤️', 'sound': 'Color the lovely heart!'},
    {'name': '🌙 Moon', 'icon': '🌙', 'sound': 'Color the beautiful crescent moon!'},
    {'name': '☀️ Sun', 'icon': '☀️', 'sound': 'Color the bright sun!'},
    {'name': '🍎 Apple', 'icon': '🍎', 'sound': 'Color the delicious red apple!'},
    {'name': '🌳 Tree', 'icon': '🌳', 'sound': 'Let\'s paint a green tree!'},
  ];

  final List<Color> _crayonColors = [
    const Color(0xFFFF4D4D), // Red
    const Color(0xFFFF9F43), // Orange
    const Color(0xFFFFD2FF), // Pink
    const Color(0xFFFFEB3B), // Yellow
    const Color(0xFF4CAF50), // Green
    const Color(0xFF2196F3), // Blue
    const Color(0xFF9C27B0), // Purple
    const Color(0xFF795548), // Brown
  ];

  @override
  void initState() {
    super.initState();
    _stars = _progress.totalStarsAcrossModules;
    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    
    _audio.speakEnglish('Welcome to Crayon Canvas! Choose a crayon and color the shape!');
  }

  @override
  void dispose() {
    _sparkleController.dispose();
    _audio.dispose();
    super.dispose();
  }

  void _onTemplateSelected(Map<String, dynamic> template) {
    _sfx.playTap();
    setState(() {
      _currentTemplate = template['name'];
      _strokes.clear();
    });
    _audio.speakEnglish(template['sound']);
  }

  void _onColorSelected(Color color, bool isRainbow) {
    _sfx.playPop();
    setState(() {
      _selectedColor = color;
      _isRainbow = isRainbow;
    });
  }

  void _clearCanvas() {
    _sfx.playTap();
    setState(() {
      _strokes.clear();
    });
    _audio.speakEnglish('Clean page! Ready to draw again.');
  }

  void _saveDrawing() {
    _sfx.playFanfare();
    _progress.addStar('games');
    setState(() {
      _stars++;
    });
    _audio.speakEnglish('Beautiful drawing! You earned a star!');
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('🎉 Masterpiece Saved!', textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.textDark)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🌈', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 12),
            const Text('Your colored shape looks spectacular! Keep drawing!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: AppColors.textDark)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Okay!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE0F7FA), Color(0xFF80DEEA)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              _buildTemplateSelector(),
              Expanded(child: _buildDrawingArea()),
              _buildBrushControls(),
              _buildCrayonBox(),
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
            icon: const Icon(Icons.arrow_back, size: 32, color: AppColors.textDark),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Spacer(),
          const Text(
            '🎨 Crayon Canvas',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Text('⭐ ', style: TextStyle(fontSize: 18)),
                Text('$_stars', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateSelector() {
    return Container(
      height: 64,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _templates.length,
        itemBuilder: (ctx, i) {
          final t = _templates[i];
          final isSelected = t['name'] == _currentTemplate;
          return GestureDetector(
            onTap: () => _onTemplateSelected(t),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(right: 10, top: 4, bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (isSelected ? AppColors.primary : Colors.grey).withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text(t['icon'], style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 6),
                  Text(
                    t['name'].split(' ')[1],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white : AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDrawingArea() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: GestureDetector(
          onPanStart: (details) {
            setState(() {
              final List<Offset> points = [details.localPosition];
              _currentStroke = DrawingStroke(
                points: points,
                color: _isRainbow ? Colors.red : _selectedColor,
                strokeWidth: _strokeWidth,
                isRainbow: _isRainbow,
              );
              _strokes.add(_currentStroke!);
            });
          },
          onPanUpdate: (details) {
            setState(() {
              if (_currentStroke != null) {
                _currentStroke!.points.add(details.localPosition);
              }
            });
          },
          onPanEnd: (_) {
            _currentStroke = null;
          },
          child: CustomPaint(
            painter: _CanvasPainter(
              strokes: _strokes,
              templateName: _currentTemplate,
              sparkleVal: _sparkleController.value,
            ),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }

  Widget _buildBrushControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Row(
        children: [
          const Text('✏️ Size: ', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textDark)),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.secondary,
                thumbColor: AppColors.secondary,
                overlayColor: AppColors.secondary.withValues(alpha: 0.2),
              ),
              child: Slider(
                value: _strokeWidth,
                min: 4.0,
                max: 30.0,
                onChanged: (val) {
                  setState(() {
                    _strokeWidth = val;
                  });
                },
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: AppColors.primary, size: 28),
            onPressed: _clearCanvas,
            tooltip: 'Clear Drawing',
          ),
          IconButton(
            icon: const Icon(Icons.check_circle, color: AppColors.success, size: 30),
            onPressed: _saveDrawing,
            tooltip: 'Save Masterpiece',
          ),
        ],
      ),
    );
  }

  Widget _buildCrayonBox() {
    return Container(
      height: 110,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _crayonColors.length + 1,
        itemBuilder: (ctx, idx) {
          final isRainbowCrayon = idx == _crayonColors.length;
          final color = isRainbowCrayon ? Colors.white : _crayonColors[idx];
          final isSelected = isRainbowCrayon ? _isRainbow : (_selectedColor == color && !_isRainbow);

          return GestureDetector(
            onTap: () => _onColorSelected(color, isRainbowCrayon),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              width: 48,
              height: isSelected ? 90 : 76,
              transform: Matrix4.translationValues(0, isSelected ? -10 : 0, 0),
              decoration: BoxDecoration(
                gradient: isRainbowCrayon
                    ? const LinearGradient(
                        colors: [
                          Colors.red,
                          Colors.orange,
                          Colors.yellow,
                          Colors.green,
                          Colors.blue,
                          Colors.purple
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      )
                    : null,
                color: isRainbowCrayon ? null : color,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isRainbowCrayon ? Colors.purple : color).withValues(alpha: 0.4),
                    blurRadius: isSelected ? 8 : 4,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: isRainbowCrayon
                    ? const Text('🌈', style: TextStyle(fontSize: 22))
                    : isSelected
                        ? const Text('✏️', style: TextStyle(fontSize: 20, color: Colors.white))
                        : null,
              ),
            ),
          );
        },
      ),
    );
  }
}

class DrawingStroke {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final bool isRainbow;

  DrawingStroke({
    required this.points,
    required this.color,
    required this.strokeWidth,
    required this.isRainbow,
  });
}

class _CanvasPainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  final String templateName;
  final double sparkleVal;

  _CanvasPainter({
    required this.strokes,
    required this.templateName,
    required this.sparkleVal,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw outline template shape
    _drawTemplateOutline(canvas, size);

    // 2. Draw user strokes
    for (final stroke in strokes) {
      if (stroke.points.length < 2) continue;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = stroke.strokeWidth;

      if (stroke.isRainbow) {
        // Draw with rainbow gradient stroke!
        for (int i = 0; i < stroke.points.length - 1; i++) {
          final ratio = i / stroke.points.length;
          paint.color = HSVColor.fromAHSV(1.0, ratio * 360, 0.9, 0.95).toColor();
          canvas.drawLine(stroke.points[i], stroke.points[i + 1], paint);
        }
      } else {
        paint.color = stroke.color;
        for (int i = 0; i < stroke.points.length - 1; i++) {
          canvas.drawLine(stroke.points[i], stroke.points[i + 1], paint);
        }
      }
    }
  }

  void _drawTemplateOutline(Canvas canvas, Size size) {
    final outlinePaint = Paint()
      ..color = AppColors.textDark.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    final dashPaint = Paint()
      ..color = AppColors.textDark.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = min(size.width, size.height) * 0.32;

    if (templateName.contains('Star')) {
      final path = _getStarPath(cx, cy, 5, r, r * 0.45);
      canvas.drawPath(path, outlinePaint);
      _drawDashedPath(canvas, path, dashPaint);
    } else if (templateName.contains('Heart')) {
      final path = _getHeartPath(cx, cy, r * 1.1);
      canvas.drawPath(path, outlinePaint);
      _drawDashedPath(canvas, path, dashPaint);
    } else if (templateName.contains('Moon')) {
      final path = Path()
        ..addArc(Rect.fromCircle(center: Offset(cx - r * 0.25, cy), radius: r), -pi * 0.45, pi * 0.9)
        ..arcToPoint(
          Offset(cx - r * 0.25 + r * cos(-pi * 0.45), cy + r * sin(-pi * 0.45)),
          radius: Radius.circular(r * 0.8),
          clockwise: false,
        );
      canvas.drawPath(path, outlinePaint);
      _drawDashedPath(canvas, path, dashPaint);
    } else if (templateName.contains('Sun')) {
      // Draw inner circle
      canvas.drawCircle(Offset(cx, cy), r * 0.6, outlinePaint);
      canvas.drawCircle(Offset(cx, cy), r * 0.6, dashPaint);
      // Rays
      final numRays = 8;
      for (int i = 0; i < numRays; i++) {
        final angle = (i * 2 * pi) / numRays;
        final startX = cx + cos(angle) * (r * 0.75);
        final startY = cy + sin(angle) * (r * 0.75);
        final endX = cx + cos(angle) * r;
        final endY = cy + sin(angle) * r;
        canvas.drawLine(Offset(startX, startY), Offset(endX, endY), outlinePaint);
        canvas.drawLine(Offset(startX, startY), Offset(endX, endY), dashPaint);
      }
    } else if (templateName.contains('Apple')) {
      final path = Path()
        ..moveTo(cx, cy - r * 0.6)
        ..cubicTo(cx + r * 0.5, cy - r * 0.9, cx + r * 0.9, cy - r * 0.3, cx + r * 0.7, cy + r * 0.3)
        ..cubicTo(cx + r * 0.6, cy + r * 0.7, cx + r * 0.2, cy + r * 0.8, cx, cy + r * 0.6)
        ..cubicTo(cx - r * 0.2, cy + r * 0.8, cx - r * 0.6, cy + r * 0.7, cx - r * 0.7, cy + r * 0.3)
        ..cubicTo(cx - r * 0.9, cy - r * 0.3, cx - r * 0.5, cy - r * 0.9, cx, cy - r * 0.6)
        ..close();
      
      // Stem
      final stemPath = Path()
        ..moveTo(cx, cy - r * 0.6)
        ..quadraticBezierTo(cx + r * 0.15, cy - r * 0.85, cx + r * 0.25, cy - r * 0.9);
      
      canvas.drawPath(path, outlinePaint);
      _drawDashedPath(canvas, path, dashPaint);
      canvas.drawPath(stemPath, outlinePaint);
      canvas.drawPath(stemPath, dashPaint);
    } else if (templateName.contains('Tree')) {
      // Trunk
      final trunk = Path()
        ..moveTo(cx - r * 0.15, cy + r * 0.1)
        ..lineTo(cx - r * 0.15, cy + r * 0.7)
        ..lineTo(cx + r * 0.15, cy + r * 0.7)
        ..lineTo(cx + r * 0.15, cy + r * 0.1)
        ..close();
      
      // Fluffy leaves
      final foliage = Path()
        ..addOval(Rect.fromCircle(center: Offset(cx, cy - r * 0.15), radius: r * 0.52))
        ..addOval(Rect.fromCircle(center: Offset(cx - r * 0.3, cy + r * 0.05), radius: r * 0.38))
        ..addOval(Rect.fromCircle(center: Offset(cx + r * 0.3, cy + r * 0.05), radius: r * 0.38));

      canvas.drawPath(trunk, outlinePaint);
      canvas.drawPath(foliage, outlinePaint);
      _drawDashedPath(canvas, trunk, dashPaint);
      _drawDashedPath(canvas, foliage, dashPaint);
    }
  }

  Path _getStarPath(double cx, double cy, int spikes, double outerRadius, double innerRadius) {
    final path = Path();
    var rot = pi / 2 * 3;
    var x = cx;
    var y = cy;
    final step = pi / spikes;

    path.moveTo(cx, cy - outerRadius);
    for (int i = 0; i < spikes; i++) {
      x = cx + cos(rot) * outerRadius;
      y = cy + sin(rot) * outerRadius;
      path.lineTo(x, y);
      rot += step;

      x = cx + cos(rot) * innerRadius;
      y = cy + sin(rot) * innerRadius;
      path.lineTo(x, y);
      rot += step;
    }
    path.lineTo(cx, cy - outerRadius);
    path.close();
    return path;
  }

  Path _getHeartPath(double cx, double cy, double r) {
    final path = Path();
    final d = r * 0.8;
    path.moveTo(cx, cy + d * 0.45);
    path.cubicTo(cx - d * 0.6, cy - d * 0.4, cx - d * 1.1, cy - d * 1.0, cx, cy - d * 0.8);
    path.moveTo(cx, cy + d * 0.45);
    path.cubicTo(cx + d * 0.6, cy - d * 0.4, cx + d * 1.1, cy - d * 1.0, cx, cy - d * 0.8);
    return path;
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    // Simple dash approximation by drawing circles/short segments over path metrics
    try {
      final metrics = path.computeMetrics();
      for (final metric in metrics) {
        double distance = 0.0;
        while (distance < metric.length) {
          final tangent = metric.getTangentForOffset(distance);
          if (tangent != null) {
            canvas.drawCircle(tangent.position, 1.5, paint);
          }
          distance += 12.0; // gap size
        }
      }
    } catch (_) {
      // Fallback in case of computeMetrics errors
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CanvasPainter oldDelegate) =>
      strokes != oldDelegate.strokes ||
      templateName != oldDelegate.templateName ||
      sparkleVal != oldDelegate.sparkleVal;
}
