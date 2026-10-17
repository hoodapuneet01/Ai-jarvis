import 'dart:math' as math;

import 'package:flutter/material.dart';

class _Particle {
  _Particle(math.Random rnd)
      : x = rnd.nextDouble(),
        y0 = rnd.nextDouble(),
        size = 0.6 + rnd.nextDouble() * 1.4,
        cycles = 1 + rnd.nextInt(2),
        twinkle = 2 + rnd.nextInt(5),
        phase = rnd.nextDouble() * math.pi * 2;

  final double x, y0, size, phase;
  final int cycles, twinkle;
}

/// Sparse, slow-drifting dots behind the interface. Loops seamlessly.
class ParticleField extends StatefulWidget {
  const ParticleField({super.key, required this.color});

  final Color color;

  @override
  State<ParticleField> createState() => _ParticleFieldState();
}

class _ParticleFieldState extends State<ParticleField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim =
      AnimationController(vsync: this, duration: const Duration(seconds: 24));
  late final List<_Particle> _particles = () {
    final rnd = math.Random(7);
    return List.generate(36, (_) => _Particle(rnd));
  }();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _anim.stop();
    } else if (!_anim.isAnimating) {
      _anim.repeat();
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _ParticlePainter(_anim, _particles, widget.color),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter(this.anim, this.particles, this.color) : super(repaint: anim);

  final Animation<double> anim;
  final List<_Particle> particles;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final t = anim.value;
    final paint = Paint();
    for (final p in particles) {
      final y = (p.y0 - t * p.cycles) % 1.0;
      final tw = 0.5 + 0.5 * math.sin(t * math.pi * 2 * p.twinkle + p.phase);
      paint.color = color.withAlpha(((0.10 + 0.20 * tw) * 255).round());
      canvas.drawCircle(Offset(p.x * size.width, y * size.height), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.color != color;
}
