import 'dart:math';

import 'package:flutter/material.dart';

/// Soft colored circles that drift upward and sway, looping forever.
/// Used behind the brand mark on the splash screen so it feels alive while
/// the app boots.
class AnimatedBubbles extends StatefulWidget {
  const AnimatedBubbles({
    super.key,
    this.count = 3,
    this.minSize = 120,
    this.maxSize = 220,
    this.colors = const [
      Color(0xFF6EE7B7),
      Color(0xFFA7F3D0),
      Color(0xFF34D399),
      Color(0xFF5EEAD4),
      Color(0xFFFDE68A),
      Color(0xFF7DD3FC),
      Colors.white,
    ],
    this.duration = const Duration(seconds: 10),
    this.seed = 21,
  });

  final int count;
  final double minSize;
  final double maxSize;
  final List<Color> colors;
  final Duration duration;
  final int seed;

  @override
  State<AnimatedBubbles> createState() => _AnimatedBubblesState();
}

class _Bubble {
  _Bubble({required this.dx, required this.size, required this.color, required this.speed, required this.phase, required this.wobble});

  final double dx;
  final double size;
  final Color color;
  final double speed;
  final double phase;
  final double wobble;
}

class _AnimatedBubblesState extends State<AnimatedBubbles> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Bubble> _bubbles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)..repeat();
    final rnd = Random(widget.seed);
    _bubbles = List.generate(widget.count, (i) {
      return _Bubble(
        dx: rnd.nextDouble(),
        size: widget.minSize + rnd.nextDouble() * (widget.maxSize - widget.minSize),
        color: widget.colors[rnd.nextInt(widget.colors.length)].withValues(alpha: 0.16 + rnd.nextDouble() * 0.22),
        speed: 0.5 + rnd.nextDouble() * 0.9,
        phase: rnd.nextDouble(),
        wobble: 10 + rnd.nextDouble() * 20,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Isolated in its own compositor layer so the ~60fps repaint driven by
    // the animation doesn't force the rest of the page (or, worse, the
    // destination screen while a Hero flight is being computed) to redraw
    // alongside it on every tick.
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          size: Size.infinite,
          painter: _BubblePainter(bubbles: _bubbles, t: _controller.value),
        ),
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  _BubblePainter({required this.bubbles, required this.t});

  final List<_Bubble> bubbles;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    for (final b in bubbles) {
      final progress = (t * b.speed + b.phase) % 1.0;
      final y = size.height * (1 - progress) - b.size / 2;
      final sway = sin((progress * 2 * pi) + b.phase * 10) * b.wobble;
      final x = (b.dx * size.width + sway).clamp(0.0, size.width);
      canvas.drawCircle(Offset(x, y), b.size / 2, Paint()..color = b.color);
    }
  }

  @override
  bool shouldRepaint(covariant _BubblePainter oldDelegate) => oldDelegate.t != t;
}
