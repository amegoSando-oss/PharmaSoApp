import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Soft colored circles that rise up from the bottom of the login header,
/// then drift freely and bounce off the edges forever so they never
/// disappear. Tapping one sends it flying off in a new random direction
/// within the same space.
class InteractiveBubbles extends StatefulWidget {
  const InteractiveBubbles({
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
    this.seed = 21,
  });

  final int count;
  final double minSize;
  final double maxSize;
  final List<Color> colors;
  final int seed;

  @override
  State<InteractiveBubbles> createState() => _InteractiveBubblesState();
}

class _Bubble {
  _Bubble({required this.size, required this.color, required this.speed});

  final double size;
  final Color color;
  final double speed;
  double vx = 0;
  double vy = 0;
  double x = 0;
  double y = 0;
  double targetY = 0;
  bool rising = false;
  bool placed = false;
}

class _InteractiveBubblesState extends State<InteractiveBubbles> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  late final List<_Bubble> _bubbles;
  final Random _rnd = Random();
  Size _size = Size.zero;
  Duration _lastElapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    final seededRnd = Random(widget.seed);
    _bubbles = List.generate(widget.count, (i) {
      return _Bubble(
        size: widget.minSize + seededRnd.nextDouble() * (widget.maxSize - widget.minSize),
        color: widget.colors[seededRnd.nextInt(widget.colors.length)].withValues(alpha: 0.16 + seededRnd.nextDouble() * 0.22),
        speed: 14 + seededRnd.nextDouble() * 16,
      );
    });
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    if (_size.isEmpty) return;
    if (!_bubbles.first.placed) {
      final placeRnd = Random(widget.seed ^ 0x5bd1e995);
      for (final b in _bubbles) {
        final r = b.size / 2;
        final w = _size.width, h = _size.height;
        b.x = w <= r * 2 ? w / 2 : r + placeRnd.nextDouble() * (w - r * 2);
        b.targetY = h <= r * 2 ? h / 2 : r + placeRnd.nextDouble() * (h - r * 2);
        // Start below the visible area so the bubble enters by rising up
        // into the header, rather than just fading in in place.
        b.y = h + r;
        b.vy = -b.speed;
        b.rising = true;
        b.placed = true;
      }
      _lastElapsed = elapsed;
      setState(() {});
      return;
    }

    final dtMs = (elapsed - _lastElapsed).inMilliseconds;
    _lastElapsed = elapsed;
    if (dtMs <= 0 || dtMs > 100) return;
    final dt = dtMs / 1000.0;

    for (final b in _bubbles) {
      final r = b.size / 2;
      if (b.rising) {
        b.y += b.vy * dt;
        if (b.y <= b.targetY) {
          b.y = b.targetY;
          _launchRandomly(b);
        }
        continue;
      }
      b.x += b.vx * dt;
      b.y += b.vy * dt;
      if (b.x - r < 0) {
        b.x = r;
        b.vx = b.vx.abs();
      } else if (b.x + r > _size.width) {
        b.x = _size.width - r;
        b.vx = -b.vx.abs();
      }
      if (b.y - r < 0) {
        b.y = r;
        b.vy = b.vy.abs();
      } else if (b.y + r > _size.height) {
        b.y = _size.height - r;
        b.vy = -b.vy.abs();
      }
    }
    setState(() {});
  }

  void _launchRandomly(_Bubble b) {
    b.rising = false;
    final angle = _rnd.nextDouble() * 2 * pi;
    b.vx = cos(angle) * b.speed;
    b.vy = sin(angle) * b.speed;
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTapUp(TapUpDetails details) {
    _Bubble? nearest;
    double nearestDist = double.infinity;
    for (final b in _bubbles) {
      final dist = (Offset(b.x, b.y) - details.localPosition).distance;
      if (dist <= b.size / 2 * 1.3 && dist < nearestDist) {
        nearest = b;
        nearestDist = dist;
      }
    }
    if (nearest == null) return;
    _launchRandomly(nearest);
  }

  @override
  Widget build(BuildContext context) {
    // Isolated in its own compositor layer so the ~60fps repaint driven by
    // the animation doesn't force the rest of the page (or, worse, the
    // destination screen while a Hero flight is being computed) to redraw
    // alongside it on every tick.
    return LayoutBuilder(
      builder: (context, constraints) {
        _size = constraints.biggest;
        return RepaintBoundary(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTapUp: _onTapUp,
            child: CustomPaint(
              size: Size.infinite,
              painter: _BubblePainter(_bubbles),
            ),
          ),
        );
      },
    );
  }
}

class _BubblePainter extends CustomPainter {
  _BubblePainter(this.bubbles) : super(repaint: null);

  final List<_Bubble> bubbles;

  @override
  void paint(Canvas canvas, Size size) {
    for (final b in bubbles) {
      if (!b.placed) continue;
      canvas.drawCircle(Offset(b.x, b.y), b.size / 2, Paint()..color = b.color);
    }
  }

  @override
  bool shouldRepaint(covariant _BubblePainter oldDelegate) => true;
}
