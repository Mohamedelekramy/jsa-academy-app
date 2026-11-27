import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_theme.dart';

/// خلفية كحلي متحركة (توهج + جزيئات ذهبية اختيارية)
class AnimatedBackground extends StatefulWidget {
  final Widget child;

  /// الجزيئات الذهبية (بتظهر في الـ Splash بس)
  final bool showParticles;

  const AnimatedBackground({
    super.key,
    required this.child,
    this.showParticles = false,
  });

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, __) => CustomPaint(
              painter: _BgPainter(_c.value, widget.showParticles),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _Particle {
  final double x, y, speed, size, phase;
  const _Particle(this.x, this.y, this.speed, this.size, this.phase);
}

class _BgPainter extends CustomPainter {
  final double t;
  final bool showParticles;
  _BgPainter(this.t, this.showParticles);

  static final List<_Particle> _particles = _make();

  static List<_Particle> _make() {
    final r = math.Random(7);
    return List.generate(
      28,
          (i) => _Particle(
        r.nextDouble(),
        r.nextDouble(),
        (1 + r.nextInt(3)).toDouble(),
        1.5 + r.nextDouble() * 2.5,
        r.nextDouble() * math.pi * 2,
      ),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()..shader = AppGradients.background.createShader(rect),
    );

    final a = t * 2 * math.pi;

    // توهج أزرق
    _glow(
      canvas,
      Offset(size.width * (0.2 + 0.15 * math.sin(a)),
          size.height * (0.22 + 0.08 * math.cos(a))),
      size.width * 0.9,
      AppColors.kids.withValues(alpha: 0.22),
    );

    // توهج ذهبي
    _glow(
      canvas,
      Offset(size.width * (0.85 - 0.12 * math.sin(a + 1)),
          size.height * (0.72 + 0.08 * math.cos(a + 2))),
      size.width * 0.8,
      AppColors.gold.withValues(alpha: 0.12),
    );

    if (!showParticles) return;

    // جزيئات ذهبية بتطفو لفوق
    final p = Paint();
    for (final s in _particles) {
      final y = ((s.y - t * s.speed) % 1.0) * size.height;
      final x = (s.x + 0.015 * math.sin(a * s.speed + s.phase)) * size.width;
      final twinkle = 0.5 + 0.5 * math.sin(a * 2 + s.phase);
      p.color = AppColors.goldLight.withValues(alpha: 0.10 + 0.35 * twinkle);
      canvas.drawCircle(Offset(x, y), s.size, p);
    }
  }

  void _glow(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color, color.withValues(alpha: 0)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _BgPainter old) =>
      old.t != t || old.showParticles != showParticles;
}