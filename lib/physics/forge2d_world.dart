import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vmath;

class LafikobraForgeGame extends Forge2DGame {
  LafikobraForgeGame({
    vmath.Vector2? gravity,
    double zoom = 10.0,
  }) : super(
          gravity: gravity ?? vmath.Vector2(0, 30.0),
          zoom: zoom,
        );

  late WallBody leftWall;
  late WallBody rightWall;
  late WallBody floorWall;

  @override
  Color backgroundColor() => const Color(0xFF0D1117);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _createBounds();
  }

  void _createBounds() {
    final size = camera.visibleWorldRect;

    leftWall = WallBody(
      start: vmath.Vector2(size.left + 0.5, size.top),
      end: vmath.Vector2(size.left + 0.5, size.bottom),
    );
    rightWall = WallBody(
      start: vmath.Vector2(size.right - 0.5, size.top),
      end: vmath.Vector2(size.right - 0.5, size.bottom),
    );
    floorWall = WallBody(
      start: vmath.Vector2(size.left, size.bottom - 0.5),
      end: vmath.Vector2(size.right, size.bottom - 0.5),
    );

    add(leftWall);
    add(rightWall);
    add(floorWall);
  }

  void setGravityY(double gY) {
    world.gravity = vmath.Vector2(0, gY);
  }

  void clearAllBodies() {
    world.bodies.forEach((b) {
      if (b.userData != 'wall') {
        world.destroyBody(b);
      }
    });
    children.forEach((c) {
      if (c is BodyComponent && c.body.userData != 'wall') {
        c.removeFromParent();
      }
    });
  }
}

class WallBody extends BodyComponent {
  final vmath.Vector2 start;
  final vmath.Vector2 end;

  WallBody({required this.start, required this.end});

  @override
  Body createBody() {
    final shape = EdgeShape()..set(start, end);
    final fixtureDef = FixtureDef(shape, friction: 0.5, restitution: 0.2);
    final bodyDef = BodyDef(type: BodyType.static, userData: 'wall');
    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }
}
