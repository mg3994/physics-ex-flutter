import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../physics/voxel_physics.dart';
import '../physics/vector2d.dart';
import '../widgets/voxel_painter.dart';

class BlackHoleScene extends StatefulWidget {
  const BlackHoleScene({super.key});

  @override
  State<BlackHoleScene> createState() => _BlackHoleSceneState();
}

class _BlackHoleSceneState extends State<BlackHoleScene> with SingleTickerProviderStateMixin {
  late VoxelPhysicsEngine engine;
  late AnimationController _ticker;
  double gravityY = 0.0;
  bool isPaused = false;
  Timer? _autoSpawnTimer;

  @override
  void initState() {
    super.initState();
    engine = VoxelPhysicsEngine(gravity: Vector2D(0, gravityY));
    _ticker = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat();
    _ticker.addListener(_onTick);

    _populateInitialParticles(300);

    _autoSpawnTimer = Timer.periodic(const Duration(milliseconds: 900), (_) {
      if (!isPaused) {
        _spawnRandomBlock();
      }
    });
  }

  void _populateInitialParticles(int count) {
    final rand = math.Random();
    List<Color> palette = [
      const Color(0xFF00F0FF),
      const Color(0xFF9D00FF),
      const Color(0xFFFF007F),
      const Color(0xFFFFFF00),
    ];

    double bhX = VoxelPhysicsEngine.virtualWidth / 2;
    double bhY = VoxelPhysicsEngine.virtualHeight * 0.48;

    for (int i = 0; i < count; i++) {
      Color col = palette[rand.nextInt(palette.length)];
      double angle = rand.nextDouble() * 2 * math.pi;
      double dist = 100.0 + rand.nextDouble() * 250.0;

      Vector2D pos = Vector2D(bhX + math.cos(angle) * dist, bhY + math.sin(angle) * dist);
      Vector2D orbitalVel = Vector2D(-math.sin(angle) * 140.0, math.cos(angle) * 140.0);

      engine.freeVoxels.add(Voxel(
        position: pos,
        velocity: orbitalVel,
        color: col,
        radius: 3.0,
        blockId: 0,
        localOffset: Vector2D.zero(),
        isFree: true,
      ));
    }
  }

  void _onTick() {
    if (!isPaused) {
      setState(() {
        engine.update(0.016);
      });
    }
  }

  void _spawnRandomBlock() {
    final rand = math.Random();
    TetrisType type = TetrisType.values[rand.nextInt(TetrisType.values.length)];
    engine.spawnTetrisBlock(type, Vector2D(VoxelPhysicsEngine.virtualWidth * 0.2 + rand.nextDouble() * (VoxelPhysicsEngine.virtualWidth * 0.6), 50.0));
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
        engine.blackHoleCenter = Vector2D(VoxelPhysicsEngine.virtualWidth / 2, VoxelPhysicsEngine.virtualHeight * 0.48);

        return GestureDetector(
          onTapDown: (details) {
            double vx = details.localPosition.dx * (VoxelPhysicsEngine.virtualWidth / constraints.maxWidth);
            double vy = details.localPosition.dy * (VoxelPhysicsEngine.virtualHeight / constraints.maxHeight);
            engine.triggerExplosion(Vector2D(vx, vy), 3.5);
          },
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.2,
                    colors: [Color(0xFF0F0B1A), Color(0xFF020108)],
                  ),
                ),
              ),
              CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                painter: VoxelPainter(engine: engine),
              ),
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tap anywhere for Singularity Pulse shockwave!', style: TextStyle(color: Colors.cyanAccent, fontSize: 13)),
                    ElevatedButton.icon(
                      onPressed: () => _populateInitialParticles(100),
                      icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.purpleAccent),
                      label: const Text('+100 Particles', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E293B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
