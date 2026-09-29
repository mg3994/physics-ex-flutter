import 'package:flutter_test/flutter_test.dart';
import 'package:physics_simulations/physics/vector2d.dart';
import 'package:physics_simulations/physics/rigid_polygon.dart';
import 'package:physics_simulations/physics/tetris_factory.dart';
import 'package:physics_simulations/physics/physics_engine.dart';

void main() {
  group('Physics Engine Unit Tests', () {
    test('Vector2D math operations', () {
      const v1 = Vector2D(3, 4);
      const v2 = Vector2D(1, 2);

      expect(v1.length, 5.0);
      expect((v1 + v2).x, 4.0);
      expect((v1 + v2).y, 6.0);
      expect(v1.dot(v2), 11.0);
    });

    test('Tetris block creation', () {
      final block = TetrisFactory.createTetrisBlock(TetrisShapeType.T, const Vector2D(100, 100));
      expect(block.shapeType, TetrisShapeType.T);
      expect(block.position.x, 100.0);
      expect(block.localVertices.isNotEmpty, true);
    });

    test('Physics engine integration step', () {
      final engine = PhysicsEngine(boundsWidth: 500, boundsHeight: 500);
      final block = TetrisFactory.createTetrisBlock(TetrisShapeType.I, const Vector2D(100, 100));

      engine.bodies.add(block);
      engine.update(0.1);

      expect(block.position.y > 100.0, true);
      expect(block.velocity.y > 0.0, true);
    });
  });
}
