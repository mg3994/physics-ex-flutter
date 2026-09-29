import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../physics/voxel_physics.dart';
import '../physics/vector2d.dart';

class VoxelPainter extends CustomPainter {
  final VoxelPhysicsEngine engine;

  VoxelPainter({required this.engine});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Funnel Hopper Walls
    _drawHopperContainer(canvas, size);

    // 2. Draw Shredder Gears
    for (var gear in engine.gears) {
      _drawGear(canvas, gear);
    }

    // 3. Draw Laser Line
    for (var laser in engine.lasers) {
      if (laser.isActive) {
        _drawLaser(canvas, laser);
      }
    }

    // 4. Draw Voxel Blocks
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

    // 5. Draw Free Voxel Particle Stream
    for (var v in engine.freeVoxels) {
      final pPaint = Paint()
        ..color = v.color.withOpacity(0.9)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(v.position.x, v.position.y), v.radius, pPaint);
    }
  }

  void _drawHopperContainer(Canvas canvas, Size size) {
    final wallPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0;

    final path = Path();
    // Left hopper funnel
    path.moveTo(0, size.height * 0.1);
    path.lineTo(size.width * 0.2, size.height * 0.45);
    path.lineTo(size.width * 0.2, size.height);

    // Right hopper funnel
    path.moveTo(size.width, size.height * 0.1);
    path.lineTo(size.width * 0.8, size.height * 0.45);
    path.lineTo(size.width * 0.8, size.height);

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
      double rIn = gear.radius - 4;
      double rOut = gear.radius + 12.0;

      double a1 = angle - angleStep * 0.25;
      double a2 = angle + angleStep * 0.25;

      path.moveTo(center.dx + rIn * math.cos(a1), center.dy + rIn * math.sin(a1));
      path.lineTo(center.dx + rOut * math.cos(angle - angleStep * 0.1), center.dy + rOut * math.sin(angle - angleStep * 0.1));
      path.lineTo(center.dx + rOut * math.cos(angle + angleStep * 0.1), center.dy + rOut * math.sin(angle + angleStep * 0.1));
      path.lineTo(center.dx + rIn * math.cos(a2), center.dy + rIn * math.sin(a2));
      path.close();

      canvas.drawPath(path, toothPaint);
    }

    // Gear shaft
    canvas.drawCircle(center, gear.radius * 0.3, Paint()..color = const Color(0xFF0F172A));
  }

  void _drawLaser(Canvas canvas, Laser laser) {
    final start = Offset(laser.start.x, laser.start.y);
    final end = Offset(laser.end.x, laser.end.y);

    // Laser Glow
    final Paint glow = Paint()
      ..color = laser.color.withOpacity(0.5)
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);
    canvas.drawLine(start, end, glow);

    // Core Laser Beam
    final Paint core = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(start, end, core);
  }

  @override
  bool shouldRepaint(covariant VoxelPainter oldDelegate) => true;
}
