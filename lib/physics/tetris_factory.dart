import 'dart:ui';
import 'vector2d.dart';
import 'rigid_polygon.dart';

class TetrisFactory {
  static const double blockSize = 24.0;

  static RigidPolygon createTetrisBlock(TetrisShapeType type, Vector2D spawnPosition) {
    List<List<int>> grid;
    Color color;

    switch (type) {
      case TetrisShapeType.I:
        grid = [
          [1, 1, 1, 1]
        ];
        color = const Color(0xFF00F0FF); // Cyan
        break;
      case TetrisShapeType.J:
        grid = [
          [1, 0, 0],
          [1, 1, 1]
        ];
        color = const Color(0xFF0000FF); // Blue
        break;
      case TetrisShapeType.L:
        grid = [
          [0, 0, 1],
          [1, 1, 1]
        ];
        color = const Color(0xFFFFA500); // Orange
        break;
      case TetrisShapeType.O:
        grid = [
          [1, 1],
          [1, 1]
        ];
        color = const Color(0xFFFFFF00); // Yellow
        break;
      case TetrisShapeType.S:
        grid = [
          [0, 1, 1],
          [1, 1, 0]
        ];
        color = const Color(0xFF00FF00); // Green
        break;
      case TetrisShapeType.T:
        grid = [
          [0, 1, 0],
          [1, 1, 1]
        ];
        color = const Color(0xFFA000FF); // Purple
        break;
      case TetrisShapeType.Z:
        grid = [
          [1, 1, 0],
          [0, 1, 1]
        ];
        color = const Color(0xFFFF0000); // Red
        break;
    }

    // Build bounding polygon vertices for the shape
    List<Vector2D> rawVertices = _gridToPolygonVertices(grid, blockSize);

    // Calculate centroid and normalize vertices relative to centroid
    Vector2D centroid = _calculateCentroid(rawVertices);
    List<Vector2D> localVertices = rawVertices.map((v) => v - centroid).toList();

    return RigidPolygon(
      position: spawnPosition,
      localVertices: localVertices,
      color: color,
      shapeType: type,
      mass: localVertices.length * 0.5,
      restitution: 0.15,
      friction: 0.5,
    );
  }

  static Vector2D _calculateCentroid(List<Vector2D> vertices) {
    double sumX = 0;
    double sumY = 0;
    for (var v in vertices) {
      sumX += v.x;
      sumY += v.y;
    }
    return Vector2D(sumX / vertices.length, sumY / vertices.length);
  }

  static List<Vector2D> _gridToPolygonVertices(List<List<int>> grid, double cellSize) {
    int rows = grid.length;
    int cols = grid[0].length;
    List<Vector2D> points = [];

    // Simple contour outline generation for block grid
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (grid[r][c] == 1) {
          double x = c * cellSize;
          double y = r * cellSize;

          // Add 4 corners of block cell
          points.add(Vector2D(x, y));
          points.add(Vector2D(x + cellSize, y));
          points.add(Vector2D(x + cellSize, y + cellSize));
          points.add(Vector2D(x, y + cellSize));
        }
      }
    }

    // Return convex hull or simplified bounding shape
    return _convexHull(points);
  }

  static List<Vector2D> _convexHull(List<Vector2D> pts) {
    if (pts.length <= 3) return pts;

    List<Vector2D> sorted = List.from(pts)
      ..sort((a, b) => a.x != b.x ? a.x.compareTo(b.x) : a.y.compareTo(b.y));

    List<Vector2D> lower = [];
    for (var p in sorted) {
      while (lower.length >= 2 &&
          (lower[lower.length - 1] - lower[lower.length - 2])
                  .cross(p - lower[lower.length - 1]) <=
              0) {
        lower.removeLast();
      }
      lower.add(p);
    }

    List<Vector2D> upper = [];
    for (var p in sorted.reversed) {
      while (upper.length >= 2 &&
          (upper[upper.length - 1] - upper[upper.length - 2])
                  .cross(p - upper[upper.length - 1]) <=
              0) {
        upper.removeLast();
      }
      upper.add(p);
    }

    lower.removeLast();
    upper.removeLast();
    return [...lower, ...upper];
  }
}
