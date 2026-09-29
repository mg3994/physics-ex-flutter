import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../physics/voxel_physics.dart';
import '../physics/vector2d.dart';
import '../widgets/voxel_painter.dart';

class SupernovaScene extends StatefulWidget {
  const SupernovaScene({super.key});

  @override
  State<SupernovaScene> createState() => _SupernovaSceneState();
}

class _SupernovaSceneState extends State<SupernovaScene> with SingleTickerProviderStateMixin {
  late VoxelPhysicsEngine engine;
  late AnimationController _ticker;
  double gravityY = 100.0;
  bool isPaused = false;

  @override
  void initState() {
    super.initState();
    engine = VoxelPhysicsEngine(gravity: Vector2D(0, gravityY));
    _ticker = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat();
    _ticker.addListener(_onTick);

    _triggerSupernovaExplosion();
  }

  void _triggerSupernovaExplosion() {
    final rand = math.Random();
    List<Color> palette = [
      const Color(0xFFFF0055),
      const Color(0xFFFFD700),
      const Color(0xFF00F0FF),
      const Color(0xFF39FF14),
      const Color(0xFFBF00FF),
    ];

    engine.clearAll();

    Vector2D center = Vector2D(engine.boundsWidth / 2, engine.boundsHeight * 0.45);

    for (int i = 0; i < 450; i++) {
      double angle = rand.nextDouble() * 2 * math.pi;
      double speed = 100.0 + rand.nextDouble() * 300.0;
      Color color = palette[rand.nextInt(palette.length)];

      engine.freeVoxels.add(Voxel(
        position: center,
        velocity: Vector2D(math.cos(angle) * speed, math.sin(angle) * speed),
        color: color,
        radius: 2.5 + rand.nextDouble() * 2.5,
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

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        engine.boundsWidth = constraints.maxWidth;
        engine.boundsHeight = constraints.maxHeight;

        return GestureDetector(
          onTapDown: (details) {
            engine.triggerExplosion(Vector2D(details.localPosition.dx, details.localPosition.dy), 4.0);
          },
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.2,
                    colors: [Color(0xFF2E001F), Color(0xFF080007)],
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
                    ElevatedButton.icon(
                      onPressed: _triggerSupernovaExplosion,
                      icon: const Icon(Icons.bolt_rounded, color: Colors.amberAccent),
                      label: const Text('DETONATE SUPERNOVA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A0033)),
                    ),
                    IconButton(
                      onPressed: () => setState(() => engine.clearAll()),
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
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
