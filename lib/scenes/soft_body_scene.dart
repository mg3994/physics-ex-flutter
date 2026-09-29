import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../physics/vector2d.dart';

class JellyPoint {
  Vector2D position;
  Vector2D velocity;
  Vector2D originOffset;

  JellyPoint({required this.position, required this.originOffset}) : velocity = Vector2D.zero();

  void update(double dt, Vector2D center, double angle) {
    Vector2D target = center + originOffset.rotate(angle);
    Vector2D force = (target - position) * 220.0;
    velocity = (velocity + force * dt) * 0.92;
    position += velocity * dt;
  }
}

class SoftBodyScene extends StatefulWidget {
  const SoftBodyScene({super.key});

  @override
  State<SoftBodyScene> createState() => _SoftBodySceneState();
}

class _SoftBodySceneState extends State<SoftBodyScene> with SingleTickerProviderStateMixin {
  late AnimationController _ticker;
  Vector2D center = Vector2D(400, 400);
  double angle = 0.0;
  List<JellyPoint> points = [];

  @override
  void initState() {
    super.initState();
    _setupJelly();
    _ticker = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
    _ticker.addListener(_onTick);
  }

  void _setupJelly() {
    points.clear();
    int count = 16;
    double radius = 120.0;
    for (int i = 0; i < count; i++) {
      double a = (i * 2 * math.pi) / count;
      Vector2D off = Vector2D(math.cos(a) * radius, math.sin(a) * radius);
      points.add(JellyPoint(position: center + off, originOffset: off));
    }
  }

  void _onTick() {
    setState(() {
      angle += 0.02;
      for (var p in points) {
        p.update(0.016, center, angle);
      }
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onPanUpdate: (d) {
            double vx = d.localPosition.dx * (800.0 / constraints.maxWidth);
            double vy = d.localPosition.dy * (1000.0 / constraints.maxHeight);
            setState(() {
              center = Vector2D(vx, vy);
            });
          },
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF020617)],
                  ),
                ),
              ),
              CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                painter: _JellyPainter(points: points, center: center),
              ),
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('Drag screen to poke & bounce Jelly Mesh!', style: TextStyle(color: Colors.pinkAccent, fontSize: 13)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _JellyPainter extends CustomPainter {
  final List<JellyPoint> points;
  final Vector2D center;

  _JellyPainter({required this.points, required this.center});

  @override
  void paint(Canvas canvas, Size size) {
    double scaleX = size.width / 800.0;
    double scaleY = size.height / 1000.0;

    canvas.save();
    canvas.scale(scaleX, scaleY);

    if (points.isNotEmpty) {
      final path = Path();
      path.moveTo(points.first.position.x, points.first.position.y);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].position.x, points[i].position.y);
      }
      path.close();

      final fillPaint = Paint()
        ..color = const Color(0xFFFF007F).withOpacity(0.7)
        ..style = PaintingStyle.fill;

      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0;

      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, borderPaint);

      canvas.drawCircle(Offset(center.x, center.y), 10.0, Paint()..color = Colors.yellowAccent);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
