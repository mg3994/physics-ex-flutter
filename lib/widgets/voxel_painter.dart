import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../physics/voxel_physics.dart';
import '../physics/vector2d.dart';

class VoxelPainter extends CustomPainter {
  final VoxelPhysicsEngine engine;

  VoxelPainter({required this.engine});

  @override
  void paint(Canvas canvas, Size size) {
    double scaleX = size.width / VoxelPhysicsEngine.virtualWidth;
    double scaleY = size.height / VoxelPhysicsEngine.virtualHeight;

    canvas.save();
    canvas.scale(scaleX, scaleY);

    // 1. Draw Funnel Hopper Walls
    _drawHopperContainer(canvas);

    // 2. Draw Black Hole if active
    if (engine.blackHoleCenter != null) {
      _drawBlackHole(canvas, engine.blackHoleCenter!);
    }

    // 3. Draw Gears
    for (var gear in engine.gears) {
      _drawGear(canvas, gear);
    }

    // 4. Draw Lasers
    for (var laser in engine.lasers) {
      if (laser.isActive) {
        _drawLaser(canvas, laser);
      }
    }

    // 5. Draw Voxel Blocks
    for (var block in engine.blocks) {
      for (var v in block.voxels) {
        if (!v.isFree) {
          final paint = Paint()
            ..color = v.color
            ..style = PaintingStyle.fill;
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset(v.position.x, v.position.y),
              width: v.radius * 2,
              height: v.radius * 2,
            ),
            paint,
          );
        }
      }
    }

    // 6. Draw Free Voxel Particles
    for (var v in engine.freeVoxels) {
      final pPaint = Paint()
        ..color = v.color.withOpacity(0.9)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(v.position.x, v.position.y), v.radius, pPaint);
    }

    canvas.restore();
  }

  void _drawBlackHole(Canvas canvas, Vector2D centerPos) {
    final center = Offset(centerPos.x, centerPos.y);

    final Paint glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF00F0FF).withOpacity(0.8),
          const Color(0xFF9D00FF).withOpacity(0.4),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: 100.0));
    canvas.drawCircle(center, 100.0, glowPaint);

    final Paint bhBody = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 28.0, bhBody);

    final Paint bhRing = Paint()
      ..color = Colors.cyanAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, 28.0, bhRing);
  }

  void _drawHopperContainer(Canvas canvas) {
    double w = VoxelPhysicsEngine.virtualWidth;
    double h = VoxelPhysicsEngine.virtualHeight;

    final wallPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0;

    final path = Path();
    path.moveTo(0, h * 0.1);
    path.lineTo(w * 0.22, h * 0.45);
    path.lineTo(w * 0.22, h);

    path.moveTo(w, h * 0.1);
    path.lineTo(w * 0.78, h * 0.45);
    path.lineTo(w * 0.78, h);

    canvas.drawPath(path, wallPaint);
  }

  void _drawGear(Canvas canvas, Gear gear) {
    final center = Offset(gear.center.x, gear.center.y);

    final Paint bodyPaint = Paint()
      ..color = const Color(0xFF334155)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, gear.radius, bodyPaint);

    final Paint toothPaint = Paint()
      ..color = const Color(0xFF64748B)
      ..style = PaintingStyle.fill;

    double angleStep = (2 * math.pi) / gear.teethCount;
    for (int i = 0; i < gear.teethCount; i++) {
      double angle = gear.currentAngle + i * angleStep;

      final path = Path();
      double rIn = gear.radius - 6;
      double rOut = gear.radius + 16.0;

      double a1 = angle - angleStep * 0.25;
      double a2 = angle + angleStep * 0.25;

      path.moveTo(center.dx + rIn * math.cos(a1), center.dy + rIn * math.sin(a1));
      path.lineTo(center.dx + rOut * math.cos(angle - angleStep * 0.1), center.dy + rOut * math.sin(angle - angleStep * 0.1));
      path.lineTo(center.dx + rOut * math.cos(angle + angleStep * 0.1), center.dy + rOut * math.sin(angle + angleStep * 0.1));
      path.lineTo(center.dx + rIn * math.cos(a2), center.dy + rIn * math.sin(a2));
      path.close();

      canvas.drawPath(path, toothPaint);
    }

    canvas.drawCircle(center, gear.radius * 0.3, Paint()..color = const Color(0xFF0F172A));
  }

  void _drawLaser(Canvas canvas, Laser laser) {
    final start = Offset(laser.start.x, laser.start.y);
    final end = Offset(laser.end.x, laser.end.y);

    final Paint glow = Paint()
      ..color = laser.color.withOpacity(0.5)
      ..strokeWidth = 12.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
    canvas.drawLine(start, end, glow);

    final Paint core = Paint()
      ..color = Colors.white
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(start, end, core);
  }

  @override
  bool shouldRepaint(covariant VoxelPainter oldDelegate) => true;
}
