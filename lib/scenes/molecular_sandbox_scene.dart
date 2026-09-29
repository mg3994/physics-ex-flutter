import 'dart:math' as math;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vmath;
import '../physics/forge2d_world.dart';
import '../physics/forge_particle_system.dart';

class MolecularSandboxScene extends StatefulWidget {
  const MolecularSandboxScene({super.key});

  @override
  State<MolecularSandboxScene> createState() => _MolecularSandboxSceneState();
}

class _MolecularSandboxSceneState extends State<MolecularSandboxScene> {
  late LafikobraForgeGame game;
  double gravityY = 20.0;
  bool isPaused = false;

  @override
  void initState() {
    super.initState();
    game = LafikobraForgeGame(gravity: vmath.Vector2(0, gravityY));
    _spawnMolecules(80);
  }

  void _spawnMolecules(int count) {
    final rand = math.Random();
    List<Color> palette = [
      const Color(0xFF00F0FF),
      const Color(0xFFFF007F),
      const Color(0xFF39FF14),
      const Color(0xFFFFFF00),
      const Color(0xFFBF00FF),
    ];

    for (int i = 0; i < count; i++) {
      Color color = palette[rand.nextInt(palette.length)];
      vmath.Vector2 pos = vmath.Vector2((rand.nextDouble() - 0.5) * 16.0, -15.0 + (rand.nextDouble() - 0.5) * 10.0);
      vmath.Vector2 vel = vmath.Vector2((rand.nextDouble() - 0.5) * 20.0, (rand.nextDouble() - 0.5) * 20.0);

      game.add(ParticleBodyComponent(
        initialPosition: pos,
        initialVelocity: vel,
        color: color,
        radius: 0.45,
        isFluid: true,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GameWidget(game: game),
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton.icon(
                onPressed: () => _spawnMolecules(30),
                icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.purpleAccent),
                label: const Text('+30 Molecules', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E293B)),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        isPaused = !isPaused;
                        if (isPaused) {
                          game.pauseEngine();
                        } else {
                          game.resumeEngine();
                        }
                      });
                    },
                    icon: Icon(isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded, color: Colors.amberAccent),
                  ),
                  IconButton(
                    onPressed: () => setState(() => game.clearAllBodies()),
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                  ),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 24,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withOpacity(0.9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                const Icon(Icons.arrow_downward_rounded, size: 18, color: Colors.white70),
                const SizedBox(width: 8),
                const Text('Gravity:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                Expanded(
                  child: Slider(
                    value: gravityY,
                    min: -50.0,
                    max: 80.0,
                    activeColor: Colors.purpleAccent,
                    onChanged: (val) {
                      setState(() {
                        gravityY = val;
                        game.setGravityY(gravityY);
                      });
                    },
                  ),
                ),
                Text('${gravityY.round()}', style: const TextStyle(color: Colors.purpleAccent, fontSize: 12)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
