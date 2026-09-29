import 'dart:math' as math;
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vmath;

class ParticleBodyComponent extends BodyComponent {
  final vmath.Vector2 initialPosition;
  final vmath.Vector2 initialVelocity;
  final Color color;
  final double radius;
  final bool isFluid;

  ParticleBodyComponent({
    required this.initialPosition,
    required this.initialVelocity,
    required this.color,
    this.radius = 0.35,
    this.isFluid = false,
  });

  @override
  Body createBody() {
    final bodyDef = BodyDef(
      type: BodyType.dynamic,
      position: initialPosition,
      linearVelocity: initialVelocity,
      bullet: true,
      userData: 'particle',
    );

    final body = world.createBody(bodyDef);
    final shape = CircleShape()..radius = radius;
    final fixtureDef = FixtureDef(
      shape,
      density: 2.0,
      friction: isFluid ? 0.05 : 0.2,
      restitution: isFluid ? 0.8 : 0.3,
    );

    body.createFixture(fixtureDef);
    return body;
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset.zero, radius, paint);

    if (isFluid) {
      final glowPaint = Paint()
        ..color = color.withOpacity(0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.0);
      canvas.drawCircle(Offset.zero, radius * 1.8, glowPaint);
    }
  }
}
