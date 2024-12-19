import 'package:flutter/material.dart';
import 'neon_painter.dart';

class AnimatedBackground extends StatefulWidget {
  final Color color;
  final Widget child;

  const AnimatedBackground({
    super.key,
    required this.color,
    required this.child,
  });

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: NeonPainter(
                color: widget.color,
                progress: _controller.value,
              ),
              child: Container(),
            );
          },
        ),
        widget.child,
      ],
    );
  }
}
