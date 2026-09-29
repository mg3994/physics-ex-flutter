import 'dart:math' as math;
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vmath;

enum TetrisType { I, J, L, O, S, T, Z }

class TetrisForgeBody extends BodyComponent {
  final vmath.Vector2 initialPosition;
  final TetrisType shapeType;
  final Color color;

  TetrisForgeBody({
    required this.initialPosition,
    required this.shapeType,
    required this.color,
  });

  static Color getColorForType(TetrisType type) {
    switch (type) {
      case TetrisType.I:
        return const Color(0xFF00F0FF);
      case TetrisType.J:
        return const Color(0xFF0044FF);
      case TetrisType.L:
        return const Color(0xFFFFA500);
      case TetrisType.O:
        return const Color(0xFFFFFF00);
      case TetrisType.S:
        return const Color(0xFF00FF00);
      case TetrisType.T:
        return const Color(0xFFA000FF);
      case TetrisType.Z:
        return const Color(0xFFFF0000);
    }
  }

  @override
  Body createBody() {
    final bodyDef = BodyDef(
      type: BodyType.dynamic,
      position: initialPosition,
      angularDamping: 0.2,
      linearDamping: 0.1,
      userData: this,
    );

    final body = world.createBody(bodyDef);
    final List<List<vmath.Vector2>> subPolygons = _generateSubPolygons(shapeType, 0.8);

    for (final polyVerts in subPolygons) {
      final shape = PolygonShape()..set(polyVerts);
      final fixtureDef = FixtureDef(
        shape,
        density: 1.2,
        friction: 0.5,
        restitution: 0.2,
      );
      body.createFixture(fixtureDef);
    }

    return body;
  }

  static List<List<vmath.Vector2>> _generateSubPolygons(TetrisType type, double scale) {
    switch (type) {
      case TetrisType.I:
        return [
          [
            vmath.Vector2(-2.0 * scale, -0.5 * scale),
            vmath.Vector2(2.0 * scale, -0.5 * scale),
            vmath.Vector2(2.0 * scale, 0.5 * scale),
            vmath.Vector2(-2.0 * scale, 0.5 * scale),
          ]
        ];
      case TetrisType.O:
        return [
          [
            vmath.Vector2(-1.0 * scale, -1.0 * scale),
            vmath.Vector2(1.0 * scale, -1.0 * scale),
            vmath.Vector2(1.0 * scale, 1.0 * scale),
            vmath.Vector2(-1.0 * scale, 1.0 * scale),
          ]
        ];
      case TetrisType.T:
        return [
          [
            vmath.Vector2(-1.5 * scale, -0.5 * scale),
            vmath.Vector2(1.5 * scale, -0.5 * scale),
            vmath.Vector2(1.5 * scale, 0.5 * scale),
            vmath.Vector2(-1.5 * scale, 0.5 * scale),
          ],
          [
            vmath.Vector2(-0.5 * scale, 0.5 * scale),
            vmath.Vector2(0.5 * scale, 0.5 * scale),
            vmath.Vector2(0.5 * scale, 1.5 * scale),
            vmath.Vector2(-0.5 * scale, 1.5 * scale),
          ]
        ];
      default:
        // Default box fallback
        return [
          [
            vmath.Vector2(-1.0 * scale, -1.0 * scale),
            vmath.Vector2(1.0 * scale, -1.0 * scale),
            vmath.Vector2(1.0 * scale, 1.0 * scale),
            vmath.Vector2(-1.0 * scale, 1.0 * scale),
          ]
        ];
    }
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.08;

    for (final fixture in body.fixtures) {
      final shape = fixture.shape as PolygonShape;
      final path = Path();
      final vertices = shape.vertices;

      if (vertices.isNotEmpty) {
        path.moveTo(vertices[0].x, vertices[0].y);
        for (int i = 1; i < vertices.length; i++) {
          path.lineTo(vertices[i].x, vertices[i].y);
        }
        path.close();

        canvas.drawPath(path, paint);
        canvas.drawPath(path, borderPaint);
      }
    }
  }
}
