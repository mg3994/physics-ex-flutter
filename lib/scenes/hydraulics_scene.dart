import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../physics/voxel_physics.dart';
import '../physics/vector2d.dart';
import '../widgets/voxel_painter.dart';
import '../widgets/control_panel.dart';

class HydraulicsScene extends StatefulWidget {
  const HydraulicsScene({super.key});

  @override
  State<HydraulicsScene> createState() => _HydraulicsSceneState();
}

class _HydraulicsSceneState extends State<HydraulicsScene> with SingleTickerProviderStateMixin {
  late VoxelPhysicsEngine engine;
  late AnimationController _ticker;
  double gravityY = 450.0;
  double gearSpeed = 8.0;
  bool isPaused = false;
  Timer? _waterStreamTimer;

  @override
  void initState() {
    super.initState();
    engine = VoxelPhysicsEngine(gravity: Vector2D(0, gravityY));
    _ticker = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat();
    _ticker.addListener(_onTick);

    _waterStreamTimer = Timer.periodic(const Duration(milliseconds: 60), (_) {
      if (!isPaused) {
        _spawnFluidStream();
      }
    });
  }

  void _spawnFluidStream() {
    final rand = math.Random();
    double px = engine.boundsWidth * 0.45 + (rand.nextDouble() - 0.5) * 40.0;
    engine.freeVoxels.add(Voxel(
      position: Vector2D(px, 10.0),
      velocity: Vector2D((rand.nextDouble() - 0.5) * 30.0, 150.0 + rand.nextDouble() * 50.0),
      color: Color.lerp(const Color(0xFF00F0FF), const Color(0xFF0066FF), rand.nextDouble())!,
      radius: 3.0,
      blockId: 0,
      localOffset: Vector2D.zero(),
      isFree: true,
    ));
  }

  void _onTick() {
    if (!isPaused) {
      setState(() {
        engine.update(0.016);
      });
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _waterStreamTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        engine.boundsWidth = constraints.maxWidth;
        engine.boundsHeight = constraints.maxHeight;

        double centerX = constraints.maxWidth / 2;
        double centerY = constraints.maxHeight * 0.50;
        if (engine.gears.isEmpty) {
          engine.gears.add(Gear(
            center: Vector2D(centerX, centerY),
            radius: 55,
            teethCount: 12,
            rotationSpeed: gearSpeed,
            clockwise: true,
          ));
        } else {
          engine.gears[0].center = Vector2D(centerX, centerY);
        }

        return Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF051329), Color(0xFF020A14)],
                ),
              ),
            ),
            CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: VoxelPainter(engine: engine),
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
                onSpawnBlock: () {
                  TetrisType type = TetrisType.values[math.Random().nextInt(TetrisType.values.length)];
                  engine.spawnTetrisBlock(type, Vector2D(constraints.maxWidth / 2, 40.0));
                },
                onClearAll: () => setState(() => engine.clearAll()),
                onTogglePause: () => setState(() => isPaused = !isPaused),
                isPaused: isPaused,
              ),
            ),
          ],
        );
      },
    );
  }
}
