import 'dart:async';
import 'dart:math' as math;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vmath;
import '../physics/forge2d_world.dart';
import '../physics/tetris_forge_body.dart';
import '../physics/shredder_gear_body.dart';
import '../physics/forge_particle_system.dart';
import '../widgets/control_panel.dart';

class LavaMeltScene extends StatefulWidget {
  const LavaMeltScene({super.key});

  @override
  State<LavaMeltScene> createState() => _LavaMeltSceneState();
}

class _LavaMeltSceneState extends State<LavaMeltScene> {
  late LafikobraForgeGame game;
  late ShredderGearBody gear;
  double gravityY = 35.0;
  double gearSpeed = 6.0;
  bool isPaused = false;
  Timer? _autoSpawnTimer;
  Timer? _lavaParticleTimer;
  bool autoSpawn = true;

  @override
  void initState() {
    super.initState();
    game = LafikobraForgeGame(gravity: vmath.Vector2(0, gravityY));
    _setupLavaScene();

    _autoSpawnTimer = Timer.periodic(const Duration(milliseconds: 1100), (_) {
      if (autoSpawn && !isPaused) {
        _spawnRandomBlock();
      }
    });

    _lavaParticleTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!isPaused) {
        _spawnLavaParticle();
      }
    });
  }

  void _setupLavaScene() {
    gear = ShredderGearBody(
      position: vmath.Vector2(0.0, 6.0),
      radius: 5.0,
      speed: gearSpeed,
      clockwise: true,
    );
    game.add(gear);
  }

  void _spawnLavaParticle() {
    final rand = math.Random();
    double px = (rand.nextDouble() - 0.5) * 12.0;
    game.add(ParticleBodyComponent(
      initialPosition: vmath.Vector2(px, 18.0),
      initialVelocity: vmath.Vector2((rand.nextDouble() - 0.5) * 4, -5.0 - rand.nextDouble() * 5.0),
      color: Color.lerp(const Color(0xFFFF4500), const Color(0xFFFFD700), rand.nextDouble())!,
      radius: 0.35,
      isFluid: true,
    ));
  }

  void _spawnRandomBlock([vmath.Vector2? pos]) {
    final rand = math.Random();
    TetrisType type = TetrisType.values[rand.nextInt(TetrisType.values.length)];
    Color color = TetrisForgeBody.getColorForType(type);

    vmath.Vector2 spawnPos = pos ?? vmath.Vector2((rand.nextDouble() - 0.5) * 8.0, -18.0);

    game.add(TetrisForgeBody(
      initialPosition: spawnPos,
      shapeType: type,
      color: color,
    ));
  }

  @override
  void dispose() {
    _autoSpawnTimer?.cancel();
    _lavaParticleTimer?.cancel();
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
                game.setGravityY(gravityY);
              });
            },
            shredderSpeed: gearSpeed,
            onShredderSpeedChanged: (val) {
              setState(() {
                gearSpeed = val;
                gear.setMotorSpeed(gearSpeed);
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
