import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

class DoublePendulumScene extends StatefulWidget {
  const DoublePendulumScene({super.key});

  @override
  State<DoublePendulumScene> createState() => _DoublePendulumSceneState();
}

class _DoublePendulumSceneState extends State<DoublePendulumScene> with SingleTickerProviderStateMixin {
  late AnimationController _ticker;

  double r1 = 160.0;
  double r2 = 140.0;
  double m1 = 20.0;
  double m2 = 20.0;

  double a1 = math.pi / 2;
  double a2 = math.pi / 3;
  double a1V = 0.0;
  double a2V = 0.0;
  double g = 1.0;

  List<Offset> tracePath = [];

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
    _ticker.addListener(_onTick);
  }

  void _onTick() {
    setState(() {
      for (int i = 0; i < 4; i++) {
        _stepPhysics();
      }
    });
  }

  void _stepPhysics() {
    double num1 = -g * (2 * m1 + m2) * math.sin(a1);
    double num2 = -m2 * g * math.sin(a1 - 2 * a2);
    double num3 = -2 * math.sin(a1 - a2) * m2;
    double num4 = a2V * a2V * r2 + a1V * a1V * r1 * math.cos(a1 - a2);
    double den = r1 * (2 * m1 + m2 - m2 * math.cos(2 * a1 - 2 * a2));
    double a1A = (num1 + num2 + num3 * num4) / den;

    num1 = 2 * math.sin(a1 - a2);
    num2 = (a1V * a1V * r1 * (m1 + m2));
    num3 = g * (m1 + m2) * math.cos(a1);
    num4 = a2V * a2V * r2 * m2 * math.cos(a1 - a2);
    den = r2 * (2 * m1 + m2 - m2 * math.cos(2 * a1 - 2 * a2));
    double a2A = (num1 * (num2 + num3 + num4)) / den;

    a1V += a1A;
    a2V += a2A;
    a1 += a1V;
    a2 += a2V;

    a1V *= 0.999;
    a2V *= 0.999;

    double x1 = 400 + r1 * math.sin(a1);
    double y1 = 300 + r1 * math.cos(a1);
    double x2 = x1 + r2 * math.sin(a2);
    double y2 = y1 + r2 * math.cos(a2);

    tracePath.add(Offset(x2, y2));
    if (tracePath.length > 500) {
      tracePath.removeAt(0);
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double x1 = 400 + r1 * math.sin(a1);
    double y1 = 300 + r1 * math.cos(a1);
    double x2 = x1 + r2 * math.sin(a2);
    double y2 = y1 + r2 * math.cos(a2);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  colors: [Color(0xFF1E1B4B), Color(0xFF070514)],
                ),
              ),
            ),
            CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: _PendulumPainter(
                x1: x1,
                y1: y1,
                x2: x2,
                y2: y2,
                r1: r1,
                r2: r2,
                tracePath: tracePath,
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    a1 = math.pi / 2;
                    a2 = math.pi / 2.5;
                    a1V = 0;
                    a2V = 0;
                    tracePath.clear();
                  });
                },
                icon: const Icon(Icons.refresh_rounded, color: Colors.amberAccent),
                label: const Text('Reset Pendulum', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E293B)),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PendulumPainter extends CustomPainter {
  final double x1, y1, x2, y2, r1, r2;
  final List<Offset> tracePath;

  _PendulumPainter({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    required this.r1,
    required this.r2,
    required this.tracePath,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double scaleX = size.width / 800.0;
    double scaleY = size.height / 1000.0;

    canvas.save();
    canvas.scale(scaleX, scaleY);

    final tracePaint = Paint()
      ..color = const Color(0xFFFF0055).withOpacity(0.6)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    if (tracePath.length > 1) {
      final path = Path();
      path.moveTo(tracePath.first.dx, tracePath.first.dy);
      for (int i = 1; i < tracePath.length; i++) {
        path.lineTo(tracePath[i].dx, tracePath[i].dy);
      }
      canvas.drawPath(path, tracePaint);
    }

    final rodPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4.0;

    Offset origin = const Offset(400, 300);
    Offset p1 = Offset(x1, y1);
    Offset p2 = Offset(x2, y2);

    canvas.drawLine(origin, p1, rodPaint);
    canvas.drawLine(p1, p2, rodPaint);

    canvas.drawCircle(origin, 6, Paint()..color = Colors.cyanAccent);
    canvas.drawCircle(p1, 12, Paint()..color = Colors.amberAccent);
    canvas.drawCircle(p2, 12, Paint()..color = Colors.pinkAccent);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
