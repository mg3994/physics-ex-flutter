import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vmath;

class LaserBeamComponent extends Component with HasGameReference<Forge2DGame> {
  vmath.Vector2 startPoint;
  vmath.Vector2 endPoint;
  Color color;
  bool isActive;

  LaserBeamComponent({
    required this.startPoint,
    required this.endPoint,
    this.color = const Color(0xFFFF0055),
    this.isActive = true,
  });

  @override
  void update(double dt) {
    super.update(dt);
    if (!isActive) return;

    // Check intersecting bodies in game world
    final List<Body> bodiesToSlice = [];
    game.world.bodies.forEach((body) {
      if (body.type == BodyType.dynamic && body.userData != 'wall' && body.userData != 'gear') {
        if (_intersectsLaser(body)) {
          bodiesToSlice.add(body);
        }
      }
    });

    for (final body in bodiesToSlice) {
      _sliceBody(body);
    }
  }

  bool _intersectsLaser(Body body) {
    for (final fixture in body.fixtures) {
      if (fixture.shape is PolygonShape) {
        final shape = fixture.shape as PolygonShape;
        final verts = shape.vertices.map((v) => body.getWorldPoint(v)).toList();
        for (int i = 0; i < verts.length; i++) {
          final p1 = verts[i];
          final p2 = verts[(i + 1) % verts.length];
          if (_lineIntersects(startPoint, endPoint, p1, p2)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  bool _lineIntersects(vmath.Vector2 a1, vmath.Vector2 a2, vmath.Vector2 b1, vmath.Vector2 b2) {
    double d = (a2.x - a1.x) * (b2.y - b1.y) - (a2.y - a1.y) * (b2.x - b1.x);
    if (d == 0) return false;
    double u = ((b1.x - a1.x) * (b2.y - b1.y) - (b1.y - a1.y) * (b2.x - b1.x)) / d;
    double v = ((b1.x - a1.x) * (a2.y - a1.y) - (b1.y - a1.y) * (a2.x - a1.x)) / d;
    return (u >= 0 && u <= 1 && v >= 0 && v <= 1);
  }

  void _sliceBody(Body body) {
    final pos = body.position.clone();
    final vel = body.linearVelocity.clone();

    // Remove sliced body from world
    game.world.destroyBody(body);

    // Create split sub-debris bodies
    _createDebris(pos + vmath.Vector2(-0.8, -0.4), vel + vmath.Vector2(-4.0, -2.0));
    _createDebris(pos + vmath.Vector2(0.8, -0.4), vel + vmath.Vector2(4.0, -2.0));
  }

  void _createDebris(vmath.Vector2 pos, vmath.Vector2 vel) {
    final bodyDef = BodyDef(
      type: BodyType.dynamic,
      position: pos,
      linearVelocity: vel,
    );
    final b = game.world.createBody(bodyDef);
    final shape = PolygonShape()..set([
      vmath.Vector2(-0.6, -0.6),
      vmath.Vector2(0.6, -0.4),
      vmath.Vector2(0.0, 0.6),
    ]);
    b.createFixture(FixtureDef(shape, density: 1.0, friction: 0.4, restitution: 0.3));
  }

  @override
  void render(Canvas canvas) {
    if (!isActive) return;

    final startOffset = Offset(startPoint.x, startPoint.y);
    final endOffset = Offset(endPoint.x, endPoint.y);

    // Glow Outer Line
    final glowPaint = Paint()
      ..color = color.withOpacity(0.6)
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

    // Inner Core Line
    final corePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 0.25
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(startOffset, endOffset, glowPaint);
    canvas.drawLine(startOffset, endOffset, corePaint);
  }
}
