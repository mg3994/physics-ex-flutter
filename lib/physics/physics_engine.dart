import 'dart:math' as math;
import 'dart:ui';
import 'vector2d.dart';
import 'rigid_polygon.dart';
import 'particle_and_gear.dart';

class SliceResult {
  final List<RigidPolygon> newPolygons;
  final List<Particle> sparks;

  SliceResult(this.newPolygons, this.sparks);
}

class PhysicsEngine {
  Vector2D gravity;
  List<RigidPolygon> bodies = [];
  List<ShredderGear> gears = [];
  List<LaserCutLine> lasers = [];
  List<Particle> particles = [];

  double boundsWidth;
  double boundsHeight;

  PhysicsEngine({
    this.gravity = const Vector2D(0, 450.0),
    this.boundsWidth = 600,
    this.boundsHeight = 800,
  });

  void update(double dt) {
    if (dt <= 0) return;
    dt = math.min(dt, 0.033);

    for (var gear in gears) {
      gear.update(dt);
    }

    _handleLaserSlicing();
    _handleGearInteractions();

    for (var body in bodies) {
      body.integrate(dt, gravity);
    }

    _resolveBodyCollisions();
    _enforceBoundaries();

    for (int i = particles.length - 1; i >= 0; i--) {
      particles[i].update(dt, gravity);
      if (particles[i].isDead) {
        particles.removeAt(i);
      }
    }

    if (particles.length > 800) {
      particles.removeRange(0, particles.length - 800);
    }

    if (bodies.length > 100) {
      int removeIndex = bodies.indexWhere((b) => b.isDebris);
      if (removeIndex != -1) {
        bodies.removeAt(removeIndex);
      }
    }
  }

  void _handleLaserSlicing() {
    List<RigidPolygon> addedBodies = [];
    List<RigidPolygon> removedBodies = [];

    for (var laser in lasers) {
      if (!laser.isActive) continue;

      for (var body in bodies) {
        if (body.invMass == 0) continue;

        SliceResult? result = _slicePolygonWithLine(body, laser.start, laser.end, laser.color);
        if (result != null) {
          removedBodies.add(body);
          addedBodies.addAll(result.newPolygons);
          particles.addAll(result.sparks);
        }
      }
    }

    for (var b in removedBodies) {
      bodies.remove(b);
    }
    bodies.addAll(addedBodies);
  }

  SliceResult? _slicePolygonWithLine(RigidPolygon body, Vector2D p1, Vector2D p2, Color laserColor) {
    List<Vector2D> worldVerts = body.worldVertices;
    int n = worldVerts.length;
    if (n < 3) return null;

    List<int> intersectIndices = [];
    List<Vector2D> intersectPoints = [];

    for (int i = 0; i < n; i++) {
      Vector2D a = worldVerts[i];
      Vector2D b = worldVerts[(i + 1) % n];

      Vector2D? hit = _lineIntersection(p1, p2, a, b);
      if (hit != null) {
        intersectIndices.add(i);
        intersectPoints.add(hit);
      }
    }

    if (intersectPoints.length != 2) return null;

    Vector2D cut1 = intersectPoints[0];
    Vector2D cut2 = intersectPoints[1];

    List<Vector2D> poly1World = [];
    List<Vector2D> poly2World = [];

    int idx1 = intersectIndices[0];
    int idx2 = intersectIndices[1];

    poly1World.add(cut1);
    poly1World.add(cut2);
    for (int i = (idx2 + 1) % n; i != (idx1 + 1) % n; i = (i + 1) % n) {
      poly1World.add(worldVerts[i]);
    }

    poly2World.add(cut2);
    poly2World.add(cut1);
    for (int i = (idx1 + 1) % n; i != (idx2 + 1) % n; i = (i + 1) % n) {
      poly2World.add(worldVerts[i]);
    }

    if (poly1World.length < 3 || poly2World.length < 3) return null;

    RigidPolygon body1 = _createSubPolygon(poly1World, body, Vector2D(-25, -20));
    RigidPolygon body2 = _createSubPolygon(poly2World, body, Vector2D(25, -20));

    List<Particle> sparks = [];
    Vector2D cutMid = (cut1 + cut2) * 0.5;
    final rand = math.Random();
    for (int i = 0; i < 15; i++) {
      double angle = rand.nextDouble() * 2 * math.pi;
      double speed = 60.0 + rand.nextDouble() * 120.0;
      sparks.add(Particle(
        position: cutMid,
        velocity: Vector2D(math.cos(angle) * speed, math.sin(angle) * speed),
        color: laserColor,
        radius: 2.0 + rand.nextDouble() * 2.0,
        maxLife: 0.3 + rand.nextDouble() * 0.4,
        isSpark: true,
      ));
    }

    return SliceResult([body1, body2], sparks);
  }

