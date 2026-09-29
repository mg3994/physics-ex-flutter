import 'dart:math' as math;
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vmath;

class ShredderGearBody extends BodyComponent {
  final vmath.Vector2 position;
  final double radius;
  final int teethCount;
  final double speed;
  final bool clockwise;

  late RevoluteJoint revoluteJoint;

  ShredderGearBody({
    required this.position,
    this.radius = 4.5,
    this.teethCount = 8,
    this.speed = 4.0,
    this.clockwise = true,
  });

  @override
  Body createBody() {
    // Ground anchor body for the joint
    final anchorDef = BodyDef(type: BodyType.static, position: position);
    final anchorBody = world.createBody(anchorDef);

    // Rotating gear body
    final gearDef = BodyDef(
      type: BodyType.dynamic,
      position: position,
      angularDamping: 0.0,
      userData: 'gear',
    );
    final gearBody = world.createBody(gearDef);

    // Create central cylinder fixture
    final circleShape = CircleShape()..radius = radius * 0.85;
    gearBody.createFixture(FixtureDef(circleShape, density: 10.0, friction: 0.9, restitution: 0.1));

    // Create teeth fixtures around gear body
    double angleStep = (2 * math.pi) / teethCount;
    double toothWidth = 0.5;
    double toothLength = 1.2;

    for (int i = 0; i < teethCount; i++) {
      double angle = i * angleStep;
      vmath.Vector2 p1 = vmath.Vector2(math.cos(angle) * (radius * 0.8), math.sin(angle) * (radius * 0.8));
      vmath.Vector2 p2 = vmath.Vector2(math.cos(angle) * (radius + toothLength), math.sin(angle) * (radius + toothLength));

      final toothShape = PolygonShape()..set([
        p1 + vmath.Vector2(-math.sin(angle) * toothWidth, math.cos(angle) * toothWidth),
        p1 + vmath.Vector2(math.sin(angle) * toothWidth, -math.cos(angle) * toothWidth),
        p2 + vmath.Vector2(math.sin(angle) * toothWidth * 0.5, -math.cos(angle) * toothWidth * 0.5),
        p2 + vmath.Vector2(-math.sin(angle) * toothWidth * 0.5, math.cos(angle) * toothWidth * 0.5),
      ]);

      gearBody.createFixture(FixtureDef(toothShape, density: 5.0, friction: 1.0, restitution: 0.1));
    }

    // Connect with Revolute Joint & Motor
    final jointDef = RevoluteJointDef()
      ..initialize(anchorBody, gearBody, position)
      ..enableMotor = true
      ..motorSpeed = (clockwise ? 1 : -1) * speed
      ..maxMotorTorque = 100000.0;

    revoluteJoint = RevoluteJoint(jointDef);
    world.createJoint(revoluteJoint);

    return gearBody;
  }

  void setMotorSpeed(double newSpeed) {
    revoluteJoint.setMotorSpeed((clockwise ? 1 : -1) * newSpeed);
  }

  @override
  void render(Canvas canvas) {
    final gearPaint = Paint()
      ..color = const Color(0xFF334155)
      ..style = PaintingStyle.fill;

    final teethPaint = Paint()
      ..color = const Color(0xFF64748B)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.08;

    canvas.drawCircle(Offset.zero, radius * 0.85, gearPaint);
    canvas.drawCircle(Offset.zero, radius * 0.85, borderPaint);

    for (final fixture in body.fixtures) {
      if (fixture.shape is PolygonShape) {
        final shape = fixture.shape as PolygonShape;
        final path = Path();
        final verts = shape.vertices;
        if (verts.isNotEmpty) {
          path.moveTo(verts[0].x, verts[0].y);
          for (int i = 1; i < verts.length; i++) {
            path.lineTo(verts[i].x, verts[i].y);
          }
          path.close();
          canvas.drawPath(path, teethPaint);
          canvas.drawPath(path, borderPaint);
        }
      }
    }

    // Center pin
    canvas.drawCircle(Offset.zero, radius * 0.2, Paint()..color = const Color(0xFF0F172A));
  }
}
