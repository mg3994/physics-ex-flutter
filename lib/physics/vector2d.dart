import 'dart:math' as math;
import 'package:vector_math/vector_math.dart' as vm;

typedef Vector2D = vm.Vector2;

extension Vector2DExtensions on vm.Vector2 {
  double cross(vm.Vector2 other) => x * other.y - y * other.x;

  vm.Vector2 rotate(double angle) {
    final cosA = math.cos(angle);
    final sinA = math.sin(angle);
    return vm.Vector2(x * cosA - y * sinA, x * sinA + y * cosA);
  }

  vm.Vector2 perpendicular() => vm.Vector2(-y, x);

  vm.Vector2 normalized() {
    final len = length;
    if (len == 0) return vm.Vector2.zero();
    return vm.Vector2(x / len, y / len);
  }
}
