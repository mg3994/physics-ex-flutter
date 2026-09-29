import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../physics/vector2d.dart';

class ClothNode {
  Vector2D position;
  Vector2D oldPosition;
  bool isPinned;

  ClothNode({required this.position, this.isPinned = false}) : oldPosition = position;

  void update(double dt, Vector2D gravity, Vector2D wind) {
    if (isPinned) return;
    Vector2D vel = (position - oldPosition) * 0.98 + wind * dt;
    oldPosition = position;
    position = position + vel + gravity * (dt * dt);
  }
}

class ClothConstraint {
  ClothNode p1;
  ClothNode p2;
  double targetDistance;

  ClothConstraint(this.p1, this.p2) : targetDistance = p1.position.distanceTo(p2.position);

  void resolve() {
    Vector2D delta = p2.position - p1.position;
    double dist = delta.length;
    if (dist == 0) return;
    double diff = (dist - targetDistance) / dist;
    Vector2D correction = delta * (0.5 * diff);

    if (!p1.isPinned) p1.position += correction;
    if (!p2.isPinned) p2.position -= correction;
  }
}

class ClothRopeScene extends StatefulWidget {
  const ClothRopeScene({super.key});

  @override
  State<ClothRopeScene> createState() => _ClothRopeSceneState();
}

class _ClothRopeSceneState extends State<ClothRopeScene> with SingleTickerProviderStateMixin {
  late AnimationController _ticker;
  List<ClothNode> nodes = [];
  List<ClothConstraint> constraints = [];
  ClothNode? draggedNode;

  static const int cols = 16;
  static const int rows = 12;
  static const double spacing = 22.0;

  @override
  void initState() {
    super.initState();
    _setupClothMesh();
    _ticker = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
    _ticker.addListener(_onTick);
  }

  void _setupClothMesh() {
    nodes.clear();
    constraints.clear();

    double startX = 220.0;
    double startY = 80.0;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        bool isPinned = (r == 0 && (c == 0 || c == cols ~/ 2 || c == cols - 1));
        nodes.add(ClothNode(
          position: Vector2D(startX + c * spacing, startY + r * spacing),
          isPinned: isPinned,
        ));
      }
    }

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        int idx = r * cols + c;
        if (c < cols - 1) constraints.add(ClothConstraint(nodes[idx], nodes[idx + 1]));
        if (r < rows - 1) constraints.add(ClothConstraint(nodes[idx], nodes[idx + cols]));
      }
    }
  }

  void _onTick() {
    setState(() {
      Vector2D gravity = Vector2D(0, 350.0);
      Vector2D wind = Vector2D(math.sin(DateTime.now().millisecondsSinceEpoch * 0.003) * 120.0, 0);

      for (var node in nodes) {
        node.update(0.016, gravity, wind);
      }

      for (int i = 0; i < 5; i++) {
        for (var c in constraints) {
          c.resolve();
        }
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
      builder: (context, boxConstraints) {
        return GestureDetector(
          onPanStart: (d) {
            double vx = d.localPosition.dx * (800.0 / boxConstraints.maxWidth);
            double vy = d.localPosition.dy * (1000.0 / boxConstraints.maxHeight);
            Vector2D tapPos = Vector2D(vx, vy);

            ClothNode? closest;
            double minDist = 40.0;
            for (var n in nodes) {
              double dist = n.position.distanceTo(tapPos);
              if (dist < minDist) {
                minDist = dist;
                closest = n;
              }
            }
            draggedNode = closest;
          },
          onPanUpdate: (d) {
            if (draggedNode != null) {
              double vx = d.localPosition.dx * (800.0 / boxConstraints.maxWidth);
              double vy = d.localPosition.dy * (1000.0 / boxConstraints.maxHeight);
              draggedNode!.position = Vector2D(vx, vy);
            }
          },
          onPanEnd: (_) => draggedNode = null,
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
                size: Size(boxConstraints.maxWidth, boxConstraints.maxHeight),
                painter: _ClothPainter(nodes: nodes, constraints: constraints),
              ),
              Positioned(
                top: 16,
                left: 16,
                child: ElevatedButton.icon(
                  onPressed: _setupClothMesh,
                  icon: const Icon(Icons.refresh_rounded, color: Colors.cyanAccent),
                  label: const Text('Reset Cloth Mesh', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E293B)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ClothPainter extends CustomPainter {
  final List<ClothNode> nodes;
  final List<ClothConstraint> constraints;

  _ClothPainter({required this.nodes, required this.constraints});

  @override
  void paint(Canvas canvas, Size size) {
    double scaleX = size.width / 800.0;
    double scaleY = size.height / 1000.0;

    canvas.save();
    canvas.scale(scaleX, scaleY);

    final linePaint = Paint()
      ..color = const Color(0xFF00F0FF).withOpacity(0.7)
      ..strokeWidth = 2.0;

    for (var c in constraints) {
      canvas.drawLine(
        Offset(c.p1.position.x, c.p1.position.y),
        Offset(c.p2.position.x, c.p2.position.y),
        linePaint,
      );
    }

    final nodePaint = Paint()
      ..color = Colors.cyanAccent
      ..style = PaintingStyle.fill;

    for (var n in nodes) {
      canvas.drawCircle(Offset(n.position.x, n.position.y), n.isPinned ? 5.0 : 3.0, nodePaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
