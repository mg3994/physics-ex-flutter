import 'dart:math' as math;
import 'dart:ui';
import 'vector2d.dart';

enum TetrisType { I, J, L, O, S, T, Z }

class Voxel {
  Vector2D position;
  Vector2D velocity;
  Color color;
  double radius;
  bool isFree;
  int blockId;
  Vector2D localOffset;

  Voxel({
    required this.position,
    required this.velocity,
    required this.color,
    required this.radius,
    required this.blockId,
    required this.localOffset,
    this.isFree = false,
  });

  void update(double dt, Vector2D gravity, double boundsW, double boundsH) {
    velocity = velocity + gravity * dt;
    position = position + velocity * dt;

    double pad = radius + 4.0;
    if (position.y > boundsH - pad) {
      position = Vector2D(position.x, boundsH - pad);
      velocity = Vector2D(velocity.x * 0.7, -velocity.y * 0.3);
    }
    if (position.x < pad) {
      position = Vector2D(pad, position.y);
      velocity = Vector2D(-velocity.x * 0.4, velocity.y * 0.8);
    }
    if (position.x > boundsW - pad) {
      position = Vector2D(boundsW - pad, position.y);
      velocity = Vector2D(-velocity.x * 0.4, velocity.y * 0.8);
    }
  }
}

class VoxelBlock {
  final int id;
  Vector2D position;
  Vector2D velocity;
  double angle;
  double angularVelocity;
  Color color;
  TetrisType shapeType;
  List<Voxel> voxels;

  VoxelBlock({
    required this.id,
    required this.position,
    required this.velocity,
    required this.color,
    required this.shapeType,
    required this.voxels,
    this.angle = 0.0,
    this.angularVelocity = 0.0,
  });

  void update(double dt, Vector2D gravity, double boundsW, double boundsH) {
    velocity = velocity + gravity * dt;
    position = position + velocity * dt;
    angle += angularVelocity * dt;
    angularVelocity *= 0.99;

    for (var v in voxels) {
      if (!v.isFree) {
        v.position = position + v.localOffset.rotate(angle);
        v.velocity = velocity;
      }
    }

    double pad = 24.0;
    if (position.y > boundsH - pad) {
      position = Vector2D(position.x, boundsH - pad);
      velocity = Vector2D(velocity.x * 0.7, -velocity.y * 0.25);
    }
    if (position.x < pad) {
      position = Vector2D(pad, position.y);
      velocity = Vector2D(-velocity.x * 0.3, velocity.y * 0.8);
    }
    if (position.x > boundsW - pad) {
      position = Vector2D(boundsW - pad, position.y);
      velocity = Vector2D(-velocity.x * 0.3, velocity.y * 0.8);
    }
  }
}

class Gear {
  Vector2D center;
  double radius;
  int teethCount;
  double rotationSpeed;
  double currentAngle;
  bool clockwise;

  Gear({
    required this.center,
    required this.radius,
    this.teethCount = 10,
    required this.rotationSpeed,
    this.clockwise = true,
  }) : currentAngle = 0.0;

  void update(double dt) {
    double dir = clockwise ? 1.0 : -1.0;
    currentAngle += rotationSpeed * dir * dt;
  }
}

class Laser {
  Vector2D start;
  Vector2D end;
  Color color;
  bool isActive;

  Laser({
    required this.start,
    required this.end,
    this.color = const Color(0xFFFF0055),
    this.isActive = true,
  });

  bool cutsPoint(Vector2D p, double threshold) {
    if (!isActive) return false;
    double d = _pointToLineDistance(p, start, end);
    return d <= threshold;
  }

  static double _pointToLineDistance(Vector2D p, Vector2D a, Vector2D b) {
    double l2 = a.distanceToSquared(b);
    if (l2 == 0) return p.distanceTo(a);
    double t = ((p.x - a.x) * (b.x - a.x) + (p.y - a.y) * (b.y - a.y)) / l2;
    t = t.clamp(0.0, 1.0);
    Vector2D proj = Vector2D(a.x + t * (b.x - a.x), a.y + t * (b.y - a.y));
    return p.distanceTo(proj);
  }
}

class VoxelPhysicsEngine {
  Vector2D gravity;
  double boundsWidth;
  double boundsHeight;

  List<VoxelBlock> blocks = [];
  List<Voxel> freeVoxels = [];
  List<Gear> gears = [];
  List<Laser> lasers = [];

  Vector2D? blackHoleCenter;
  double blackHoleMass = 150000.0;

  int _nextBlockId = 1;

  VoxelPhysicsEngine({
    Vector2D? gravity,
    this.boundsWidth = 600,
    this.boundsHeight = 800,
  }) : gravity = gravity ?? Vector2D(0, 400.0);

  void update(double dt) {
    if (dt <= 0) return;
    dt = math.min(dt, 0.033);

    for (var gear in gears) {
      gear.update(dt);
    }

    _processLaserSlicing();
    _processGearShredding();

    // Black hole gravitational forces
    if (blackHoleCenter != null) {
      _applyBlackHoleForces(dt);
    }

    for (int i = blocks.length - 1; i >= 0; i--) {
      var block = blocks[i];
      block.update(dt, gravity, boundsWidth, boundsHeight);

      if (block.voxels.every((v) => v.isFree)) {
        blocks.removeAt(i);
      }
    }

    for (int i = freeVoxels.length - 1; i >= 0; i--) {
      freeVoxels[i].update(dt, gravity, boundsWidth, boundsHeight);
    }

    if (freeVoxels.length > 800) {
      freeVoxels.removeRange(0, freeVoxels.length - 800);
    }
  }

