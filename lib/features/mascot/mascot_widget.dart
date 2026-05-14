import 'dart:math';
import 'package:flutter/material.dart';

class MascotWidget extends StatefulWidget {
  final String avatar;
  final bool animate;
  final double size;

  const MascotWidget({
    super.key,
    this.avatar = '🐱',
    this.animate = false,
    this.size = 60,
  });

  @override
  State<MascotWidget> createState() => _MascotWidgetState();
}

class _MascotWidgetState extends State<MascotWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _bounce;
  late Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _bounce = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
    );
    _rotation = Tween<double>(begin: -0.1, end: 0.1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );

    if (widget.animate) _ctrl.forward();
  }

  @override
  void didUpdateWidget(MascotWidget old) {
    super.didUpdateWidget(old);
    if (widget.animate && !old.animate) {
      _ctrl.forward().then((_) {
        if (mounted) _ctrl.reverse();
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotation.value * sin(_ctrl.value * pi),
          child: Transform.scale(
            scale: _bounce.value,
            child: child,
          ),
        );
      },
      child: Text(widget.avatar, style: TextStyle(fontSize: widget.size)),
    );
  }
}

const List<String> availableAvatars = [
  '🐱', '🐶', '🐰', '🦊', '🐼', '🐯', '🦁', '🐸', '🐵', '🦄',
];
