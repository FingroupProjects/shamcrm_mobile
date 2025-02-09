import 'dart:math' as math;
import 'package:flutter/material.dart';

class ParticleDeleteEffect extends StatefulWidget {
  final Widget child;
  final VoidCallback onComplete;
  final bool startAnimation;

  const ParticleDeleteEffect({
    Key? key,
    required this.child,
    required this.onComplete,
    required this.startAnimation,
  }) : super(key: key);

  @override
  _ParticleDeleteEffectState createState() => _ParticleDeleteEffectState();
}

class _ParticleDeleteEffectState extends State<ParticleDeleteEffect> with TickerProviderStateMixin {
  late List<Particle> particles;
  late AnimationController _controller;
  final int particleCount = 50;
  bool isAnimating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ParticleDeleteEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.startAnimation && !isAnimating) {
      _startAnimation();
    }
  }

  void _startAnimation() {
    isAnimating = true;
    _initializeParticles();
    _controller.forward(from: 0.0);
  }

  void _initializeParticles() {
    particles = List.generate(particleCount, (index) {
      final random = math.Random();
      final angle = random.nextDouble() * 2 * math.pi;
      final velocity = random.nextDouble() * 100 + 50;
      final size = random.nextDouble() * 4 + 2;

      return Particle(
        angle: angle,
        velocity: velocity,
        size: size,
        color: Color(0xff1E2E52).withOpacity(random.nextDouble() * 0.6 + 0.4),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        if (!isAnimating) {
          return widget.child;
        }

        return CustomPaint(
          size: Size(100, 100), // Размер контейнера файла
          painter: ParticlePainter(
            particles: particles,
            progress: _controller.value,
          ),
          child: Opacity(
            opacity: 1 - _controller.value,
            child: widget.child,
          ),
        );
      },
    );
  }
}

class Particle {
  final double angle;
  final double velocity;
  final double size;
  final Color color;

  Particle({
    required this.angle,
    required this.velocity,
    required this.size,
    required this.color,
  });
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double progress;

  ParticlePainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (final particle in particles) {
      final distance = particle.velocity * progress;
      final dx = math.cos(particle.angle) * distance;
      final dy = math.sin(particle.angle) * distance;
      final position = center + Offset(dx, dy);

      final paint = Paint()
        ..color = particle.color.withOpacity(1 - progress)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        position,
        particle.size * (1 - progress),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
}