  void _applyBlackHoleForces(double dt) {
    final bh = blackHoleCenter!;
    for (var p in freeVoxels) {
      double dist = p.position.distanceTo(bh);
      if (dist > 5.0 && dist < 350.0) {
        Vector2D dir = (bh - p.position).normalized();
        Vector2D orbital = Vector2D(-dir.y, dir.x);
        double force = blackHoleMass / (dist * dist);
        p.velocity += (dir * force + orbital * (force * 0.4)) * dt;
      }
    }
  }

  void triggerExplosion(Vector2D center, double forceStrength) {
    final rand = math.Random();
    for (var v in freeVoxels) {
      double dist = v.position.distanceTo(center);
      if (dist < 220.0) {
        Vector2D dir = dist == 0
            ? Vector2D((rand.nextDouble() - 0.5), (rand.nextDouble() - 0.5)).normalized()
            : (v.position - center).normalized();
        double pForce = (220.0 - dist) * forceStrength;
        v.velocity += dir * pForce;
      }
    }
  }

  void spawnTetrisBlock(TetrisType type, Vector2D spawnPos) {
    List<List<int>> grid;
    Color color;

    switch (type) {
      case TetrisType.I:
        grid = [
          [1, 1, 1, 1]
        ];
        color = const Color(0xFF00F0FF);
        break;
      case TetrisType.J:
        grid = [
          [1, 0, 0],
          [1, 1, 1]
        ];
        color = const Color(0xFF0044FF);
        break;
      case TetrisType.L:
        grid = [
          [0, 0, 1],
          [1, 1, 1]
        ];
        color = const Color(0xFFFFA500);
        break;
      case TetrisType.O:
        grid = [
          [1, 1],
          [1, 1]
        ];
        color = const Color(0xFFFFFF00);
        break;
      case TetrisType.S:
        grid = [
          [0, 1, 1],
          [1, 1, 0]
        ];
        color = const Color(0xFF00FF00);
        break;
      case TetrisType.T:
        grid = [
          [0, 1, 0],
          [1, 1, 1]
        ];
        color = const Color(0xFFA000FF);
        break;
      case TetrisType.Z:
        grid = [
          [1, 1, 0],
          [0, 1, 1]
        ];
        color = const Color(0xFFFF0000);
        break;
    }

    int blockId = _nextBlockId++;
    double voxelSize = 8.0;
    List<Voxel> voxels = [];

    int rows = grid.length;
    int cols = grid[0].length;
    double centerOffX = (cols * voxelSize) / 2.0;
    double centerOffY = (rows * voxelSize) / 2.0;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (grid[r][c] == 1) {
          for (double vx = 0; vx < voxelSize; vx += 3.5) {
            for (double vy = 0; vy < voxelSize; vy += 3.5) {
              Vector2D localPos = Vector2D(c * voxelSize + vx - centerOffX, r * voxelSize + vy - centerOffY);
              voxels.add(Voxel(
                position: spawnPos + localPos,
                velocity: Vector2D.zero(),
                color: color,
                radius: 2.0,
                blockId: blockId,
                localOffset: localPos,
              ));
            }
          }
        }
      }
    }

    blocks.add(VoxelBlock(
      id: blockId,
      position: spawnPos,
      velocity: Vector2D(0, 50.0),
      color: color,
      shapeType: type,
      voxels: voxels,
      angularVelocity: (math.Random().nextDouble() - 0.5) * 1.5,
    ));
  }

  void _processLaserSlicing() {
    final rand = math.Random();
    for (var laser in lasers) {
      if (!laser.isActive) continue;

      for (var block in blocks) {
        for (var voxel in block.voxels) {
          if (!voxel.isFree && laser.cutsPoint(voxel.position, 6.0)) {
            voxel.isFree = true;
            double side = (rand.nextDouble() > 0.5) ? 1.0 : -1.0;
            voxel.velocity = Vector2D(side * (60.0 + rand.nextDouble() * 100.0), -30.0 - rand.nextDouble() * 50.0);
            freeVoxels.add(voxel);
          }
        }
      }
    }
  }

  void _processGearShredding() {
    final rand = math.Random();
    for (var gear in gears) {
      for (var block in blocks) {
        for (var voxel in block.voxels) {
          if (!voxel.isFree && voxel.position.distanceTo(gear.center) < gear.radius + 8.0) {
            voxel.isFree = true;
            Vector2D dirToCenter = (gear.center - voxel.position).normalized();
            Vector2D tangential = gear.clockwise
                ? Vector2D(-dirToCenter.y, dirToCenter.x)
                : Vector2D(dirToCenter.y, dirToCenter.x);

            voxel.velocity = tangential * (gear.rotationSpeed * 25.0) + Vector2D((rand.nextDouble() - 0.5) * 60, 120.0 + rand.nextDouble() * 100);
            freeVoxels.add(voxel);
          }
        }
      }
    }
  }

  void clearAll() {
    blocks.clear();
    freeVoxels.clear();
  }
}
