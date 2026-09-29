import 'dart:ui';
import 'vector2d.dart';

enum TetrisShapeType { I, J, L, O, S, T, Z }

enum BodyType { dynamic, static, kinematic }

class RigidPolygon {
  Vector2D position;
  Vector2D velocity;
  double angularVelocity;
  double angle;

  List<Vector2D> localVertices;
  double mass;
  double invMass;
  double inertia;
  double invInertia;

  double restitution;
  double friction;

  Color color;
  TetrisShapeType? shapeType;
  bool isDebris;
  bool isLiquid;

  RigidPolygon({
    required this.position,
    required this.localVertices,
    Vector2D? velocity,
    this.angularVelocity = 0.0,
    this.angle = 0.0,
    this.mass = 1.0,
    BodyType bodyType = BodyType.dynamic,
    this.restitution = 0.2,
    this.friction = 0.4,
    required this.color,
    this.shapeType,
    this.isDebris = false,
    this.isLiquid = false,
  })  : velocity = velocity ?? Vector2D.zero(),
        invMass = (bodyType == BodyType.static || mass == double.infinity) ? 0.0 : 1.0 / mass,
        inertia = _calculateInertia(mass, localVertices),
        invInertia = (bodyType == BodyType.static || mass == double.infinity) ? 0.0 : 1.0 / _calculateInertia(mass, localVertices);

  static double _calculateInertia(double mass, List<Vector2D> vertices) {
    if (mass == double.infinity || mass <= 0 || vertices.length < 3) return 100.0;
    double sum1 = 0.0;
    double sum2 = 0.0;
    for (int i = 0; i < vertices.length; i++) {
      Vector2D v1 = vertices[i];
      Vector2D v2 = vertices[(i + 1) % vertices.length];
      double a = v1.cross(v2).abs();
      double b = v1.dot(v1) + v1.dot(v2) + v2.dot(v2);
      sum1 += a * b;
      sum2 += a;
    }
    if (sum2 == 0) return mass * 100.0;
    return (mass / 6.0) * (sum1 / sum2);
  }

  List<Vector2D> get worldVertices {
    return localVertices.map((v) => position + v.rotate(angle)).toList();
  }

  void applyImpulse(Vector2D impulse, Vector2D contactPoint) {
    if (invMass == 0) return;
    velocity = velocity + impulse * invMass;
    Vector2D r = contactPoint - position;
    angularVelocity += invInertia * r.cross(impulse);
  }

  void integrate(double dt, Vector2D gravity) {
    if (invMass == 0) return;
    velocity = velocity + gravity * dt;
    position = position + velocity * dt;
    angle += angularVelocity * dt;
    angularVelocity *= 0.99;
  }
}