  RigidPolygon _createSubPolygon(List<Vector2D> worldVerts, RigidPolygon original, Vector2D pushImpulse) {
    Vector2D centroid = Vector2D.zero;
    for (var v in worldVerts) {
      centroid += v;
    }
    centroid = centroid / worldVerts.length.toDouble();

    List<Vector2D> localVerts = worldVerts.map((v) => v - centroid).toList();

    return RigidPolygon(
      position: centroid,
      localVertices: localVerts,
      velocity: original.velocity + pushImpulse,
      angularVelocity: original.angularVelocity + (math.Random().nextDouble() - 0.5) * 4.0,
      color: original.color,
      isDebris: true,
      mass: math.max(0.2, original.mass * 0.45),
      restitution: original.restitution,
      friction: original.friction,
    );
  }

  void _handleGearInteractions() {
    List<RigidPolygon> removed = [];
    List<RigidPolygon> addedDebris = [];

    for (var gear in gears) {
      for (var body in bodies) {
        if (body.invMass == 0) continue;

        double dist = body.position.distanceTo(gear.center);
        if (dist < gear.radius + 30.0) {
          Vector2D dirToGear = (gear.center - body.position).normalized;
          Vector2D tangential = gear.clockwise
              ? Vector2D(-dirToGear.y, dirToGear.x)
              : Vector2D(dirToGear.y, -dirToGear.x);

          body.velocity += (tangential * (gear.rotationSpeed * 30.0) + dirToGear * 80.0) * 0.05;

          if (dist < gear.radius + 10.0) {
            removed.add(body);

            final rand = math.Random();
            for (int i = 0; i < 4; i++) {
              double offsetAngle = rand.nextDouble() * 2 * math.pi;
              Vector2D debPos = body.position + Vector2D(math.cos(offsetAngle) * 8, math.sin(offsetAngle) * 8);

              List<Vector2D> debVerts = [
                const Vector2D(-6, -6),
                const Vector2D(6, -4),
                const Vector2D(0, 8),
              ];

              addedDebris.add(RigidPolygon(
                position: debPos,
                localVertices: debVerts,
                velocity: Vector2D((rand.nextDouble() - 0.5) * 150, 100 + rand.nextDouble() * 100),
                color: body.color,
                isDebris: true,
                mass: 0.1,
              ));
            }

            for (int i = 0; i < 12; i++) {
              double pAngle = rand.nextDouble() * 2 * math.pi;
              particles.add(Particle(
                position: body.position,
                velocity: Vector2D(math.cos(pAngle) * 120, math.sin(pAngle) * 120),
                color: body.color,
                radius: 2.0 + rand.nextDouble() * 3.0,
                maxLife: 0.5 + rand.nextDouble() * 0.5,
              ));
            }
          }
        }
      }
    }

    for (var b in removed) {
      bodies.remove(b);
    }
    bodies.addAll(addedDebris);
  }

  void _resolveBodyCollisions() {
    for (int i = 0; i < bodies.length; i++) {
      for (int j = i + 1; j < bodies.length; j++) {
        RigidPolygon a = bodies[i];
        RigidPolygon b = bodies[j];

        if (a.invMass == 0 && b.invMass == 0) continue;

        double distSq = a.position.distanceToSquared(b.position);
        if (distSq > 150 * 150) continue;

        _resolvePolygonCollision(a, b);
      }
    }
  }

