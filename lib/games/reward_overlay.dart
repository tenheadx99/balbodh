import 'dart:math';
import 'package:flutter/material.dart';
import '../core/constants/colors.dart';

class RewardOverlay extends StatefulWidget {
  final String message;
  final bool showConfetti;
  final VoidCallback? onComplete;

  const RewardOverlay({
    super.key,
    this.message = 'Great Job!',
    this.showConfetti = true,
    this.onComplete,
  });

  @override
  State<RewardOverlay> createState() => _RewardOverlayState();
}

class _RewardOverlayState extends State<RewardOverlay>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late AnimationController _confettiController;
  final List<_ConfettiParticle> _particles = [];

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );
    _scaleController.forward();

    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    if (widget.showConfetti) {
      _confettiController.repeat();

      final random = Random();
      for (int i = 0; i < 30; i++) {
        _particles.add(_ConfettiParticle(
          x: random.nextDouble(),
          delay: random.nextDouble(),
          color: AppColors.bubbleColors[random.nextInt(AppColors.bubbleColors.length)],
          size: 6 + random.nextDouble() * 8,
          speed: 0.5 + random.nextDouble() * 1.0,
        ));
      }

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _confettiController.stop();
          widget.onComplete?.call();
        }
      });
    } else {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) widget.onComplete?.call();
      });
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (widget.showConfetti)
          AnimatedBuilder(
            animation: _confettiController,
            builder: (context, _) {
              return CustomPaint(
                size: Size.infinite,
                painter: _ConfettiPainter(
                  particles: _particles,
                  progress: _confettiController.value,
                ),
              );
            },
          ),
        Center(
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '⭐',
                    style: TextStyle(fontSize: 64),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.message,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ConfettiParticle {
  final double x;
  final double delay;
  final Color color;
  final double size;
  final double speed;

  _ConfettiParticle({
    required this.x,
    required this.delay,
    required this.color,
    required this.size,
    required this.speed,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final pProgress = ((progress - p.delay) / p.speed).clamp(0.0, 1.0);
      if (pProgress <= 0 || pProgress >= 1) continue;

      final y = size.height * (1 - pProgress);
      final wobble = sin(pProgress * 20) * 20;
      final x = size.width * p.x + wobble;

      final opacity = (1 - pProgress).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), p.size * (1 - pProgress * 0.3), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}
