import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/core_state.dart';

const double _tau = math.pi * 2;

Color _a(Color c, double opacity) =>
    c.withAlpha((opacity.clamp(0.0, 1.0) * 255).round());

Offset _polar(Offset c, double angle, double radius) =>
    Offset(c.dx + math.cos(angle) * radius, c.dy + math.sin(angle) * radius);

/// Animated circular AI core. Each [CoreState] has its own motion.
/// The animation loops every 24 s; all speeds are whole cycles per loop
/// so the loop is seamless. Respects the system "remove animations" setting.
class AiCore extends StatefulWidget {
  const AiCore({super.key, required this.state, this.size = 320});

  final CoreState state;
  final double size;

  @override
  State<AiCore> createState() => _AiCoreState();
}

class _AiCoreState extends State<AiCore> with SingleTickerProviderStateMixin {
  late final AnimationController _anim =
      AnimationController(vsync: this, duration: const Duration(seconds: 24));

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
    return Semantics(
      label: 'AI core, ${widget.state.label}',
      child: RepaintBoundary(
        child: TweenAnimationBuilder<Color?>(
          tween: ColorTween(end: widget.state.color),
          duration: const Duration(milliseconds: 450),
          builder: (context, color, _) => CustomPaint(
            size: Size.square(widget.size),
            painter: AiCorePainter(
              anim: _anim,
              state: widget.state,
              color: color ?? widget.state.color,
            ),
          ),
        ),
      ),
    );
  }
}

class AiCorePainter extends CustomPainter {
  AiCorePainter({required this.anim, required this.state, required this.color})
      : super(repaint: anim);

  final Animation<double> anim;
  final CoreState state;
  final Color color;

  // Ring rotation in whole cycles per 24 s loop (negative = counter-clockwise).
  static const Map<CoreState, List<int>> _speeds = {
    CoreState.idle: [1, -2, 3, -1],
    CoreState.listening: [2, -2, 3, -3],
    CoreState.thinking: [10, -14, 8, -6],
    CoreState.speaking: [2, -3, 3, -2],
    CoreState.executing: [4, -4, 6, -6],
    CoreState.error: [0, 0, 0, 0],
    CoreState.offline: [0, 0, 0, 0],
  };
  static const Map<CoreState, int> _breathK = {
    CoreState.idle: 4,
    CoreState.listening: 12,
    CoreState.thinking: 24,
    CoreState.speaking: 8,
    CoreState.executing: 6,
    CoreState.error: 30,
    CoreState.offline: 2,
  };
  static const Map<CoreState, double> _breathAmp = {
    CoreState.idle: 0.05,
    CoreState.listening: 0.07,
    CoreState.thinking: 0.04,
    CoreState.speaking: 0.08,
    CoreState.executing: 0.03,
    CoreState.error: 0.06,
    CoreState.offline: 0.02,
  };

