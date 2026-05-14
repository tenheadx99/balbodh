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

class _BubbleWidgetState extends State<BubbleWidget>
    with TickerProviderStateMixin {
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
    _wobbleController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500 + _random.nextInt(1000)),
    )..repeat(reverse: true);

    _wobbleAnimation = Tween<double>(begin: -0.05, end: 0.05).animate(
      CurvedAnimation(parent: _wobbleController, curve: Curves.easeInOut),
    );

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(begin: -0.3, end: 0.3).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
    );
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
    setState(() => _shaking = true);
    _shakeController.forward().then((_) {
      if (mounted) {
        _shakeController.reverse();
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

    return Positioned(
      left: widget.xPosition - widget.size / 2,
      top: widget.yPosition - widget.size / 2,
      child: GestureDetector(
        onTap: _onTap,
        child: AnimatedBuilder(
          animation: _wobbleAnimation,
          builder: (context, child) {
            final angle = _shaking
                ? _shakeAnimation.value
                : _wobbleAnimation.value;
            return Transform.rotate(
              angle: angle,
              child: child,
            );
          },
          child: AnimatedScale(
            scale: widget.isHinted ? 1.2 : 1.0,
            duration: const Duration(milliseconds: 500),
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    widget.color.withValues(alpha: 0.9),
                    widget.color.withValues(alpha: 0.6),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  widget.letter.displayName,
                  style: TextStyle(
                    fontSize: widget.size * 0.45,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 8,
                        color: Colors.black.withValues(alpha: 0.3),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
