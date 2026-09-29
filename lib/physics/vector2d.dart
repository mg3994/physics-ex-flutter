import 'dart:math' as math;

class Vector2D {
  final double x;
  final double y;

  const Vector2D(this.x, this.y);

  static const Vector2D zero = Vector2D(0, 0);

  Vector2D operator +(Vector2D other) => Vector2D(x + other.x, y + other.y);
  Vector2D operator -(Vector2D other) => Vector2D(x - other.x, y - other.y);
  Vector2D operator *(double scalar) => Vector2D(x * scalar, y * scalar);
  Vector2D operator /(double scalar) => Vector2D(x / scalar, y / scalar);
  Vector2D operator -() => Vector2D(-x, -y);

  double dot(Vector2D other) => x * other.x + y * other.y;
  double cross(Vector2D other) => x * other.y - y * other.x;

  double get lengthSquared => x * x + y * y;
  double get length => math.sqrt(lengthSquared);

  Vector2D get normalized {
    final len = length;
    if (len == 0) return Vector2D.zero;
    return Vector2D(x / len, y / len);
  }

  double distanceTo(Vector2D other) => (this - other).length;
  double distanceToSquared(Vector2D other) => (this - other).lengthSquared;

  Vector2D rotate(double angle) {
    final cosA = math.cos(angle);
    final sinA = math.sin(angle);
    return Vector2D(x * cosA - y * sinA, x * sinA + y * cosA);
  }

  Vector2D perpendicular() => Vector2D(-y, x);

  @override
  String toString() => 'Vector2D(${x.toStringAsFixed(2)}, ${y.toStringAsFixed(2)})';
}