  @override
  void paint(Canvas canvas, Size size) {
    final t = anim.value;
    final ph = t * _tau;
    final c = size.center(Offset.zero);
    final r = math.min(size.width, size.height) / 2;

    final dim = state == CoreState.offline ? 0.55 : 1.0;
    final flick =
        state == CoreState.error && math.sin(ph * 53) > 0.7 ? 0.35 : 1.0;
    final a = dim * flick;
    final sp = _speeds[state]!;
    final jit = state == CoreState.error ? math.sin(ph * 37) * 0.12 : 0.0;
    double rot(int i) => ph * sp[i] + jit * (i + 1);
    final breath = 1 + _breathAmp[state]! * math.sin(ph * _breathK[state]!);

    // Glow
    final glowR = r * 0.62 * breath;
    canvas.drawCircle(
      c,
      glowR,
      Paint()
        ..shader = RadialGradient(
          colors: [_a(color, 0.55 * a), _a(color, 0.18 * a), _a(color, 0)],
          stops: const [0, 0.45, 1],
        ).createShader(Rect.fromCircle(center: c, radius: glowR)),
    );

    // Listening: ripples converging on the core
    if (state == CoreState.listening) {
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      for (var i = 0; i < 3; i++) {
        final k = (t * 8 + i / 3) % 1.0;
        p.color = _a(color, (1 - k) * k * 2);
        canvas.drawCircle(c, r * (0.95 - 0.55 * k), p);
      }
    }

    // Executing: radar sweep
    if (state == CoreState.executing) {
      final rect = Rect.fromCircle(center: c, radius: r * 0.88);
      canvas.drawCircle(
        c,
        r * 0.88,
        Paint()
          ..shader = SweepGradient(
            colors: [_a(color, 0), _a(color, 0), _a(color, 0.5 * a)],
            stops: const [0, 0.75, 1],
            transform: GradientRotation(ph * 4),
          ).createShader(rect),
      );
    }

    // Tick marks
    final tick = Paint()
      ..strokeWidth = 1
      ..color = _a(color, 0.3 * a);
    final tickR = r * 0.94;
    for (var i = 0; i < 60; i++) {
      final ang = rot(3) + i / 60 * _tau;
      final len = r * (i % 5 == 0 ? 0.035 : 0.018);
      canvas.drawLine(_polar(c, ang, tickR), _polar(c, ang, tickR - len), tick);
    }

    // Rings
    final broken = state == CoreState.error;
    final offline = state == CoreState.offline;
    _ring(canvas, c, r * 0.34, rot(0), 1, 1.0, 1.2, _a(color, 0.4 * a));
    _ring(canvas, c, r * 0.50, rot(1), 3, broken ? 0.4 : 0.62, 6,
        _a(color, 0.3 * a), blur: 6);
    _ring(canvas, c, r * 0.50, rot(1), 3, broken ? 0.4 : 0.62, 3,
        _a(color, 0.9 * a));
    _ring(canvas, c, r * 0.68, rot(2), offline ? 24 : 36, offline ? 0.3 : 0.5,
        2, _a(color, 0.6 * a));
    _ring(canvas, c, r * 0.86, rot(3), 2, 0.3, 1.6, _a(color, 0.75 * a));

    // Speaking: radial bars (decorative motion, not audio-reactive)
    if (state == CoreState.speaking) {
      final bar = Paint()
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = _a(color, 0.9);
      for (var i = 0; i < 72; i++) {
        final ang = i / 72 * _tau;
        final amp = 0.5 + 0.5 * math.sin(ph * 6 + i * 0.55);
        final amp2 = 0.5 + 0.5 * math.sin(ph * 9 - i * 1.1);
        final len = r * (0.015 + 0.075 * amp * amp2);
        canvas.drawLine(
            _polar(c, ang, r * 0.56), _polar(c, ang, r * 0.56 + len), bar);
      }
    }

    // Thinking: orbiting dots with trails
    if (state == CoreState.thinking) {
      final dot = Paint();
      for (var i = 0; i < 3; i++) {
        final base = ph * 5 + i * _tau / 3;
        for (var j = 0; j < 8; j++) {
          final f = 1 - j / 8;
          dot.color = _a(color, f);
          canvas.drawCircle(_polar(c, base - j * 0.09, r * 0.77), 3.2 * f + 0.6, dot);
        }
      }
    }

    // Core disc
    final dr = r * 0.17 * breath;
    canvas.drawCircle(
      c,
      dr,
      Paint()
        ..shader = RadialGradient(
          colors: [
            _a(Colors.white, 0.95 * a),
            _a(color, 0.9 * a),
            _a(color, 0.15 * a),
          ],
          stops: const [0, 0.55, 1],
        ).createShader(Rect.fromCircle(center: c, radius: dr)),
    );
  }

  void _ring(Canvas canvas, Offset c, double radius, double rotation, int count,
      double fill, double width, Color col,
      {double blur = 0}) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..color = col;
    if (blur > 0) p.maskFilter = MaskFilter.blur(BlurStyle.normal, blur);
    final slot = _tau / count;
    final rect = Rect.fromCircle(center: c, radius: radius);
    for (var i = 0; i < count; i++) {
      canvas.drawArc(rect, rotation + i * slot, slot * fill, false, p);
    }
  }

  @override
  bool shouldRepaint(AiCorePainter old) =>
      old.state != state || old.color != color;
}
