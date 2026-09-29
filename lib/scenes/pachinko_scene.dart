import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../physics/vector2d.dart';

class PachinkoBall {
  Vector2D position;
  Vector2D velocity;
  Color color;
  double radius;

  PachinkoBall({
    required this.position,
    required this.velocity,
    required this.color,
    this.radius = 8.0,
  });

  void update(double dt, Vector2D gravity, Offset center, double polyRadius, double polyAngle) {
    velocity += gravity * dt;
    position += velocity * dt;

    // Boundary check inside rotating polygon
    double distFromCenter = position.distanceTo(Vector2D(center.dx, center.dy));
    if (distFromCenter > polyRadius - radius) {
      Vector2D normal = (Vector2D(center.dx, center.dy) - position).normalized();
      position = Vector2D(center.dx, center.dy) - normal * (polyRadius - radius);
      velocity = velocity - normal * (2 * velocity.dot(normal)) * 0.7;
    }
  }
}

class PachinkoScene extends StatefulWidget {
  const PachinkoScene({super.key});

  @override
  State<PachinkoScene> createState() => _PachinkoSceneState();
}

class _PachinkoSceneState extends State<PachinkoScene> with SingleTickerProviderStateMixin {
  late AnimationController _ticker;
  List<PachinkoBall> balls = [];
  double polyAngle = 0.0;
  double polyRadius = 260.0;
  Offset center = const Offset(400, 500);

  @override
  void initState() {
    super.initState();
    _spawnBalls(60);
    _ticker = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
    _ticker.addListener(_onTick);
  }

  void _spawnBalls(int count) {
    final rand = math.Random();
    List<Color> palette = [
      const Color(0xFF00F0FF),
      const Color(0xFFFF0055),
      const Color(0xFFFFD700),
      const Color(0xFF39FF14),
      const Color(0xFFBF00FF),
    ];

    for (int i = 0; i < count; i++) {
      Color col = palette[rand.nextInt(palette.length)];
      double angle = rand.nextDouble() * 2 * math.pi;
      double r = rand.nextDouble() * 150.0;

      balls.add(PachinkoBall(
        position: Vector2D(center.dx + math.cos(angle) * r, center.dy + math.sin(angle) * r),
        velocity: Vector2D((rand.nextDouble() - 0.5) * 100, (rand.nextDouble() - 0.5) * 100),
        color: col,
      ));
    }
  }

  void _onTick() {
    setState(() {
      polyAngle += 0.02;
      Vector2D gravity = Vector2D(0, 350.0);

      for (var b in balls) {
        b.update(0.016, gravity, center, polyRadius, polyAngle);
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
        return Stack(
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
              painter: _PachinkoPainter(
                balls: balls,
                center: center,
                polyRadius: polyRadius,
                polyAngle: polyAngle,
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              child: ElevatedButton.icon(
                onPressed: () => _spawnBalls(30),
                icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.cyanAccent),
                label: const Text('+30 Bouncing Balls', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E293B)),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PachinkoPainter extends CustomPainter {
  final List<PachinkoBall> balls;
  final Offset center;
  final double polyRadius;
  final double polyAngle;

  _PachinkoPainter({
    required this.balls,
    required this.center,
    required this.polyRadius,
    required this.polyAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double scaleX = size.width / 800.0;
    double scaleY = size.height / 1000.0;

    canvas.save();
    canvas.scale(scaleX, scaleY);

    // Draw Rotating Octagon Container
    final wallPaint = Paint()
      ..color = Colors.cyanAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0;

    int sides = 8;
    final path = Path();
    for (int i = 0; i < sides; i++) {
      double a = polyAngle + (i * 2 * math.pi / sides);
      double x = center.dx + math.cos(a) * polyRadius;
      double y = center.dy + math.sin(a) * polyRadius;
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, wallPaint);

    // Draw Balls
    for (var b in balls) {
      final pPaint = Paint()
        ..color = b.color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(b.position.x, b.position.y), b.radius, pPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
