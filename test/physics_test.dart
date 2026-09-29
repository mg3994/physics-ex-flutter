import 'package:flutter_test/flutter_test.dart';
import 'package:physics_simulations/physics/tetris_forge_body.dart';
import 'package:physics_simulations/physics/forge2d_world.dart';
import 'package:vector_math/vector_math_64.dart' as vmath;
import 'package:flutter/material.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Flame & Forge2D Physics Engine Tests', () {
    test('Vector math operations', () {
      final v1 = vmath.Vector2(3, 4);
      final v2 = vmath.Vector2(1, 2);

      expect(v1.length, 5.0);
      expect((v1 + v2).x, 4.0);
      expect((v1 + v2).y, 6.0);
      expect(v1.dot(v2), 11.0);
    });

    test('TetrisForgeBody shape color mapping', () {
      expect(TetrisForgeBody.getColorForType(TetrisType.I), const Color(0xFF00F0FF));
      expect(TetrisForgeBody.getColorForType(TetrisType.O), const Color(0xFFFFFF00));
      expect(TetrisForgeBody.getColorForType(TetrisType.T), const Color(0xFFA000FF));
    });

    test('LafikobraForgeGame initialization', () {
      final game = LafikobraForgeGame(gravity: vmath.Vector2(0, 30.0));
      expect(game.world.gravity.y, 30.0);

      game.setGravityY(50.0);
      expect(game.world.gravity.y, 50.0);
    });
  });
}
