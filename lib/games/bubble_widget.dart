import 'dart:math';
import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../models/bubble_letter.dart';

class BubbleWidget extends StatefulWidget {
  final BubbleLetter letter;
  final double xPosition;
  final double yPosition;
  final double size;
  final Color color;
  final bool isTarget;
  final VoidCallback onPopped;
  final VoidCallback onWrong;
  final bool isHinted;

  const BubbleWidget({
    super.key,
    required this.letter,
    required this.xPosition,
    required this.yPosition,
    this.size = 80,
    this.color = AppColors.primary,
    this.isTarget = false,
    required this.onPopped,
    required this.onWrong,
    this.isHinted = false,
  });

  @override
  State<BubbleWidget> createState() => _BubbleWidgetState();
}

class _BubbleWidgetState extends State<BubbleWidget> with TickerProviderStateMixin {
  late AnimationController _wobbleController;
  late Animation<double> _wobbleAnimation;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  bool _popped = false;
  bool _shaking = false;

  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    
    // Smooth breathing wobble animation
    _wobbleController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1600 + _random.nextInt(800)),
    )..repeat(reverse: true);

    _wobbleAnimation = Tween<double>(begin: -0.06, end: 0.06).animate(
      CurvedAnimation(parent: _wobbleController, curve: Curves.easeInOut),
    );

    // Shake animation for incorrect taps
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -0.15), weight: 25),
      TweenSequenceItem(tween: Tween(begin: -0.15, end: 0.15), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.15, end: 0.0), weight: 25),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(BubbleWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isHinted && !oldWidget.isHinted) {
      if (mounted) setState(() {});
    }
  }

  void _onTap() {
    if (_popped) return;
    if (widget.isTarget) {
      setState(() => _popped = true);
      widget.onPopped();
    } else {
      _startShake();
      widget.onWrong();
    }
  }

  void _startShake() {
    if (_shaking) return;
    setState(() => _shaking = true);
    _shakeController.forward(from: 0.0).then((_) {
      if (mounted) {
        setState(() => _shaking = false);
      }
    });
  }

  @override
  void dispose() {
    _wobbleController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_popped) return const SizedBox.shrink();

    // Scale up slightly if hinted to draw user's eye
    final double hintedScale = widget.isHinted ? 1.22 : 1.0;

    return Positioned(
      left: widget.xPosition - widget.size / 2,
      top: widget.yPosition - widget.size / 2,
      child: GestureDetector(
        onTap: _onTap,
        child: AnimatedBuilder(
          animation: Listenable.merge([_wobbleAnimation, _shakeAnimation]),
          builder: (context, child) {
            final angle = _shaking ? _shakeAnimation.value : _wobbleAnimation.value;
            return Transform.rotate(
              angle: angle,
              child: child,
            );
          },
          child: AnimatedScale(
            scale: hintedScale,
            duration: const Duration(milliseconds: 400),
            curve: Curves.elasticOut,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.45),
                  width: 2.0,
                ),
                gradient: RadialGradient(
                  center: const Alignment(-0.25, -0.3),
                  radius: 0.9,
                  colors: [
                    Colors.white.withValues(alpha: 0.4),
                    widget.color.withValues(alpha: 0.65),
                    widget.color.withValues(alpha: 0.95),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.4),
                    blurRadius: 14,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Upper-left glossy specular highlight glint
                  Positioned(
                    left: widget.size * 0.15,
                    top: widget.size * 0.12,
                    child: Container(
                      width: widget.size * 0.28,
                      height: widget.size * 0.15,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.all(
                          Radius.elliptical(widget.size * 0.14, widget.size * 0.075),
                        ),
                      ),
                    ),
                  ),

                  // Lower-right subtle inner rim reflection
                  Positioned(
                    right: widget.size * 0.15,
                    bottom: widget.size * 0.15,
                    child: Container(
                      width: widget.size * 0.18,
                      height: widget.size * 0.18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                  ),

                  // Display character / number text
                  Center(
                    child: Text(
                      widget.letter.displayName,
                      style: TextStyle(
                        fontSize: widget.size * 0.46,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            blurRadius: 6,
                            color: Colors.black.withValues(alpha: 0.35),
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
