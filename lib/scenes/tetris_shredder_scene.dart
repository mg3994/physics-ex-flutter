import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../physics/physics_engine.dart';
import '../physics/tetris_factory.dart';
import '../physics/rigid_polygon.dart';
import '../physics/particle_and_gear.dart';
import '../physics/vector2d.dart';
import '../widgets/physics_painter.dart';
import '../widgets/control_panel.dart';

class TetrisShredderScene extends StatefulWidget {
  const TetrisShredderScene({super.key});

  @override
  State<TetrisShredderScene> createState() => _TetrisShredderSceneState();
}

class _TetrisShredderSceneState extends State<TetrisShredderScene> with SingleTickerProviderStateMixin {
  late PhysicsEngine engine;
  late AnimationController _ticker;
  double gravityY = 450.0;
  double gearSpeed = 5.0;
  bool isPaused = false;
  Timer? _autoSpawnTimer;
  bool autoSpawn = true;

  @override
  void initState() {
    super.initState();
    engine = PhysicsEngine(gravity: Vector2D(0, gravityY));
    _ticker = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat();
    _ticker.addListener(_onTick);

    _setupSceneGears();

    _autoSpawnTimer = Timer.periodic(const Duration(milliseconds: 1400), (_) {
      if (autoSpawn && !isPaused) {
        _spawnRandomBlock();
      }
    });
  }

  void _setupSceneGears() {
    engine.gears.clear();
    engine.gears.add(ShredderGear(
      center: const Vector2D(220, 380),
      radius: 65,
      teethCount: 10,
      rotationSpeed: gearSpeed,
      clockwise: true,
    ));
    engine.gears.add(ShredderGear(
      center: const Vector2D(350, 380),
      radius: 65,
      teethCount: 10,
      rotationSpeed: gearSpeed,
      clockwise: false,
    ));
  }

  void _onTick() {
    if (!isPaused) {
      setState(() {
        engine.update(0.016);
      });
    }
  }

  void _spawnRandomBlock([Vector2D? customPos]) {
    final rand = math.Random();
    TetrisShapeType type = TetrisShapeType.values[rand.nextInt(TetrisShapeType.values.length)];
    Vector2D spawnPos = customPos ?? Vector2D(220.0 + rand.nextDouble() * 130.0, 40.0);
    engine.bodies.add(TetrisFactory.createTetrisBlock(type, spawnPos));
  }

  @override
  void dispose() {
    _ticker.dispose();
    _autoSpawnTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        engine.boundsWidth = constraints.maxWidth;
        engine.boundsHeight = constraints.maxHeight;

        double centerX = constraints.maxWidth / 2;
        double centerY = constraints.maxHeight * 0.52;
        if (engine.gears.length == 2) {
          engine.gears[0].center = Vector2D(centerX - 62, centerY);
          engine.gears[1].center = Vector2D(centerX + 62, centerY);
        }

        return GestureDetector(
          onTapDown: (details) {
            _spawnRandomBlock(Vector2D(details.localPosition.dx, details.localPosition.dy));
          },
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.2,
                    colors: [Color(0xFF1E2640), Color(0xFF0F111A)],
                  ),
                ),
              ),
              CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                painter: PhysicsPainter(engine: engine),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Auto-Drop:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      Switch(
                        value: autoSpawn,
                        activeColor: Colors.cyanAccent,
                        onChanged: (val) => setState(() => autoSpawn = val),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 24,
                left: 16,
                right: 16,
                child: ControlPanel(
                  gravityY: gravityY,
                  onGravityChanged: (val) {
                    setState(() {
                      gravityY = val;
                      engine.gravity = Vector2D(0, gravityY);
                    });
                  },
                  shredderSpeed: gearSpeed,
                  onShredderSpeedChanged: (val) {
                    setState(() {
                      gearSpeed = val;
                      for (var gear in engine.gears) {
                        gear.rotationSpeed = gearSpeed;
                      }
                    });
                  },
                  onSpawnBlock: () => _spawnRandomBlock(),
                  onClearAll: () {
                    setState(() {
                      engine.bodies.clear();
                      engine.particles.clear();
                    });
                  },
                  onTogglePause: () => setState(() => isPaused = !isPaused),
                  isPaused: isPaused,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
