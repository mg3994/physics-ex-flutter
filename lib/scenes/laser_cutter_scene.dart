import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../physics/voxel_physics.dart';
import '../physics/vector2d.dart';
import '../widgets/voxel_painter.dart';
import '../widgets/control_panel.dart';

class LaserCutterScene extends StatefulWidget {
  const LaserCutterScene({super.key});

  @override
  State<LaserCutterScene> createState() => _LaserCutterSceneState();
}

class _LaserCutterSceneState extends State<LaserCutterScene> with SingleTickerProviderStateMixin {
  late VoxelPhysicsEngine engine;
  late AnimationController _ticker;
  double gravityY = 400.0;
  bool laserActive = true;
  bool isPaused = false;
  Timer? _autoSpawnTimer;
  bool autoSpawn = true;
  double laserYPercent = 0.40;

  @override
  void initState() {
    super.initState();
    engine = VoxelPhysicsEngine(gravity: Vector2D(0, gravityY));
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
        double laserY = VoxelPhysicsEngine.virtualHeight * laserYPercent;
        engine.lasers = [
          Laser(
            start: Vector2D(20, laserY),
            end: Vector2D(VoxelPhysicsEngine.virtualWidth - 20, laserY),
            color: const Color(0xFFFF0055),
            isActive: laserActive,
          ),
        ];

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
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF0D0E1A), Color(0xFF1B182B)],
                  ),
                ),
              ),
              CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                painter: VoxelPainter(engine: engine),
              ),
              Positioned(
                left: 12,
                top: constraints.maxHeight * 0.2,
                bottom: constraints.maxHeight * 0.35,
                child: Column(
                  children: [
                    const Icon(Icons.height_rounded, color: Colors.pinkAccent, size: 20),
                    Expanded(
                      child: RotatedBox(
                        quarterTurns: 3,
                        child: Slider(
                          value: laserYPercent,
                          min: 0.25,
                          max: 0.70,
                          activeColor: Colors.pinkAccent,
                          onChanged: (val) {
                            setState(() {
                              laserYPercent = val;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
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
                        activeColor: Colors.pinkAccent,
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
                  laserActive: laserActive,
                  onLaserActiveChanged: (val) => setState(() => laserActive = val),
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
