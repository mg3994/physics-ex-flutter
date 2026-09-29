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

class LavaMeltScene extends StatefulWidget {
  const LavaMeltScene({super.key});

  @override
  State<LavaMeltScene> createState() => _LavaMeltSceneState();
}

class _LavaMeltSceneState extends State<LavaMeltScene> with SingleTickerProviderStateMixin {
  late PhysicsEngine engine;
  late AnimationController _ticker;
  double gravityY = 480.0;
  double gearSpeed = 7.0;
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

    _autoSpawnTimer = Timer.periodic(const Duration(milliseconds: 1100), (_) {
      if (autoSpawn && !isPaused) {
        _spawnRandomBlock();
      }
    });
  }

  void _onTick() {
    if (!isPaused) {
      setState(() {
        engine.update(0.016);
        _processLavaMelting();
      });
    }
  }

  void _processLavaMelting() {
    double lavaLevel = engine.boundsHeight - 80.0;
    List<int> toRemove = [];
    final rand = math.Random();

    for (int i = 0; i < engine.bodies.length; i++) {
      var body = engine.bodies[i];
      if (body.position.y > lavaLevel - 30.0) {
        toRemove.add(i);

        for (int p = 0; p < 25; p++) {
          double pAngle = -math.pi * 0.85 + rand.nextDouble() * math.pi * 0.7;
          double pSpeed = 80.0 + rand.nextDouble() * 160.0;
          Color lavaColor = Color.lerp(
            const Color(0xFFFF4500),
            const Color(0xFFFFD700),
            rand.nextDouble(),
          )!;

          engine.particles.add(Particle(
            position: Vector2D(body.position.x + (rand.nextDouble() - 0.5) * 30, body.position.y),
            velocity: Vector2D(math.cos(pAngle) * pSpeed, math.sin(pAngle) * pSpeed),
            color: lavaColor,
            radius: 3.5 + rand.nextDouble() * 4.0,
            maxLife: 1.2 + rand.nextDouble() * 0.8,
            isLava: true,
          ));
        }
      }
    }

    for (int idx in toRemove.reversed) {
      if (idx < engine.bodies.length) {
        engine.bodies.removeAt(idx);
      }
    }
  }

  void _spawnRandomBlock([Vector2D? customPos]) {
    final rand = math.Random();
    TetrisShapeType type = TetrisShapeType.values[rand.nextInt(TetrisShapeType.values.length)];
    Vector2D spawnPos = customPos ?? Vector2D(engine.boundsWidth * 0.35 + rand.nextDouble() * (engine.boundsWidth * 0.3), 30.0);
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
        double centerY = constraints.maxHeight * 0.55;
        if (engine.gears.isEmpty) {
          engine.gears.add(ShredderGear(
            center: Vector2D(centerX - 60, centerY),
            radius: 65,
            teethCount: 10,
            rotationSpeed: gearSpeed,
            clockwise: true,
          ));
          engine.gears.add(ShredderGear(
            center: Vector2D(centerX + 60, centerY),
            radius: 65,
            teethCount: 10,
            rotationSpeed: gearSpeed,
            clockwise: false,
          ));
        } else {
          engine.gears[0].center = Vector2D(centerX - 60, centerY);
          engine.gears[1].center = Vector2D(centerX + 60, centerY);
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
                    center: Alignment.bottomCenter,
                    radius: 1.3,
                    colors: [Color(0xFF3A0B00), Color(0xFF0F0505)],
                  ),
                ),
              ),
              CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                painter: PhysicsPainter(engine: engine),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 80,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x88FF4500), Color(0xFFFF2200)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepOrangeAccent.withOpacity(0.6),
                        blurRadius: 25,
                        spreadRadius: 5,
                      )
                    ],
                  ),
                ),
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
                        activeColor: Colors.deepOrangeAccent,
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