  void _resolvePolygonCollision(RigidPolygon a, RigidPolygon b) {
    double minOverlap = double.infinity;
    Vector2D collisionNormal = Vector2D.zero;

    List<Vector2D> vertsA = a.worldVertices;
    List<Vector2D> vertsB = b.worldVertices;

    List<Vector2D> normals = [];
    _getNormals(vertsA, normals);
    _getNormals(vertsB, normals);

    for (var normal in normals) {
      final projA = _projectPolygon(vertsA, normal);
      final projB = _projectPolygon(vertsB, normal);

      if (projA.max < projB.min || projB.max < projA.min) {
        return;
      }

      double overlap = math.min(projA.max - projB.min, projB.max - projA.min);
      if (overlap < minOverlap) {
        minOverlap = overlap;
        collisionNormal = normal;
      }
    }

    if ((b.position - a.position).dot(collisionNormal) < 0) {
      collisionNormal = -collisionNormal;
    }

    double totalInvMass = a.invMass + b.invMass;
    if (totalInvMass > 0) {
      Vector2D correction = collisionNormal * (minOverlap / totalInvMass) * 0.8;
      if (a.invMass > 0) a.position = a.position - correction * a.invMass;
      if (b.invMass > 0) b.position = b.position + correction * b.invMass;
    }

    Vector2D relativeVel = b.velocity - a.velocity;
    double velAlongNormal = relativeVel.dot(collisionNormal);

    if (velAlongNormal > 0) return;

    double e = math.min(a.restitution, b.restitution);
    double j = -(1 + e) * velAlongNormal;
    j /= totalInvMass > 0 ? totalInvMass : 1.0;

    Vector2D impulse = collisionNormal * j;
    if (a.invMass > 0) a.velocity = a.velocity - impulse * a.invMass;
    if (b.invMass > 0) b.velocity = b.velocity + impulse * b.invMass;
  }

  void _getNormals(List<Vector2D> verts, List<Vector2D> normals) {
    for (int i = 0; i < verts.length; i++) {
      Vector2D p1 = verts[i];
      Vector2D p2 = verts[(i + 1) % verts.length];
      Vector2D edge = p2 - p1;
      normals.add(edge.perpendicular().normalized);
    }
  }

  _Projection _projectPolygon(List<Vector2D> verts, Vector2D axis) {
    double min = verts[0].dot(axis);
    double max = min;
    for (int i = 1; i < verts.length; i++) {
      double p = verts[i].dot(axis);
      if (p < min) min = p;
      if (p > max) max = p;
    }
    return _Projection(min, max);
  }

  void _enforceBoundaries() {
    double pad = 10.0;
    for (var body in bodies) {
      if (body.invMass == 0) continue;

      if (body.position.y > boundsHeight - pad) {
        body.position = Vector2D(body.position.x, boundsHeight - pad);
        body.velocity = Vector2D(body.velocity.x * 0.7, -body.velocity.y * body.restitution);
      }
      if (body.position.x < pad) {
        body.position = Vector2D(pad, body.position.y);
        body.velocity = Vector2D(-body.velocity.x * body.restitution, body.velocity.y);
      }
      if (body.position.x > boundsWidth - pad) {
        body.position = Vector2D(boundsWidth - pad, body.position.y);
        body.velocity = Vector2D(-body.velocity.x * body.restitution, body.velocity.y);
      }
    }
  }

  Vector2D? _lineIntersection(Vector2D p1, Vector2D p2, Vector2D p3, Vector2D p4) {
    double denominator = (p4.y - p3.y) * (p2.x - p1.x) - (p4.x - p3.x) * (p2.y - p1.y);
    if (denominator == 0) return null;

    double ua = ((p4.x - p3.x) * (p1.y - p3.y) - (p4.y - p3.y) * (p1.x - p3.x)) / denominator;
    double ub = ((p2.x - p1.x) * (p1.y - p3.y) - (p2.y - p1.y) * (p1.x - p3.x)) / denominator;

    if (ua >= 0 && ua <= 1 && ub >= 0 && ub <= 1) {
      return Vector2D(p1.x + ua * (p2.x - p1.x), p1.y + ua * (p2.y - p1.y));
    }
    return null;
  }
}

class _Projection {
  final double min;
  final double max;
  _Projection(this.min, this.max);
}
