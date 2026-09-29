import 'dart:async';
import 'dart:math' as math;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vmath;
import '../physics/forge2d_world.dart';
import '../physics/tetris_forge_body.dart';
import '../physics/laser_slicer.dart';
import '../widgets/control_panel.dart';

class LaserCutterScene extends StatefulWidget {
  const LaserCutterScene({super.key});

  @override
  State<LaserCutterScene> createState() => _LaserCutterSceneState();
}

class _LaserCutterSceneState extends State<LaserCutterScene> {
  late LafikobraForgeGame game;
  late LaserBeamComponent laserBeam;
  double gravityY = 30.0;
  bool laserActive = true;
  bool isPaused = false;
  Timer? _autoSpawnTimer;
  bool autoSpawn = true;

  @override
  void initState() {
    super.initState();
    game = LafikobraForgeGame(gravity: vmath.Vector2(0, gravityY));
    _setupLaser();

    _autoSpawnTimer = Timer.periodic(const Duration(milliseconds: 1100), (_) {
      if (autoSpawn && !isPaused) {
        _spawnRandomBlock();
      }
    });
  }

  void _setupLaser() {
    laserBeam = LaserBeamComponent(
      startPoint: vmath.Vector2(-18.0, 2.0),
      endPoint: vmath.Vector2(18.0, 2.0),
      color: const Color(0xFFFF0055),
      isActive: laserActive,
    );
    game.add(laserBeam);
  }

  void _spawnRandomBlock([vmath.Vector2? pos]) {
    final rand = math.Random();
    TetrisType type = TetrisType.values[rand.nextInt(TetrisType.values.length)];
    Color color = TetrisForgeBody.getColorForType(type);

    vmath.Vector2 spawnPos = pos ?? vmath.Vector2((rand.nextDouble() - 0.5) * 10.0, -18.0);

    game.add(TetrisForgeBody(
      initialPosition: spawnPos,
      shapeType: type,
      color: color,
    ));
  }

  @override
  void dispose() {
    _autoSpawnTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GameWidget(game: game),
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
                game.setGravityY(gravityY);
              });
            },
            laserActive: laserActive,
            onLaserActiveChanged: (val) {
              setState(() {
                laserActive = val;
                laserBeam.isActive = laserActive;
              });
            },
            onSpawnBlock: () => _spawnRandomBlock(),
            onClearAll: () => setState(() => game.clearAllBodies()),
            onTogglePause: () {
              setState(() {
                isPaused = !isPaused;
                if (isPaused) {
                  game.pauseEngine();
                } else {
                  game.resumeEngine();
                }
              });
            },
            isPaused: isPaused,
          ),
        ),
      ],
    );
  }
}
