import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../physics/physics_engine.dart';
import '../physics/rigid_polygon.dart';
import '../physics/particle_and_gear.dart';

class PhysicsPainter extends CustomPainter {
  final PhysicsEngine engine;
  final bool showGears;
  final bool showLaserGlow;

  PhysicsPainter({
    required this.engine,
    this.showGears = true,
    this.showLaserGlow = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (showGears) {
      for (var gear in engine.gears) {
        _drawGear(canvas, gear);
      }
    }

    for (var body in engine.bodies) {
      _drawPolygon(canvas, body);
    }

    for (var laser in engine.lasers) {
      if (laser.isActive) {
        _drawLaser(canvas, laser);
      }
    }

    for (var particle in engine.particles) {
      _drawParticle(canvas, particle);
    }
  }

  void _drawGear(Canvas canvas, ShredderGear gear) {
    final center = Offset(gear.center.x, gear.center.y);

    final Paint gearPaint = Paint()
      ..shader = RadialGradient(
        colors: [const Color(0xFF4A5568), const Color(0xFF1A202C)],
      ).createShader(Rect.fromCircle(center: center, radius: gear.radius))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, gear.radius, gearPaint);

    final Paint toothPaint = Paint()
      ..color = const Color(0xFF718096)
      ..style = PaintingStyle.fill;

    double angleStep = (2 * math.pi) / gear.teethCount;
    for (int i = 0; i < gear.teethCount; i++) {
      double angle = gear.currentAngle + i * angleStep;

      final path = Path();
      double rIn = gear.radius - 4;
      double rOut = gear.radius + gear.toothDepth;

      double a1 = angle - angleStep * 0.2;
      double a2 = angle + angleStep * 0.2;

      path.moveTo(center.dx + rIn * math.cos(a1), center.dy + rIn * math.sin(a1));
      path.lineTo(center.dx + rOut * math.cos(angle - angleStep * 0.1), center.dy + rOut * math.sin(angle - angleStep * 0.1));
      path.lineTo(center.dx + rOut * math.cos(angle + angleStep * 0.1), center.dy + rOut * math.sin(angle + angleStep * 0.1));
      path.lineTo(center.dx + rIn * math.cos(a2), center.dy + rIn * math.sin(a2));
      path.close();

      canvas.drawPath(path, toothPaint);
    }

    final Paint shaftPaint = Paint()
      ..color = const Color(0xFF2D3748)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, gear.radius * 0.3, shaftPaint);

    final Paint shaftBorder = Paint()
      ..color = const Color(0xFFCBD5E0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, gear.radius * 0.3, shaftBorder);
  }

  void _drawPolygon(Canvas canvas, RigidPolygon body) {
    var verts = body.worldVertices;
    if (verts.length < 3) return;

    final path = Path();
    path.moveTo(verts[0].x, verts[0].y);
    for (int i = 1; i < verts.length; i++) {
      path.lineTo(verts[i].x, verts[i].y);
    }
    path.close();

    final Paint fillPaint = Paint()
      ..color = body.color.withOpacity(0.9)
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, fillPaint);

    final Paint strokePaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawPath(path, strokePaint);
  }

  void _drawLaser(Canvas canvas, LaserCutLine laser) {
    final start = Offset(laser.start.x, laser.start.y);
    final end = Offset(laser.end.x, laser.end.y);

    if (showLaserGlow) {
      final Paint glowPaint = Paint()
        ..color = laser.color.withOpacity(0.5)
        ..strokeWidth = 10.0 * laser.intensity
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
      canvas.drawLine(start, end, glowPaint);
    }

    final Paint corePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.0 * laser.intensity
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(start, end, corePaint);

    final Paint innerColorPaint = Paint()
      ..color = laser.color
      ..strokeWidth = 5.0 * laser.intensity
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(start, end, innerColorPaint);
  }

  void _drawParticle(Canvas canvas, Particle particle) {
    final center = Offset(particle.position.x, particle.position.y);
    double alpha = (particle.life / particle.maxLife).clamp(0.0, 1.0);

    final Paint particlePaint = Paint()
      ..color = particle.color.withOpacity(alpha)
      ..style = PaintingStyle.fill;

    if (particle.isSpark) {
      final Paint glow = Paint()
        ..color = particle.color.withOpacity(alpha * 0.7)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
      canvas.drawCircle(center, particle.radius * 2, glow);
    }

    canvas.drawCircle(center, particle.radius, particlePaint);
  }

  @override
  bool shouldRepaint(covariant PhysicsPainter oldDelegate) => true;
}
