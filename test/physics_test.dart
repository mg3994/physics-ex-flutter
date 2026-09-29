import 'package:flutter_test/flutter_test.dart';
import 'package:physics_simulations/physics/vector2d.dart';
import 'package:physics_simulations/physics/voxel_physics.dart';

void main() {
  group('Voxel Physics Engine Unit Tests', () {
    test('Vector2D math operations', () {
      final v1 = Vector2D(3, 4);
      final v2 = Vector2D(1, 2);

      expect(v1.length, 5.0);
      expect((v1 + v2).x, 4.0);
      expect((v1 + v2).y, 6.0);
      expect(v1.dot(v2), 11.0);
    });

    test('Voxel Tetris block spawn', () {
      final engine = VoxelPhysicsEngine(boundsWidth: 500, boundsHeight: 500);
      engine.spawnTetrisBlock(TetrisType.T, Vector2D(100, 100));

      expect(engine.blocks.length, 1);
      expect(engine.blocks.first.shapeType, TetrisType.T);
      expect(engine.blocks.first.voxels.isNotEmpty, true);
    });

    test('Physics engine integration step', () {
      final engine = VoxelPhysicsEngine(boundsWidth: 500, boundsHeight: 500);
      engine.spawnTetrisBlock(TetrisType.I, Vector2D(100, 100));

      final block = engine.blocks.first;
      engine.update(0.1);

      expect(block.position.y > 100.0, true);
      expect(block.velocity.y > 0.0, true);
    });
  });
}
