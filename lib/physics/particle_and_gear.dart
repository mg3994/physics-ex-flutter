import 'dart:ui';
import 'vector2d.dart';

class Particle {
  Vector2D position;
  Vector2D velocity;
  Color color;
  double radius;
  double maxLife;
  double life;
  bool isLava;
  bool isSpark;

  Particle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.radius,
    required this.maxLife,
    this.isLava = false,
    this.isSpark = false,
  }) : life = maxLife;

  bool get isDead => life <= 0;

  void update(double dt, Vector2D gravity) {
    life -= dt;
    if (isSpark) {
      velocity = velocity * 0.95 + gravity * 0.2 * dt;
    } else if (isLava) {
      velocity = velocity + gravity * dt;
      velocity = velocity * 0.98; // Viscosity drag
    } else {
      velocity = velocity + gravity * dt;
    }
    position = position + velocity * dt;
  }
}

class ShredderGear {
  Vector2D center;
  double radius;
  int teethCount;
  double toothDepth;
  double rotationSpeed; // Radians per sec
  double currentAngle;
  bool clockwise;

  ShredderGear({
    required this.center,
    required this.radius,
    this.teethCount = 8,
    this.toothDepth = 12.0,
    required this.rotationSpeed,
    this.clockwise = true,
  }) : currentAngle = 0.0;

  void update(double dt) {
    double direction = clockwise ? 1.0 : -1.0;
    currentAngle += rotationSpeed * direction * dt;
  }
}

class LaserCutLine {
  Vector2D start;
  Vector2D end;
  Color color;
  bool isActive;
  double intensity;

  LaserCutLine({
    required this.start,
    required this.end,
    this.color = const Color(0xFFFF0055),
    this.isActive = true,
    this.intensity = 1.0,
  });
}
