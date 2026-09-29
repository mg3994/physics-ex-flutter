import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../physics/voxel_physics.dart';
import '../physics/vector2d.dart';
import '../widgets/voxel_painter.dart';
import '../widgets/control_panel.dart';

class LavaMeltScene extends StatefulWidget {
  const LavaMeltScene({super.key});

  @override
  State<LavaMeltScene> createState() => _LavaMeltSceneState();
}

class _LavaMeltSceneState extends State<LavaMeltScene> with SingleTickerProviderStateMixin {
  late VoxelPhysicsEngine engine;
  late AnimationController _ticker;
  double gravityY = 450.0;
  double gearSpeed = 7.0;
  bool isPaused = false;
  Timer? _autoSpawnTimer;
  bool autoSpawn = true;

  @override
  void initState() {
    super.initState();
    engine = VoxelPhysicsEngine(gravity: Vector2D(0, gravityY));
    _ticker = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat();
    _ticker.addListener(_onTick);

    _autoSpawnTimer = Timer.periodic(const Duration(milliseconds: 1000), (_) {
      if (autoSpawn && !isPaused) {
        _spawnRandomBlock();
      }
    });
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
    TetrisType type = TetrisType.values[rand.nextInt(TetrisType.values.length)];
    Vector2D spawnPos = customPos ?? Vector2D(VoxelPhysicsEngine.virtualWidth * 0.35 + rand.nextDouble() * (VoxelPhysicsEngine.virtualWidth * 0.3), 50.0);
    engine.spawnTetrisBlock(type, spawnPos);
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
        double centerX = VoxelPhysicsEngine.virtualWidth / 2;
        double centerY = VoxelPhysicsEngine.virtualHeight * 0.50;
        if (engine.gears.isEmpty) {
          engine.gears.add(Gear(
            center: Vector2D(centerX - 65, centerY),
            radius: 60,
            teethCount: 10,
            rotationSpeed: gearSpeed,
            clockwise: true,
          ));
          engine.gears.add(Gear(
            center: Vector2D(centerX + 65, centerY),
            radius: 60,
            teethCount: 10,
            rotationSpeed: gearSpeed,
            clockwise: false,
          ));
        }

        return GestureDetector(
          onTapDown: (details) {
            double vx = details.localPosition.dx * (VoxelPhysicsEngine.virtualWidth / constraints.maxWidth);
            double vy = details.localPosition.dy * (VoxelPhysicsEngine.virtualHeight / constraints.maxHeight);
            _spawnRandomBlock(Vector2D(vx, vy));
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
                painter: VoxelPainter(engine: engine),
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
                  onClearAll: () => setState(() => engine.clearAll()),
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
