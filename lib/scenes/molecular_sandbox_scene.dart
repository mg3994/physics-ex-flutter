import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../physics/physics_engine.dart';
import '../physics/particle_and_gear.dart';
import '../physics/vector2d.dart';
import '../widgets/physics_painter.dart';

class MolecularSandboxScene extends StatefulWidget {
  const MolecularSandboxScene({super.key});

  @override
  State<MolecularSandboxScene> createState() => _MolecularSandboxSceneState();
}

class _MolecularSandboxSceneState extends State<MolecularSandboxScene> with SingleTickerProviderStateMixin {
  late PhysicsEngine engine;
  late AnimationController _ticker;
  double gravityY = 300.0;
  bool isPaused = false;
  Vector2D? touchPoint;
  bool attractMode = false;

  @override
  void initState() {
    super.initState();
    engine = PhysicsEngine(gravity: Vector2D(0, gravityY));
    _ticker = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat();
    _ticker.addListener(_onTick);

    _populateMolecules(350);
  }

  void _populateMolecules(int count) {
    final rand = math.Random();
    List<Color> palette = [
      const Color(0xFF00F0FF),
      const Color(0xFFFF007F),
      const Color(0xFF39FF14),
      const Color(0xFFFFFF00),
      const Color(0xFFBF00FF),
    ];

    for (int i = 0; i < count; i++) {
      Color col = palette[rand.nextInt(palette.length)];
      engine.particles.add(Particle(
        position: Vector2D(100.0 + rand.nextDouble() * 350.0, 50.0 + rand.nextDouble() * 200.0),
        velocity: Vector2D((rand.nextDouble() - 0.5) * 100, (rand.nextDouble() - 0.5) * 100),
        color: col,
        radius: 3.5 + rand.nextDouble() * 3.5,
        maxLife: double.infinity,
      ));
    }
  }

  void _onTick() {
    if (!isPaused) {
      setState(() {
        _updateMolecules();
        engine.update(0.016);
      });
    }
  }

  void _updateMolecules() {
    double boundsW = engine.boundsWidth;
    double boundsH = engine.boundsHeight;

    for (var p in engine.particles) {
      if (touchPoint != null) {
        double dist = p.position.distanceTo(touchPoint!);
        if (dist < 180.0 && dist > 1.0) {
          Vector2D dir = (p.position - touchPoint!).normalized;
          double force = (180.0 - dist) * (attractMode ? -15.0 : 25.0);
          p.velocity = p.velocity + dir * (force * 0.016);
        }
      }

      if (p.position.y > boundsH - 12) {
        p.position = Vector2D(p.position.x, boundsH - 12);
        p.velocity = Vector2D(p.velocity.x * 0.9, -p.velocity.y * 0.6);
      }
      if (p.position.x < 12) {
        p.position = Vector2D(12, p.position.y);
        p.velocity = Vector2D(-p.velocity.x * 0.6, p.velocity.y * 0.9);
      }
      if (p.position.x > boundsW - 12) {
        p.position = Vector2D(boundsW - 12, p.position.y);
        p.velocity = Vector2D(-p.velocity.x * 0.6, p.velocity.y * 0.9);
      }
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
          onPanStart: (d) => setState(() => touchPoint = Vector2D(d.localPosition.dx, d.localPosition.dy)),
          onPanUpdate: (d) => setState(() => touchPoint = Vector2D(d.localPosition.dx, d.localPosition.dy)),
          onPanEnd: (_) => setState(() => touchPoint = null),
          onTapDown: (d) => setState(() => touchPoint = Vector2D(d.localPosition.dx, d.localPosition.dy)),
          onTapUp: (_) => setState(() => touchPoint = null),
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.2,
                    colors: [Color(0xFF0F172A), Color(0xFF020617)],
                  ),
                ),
              ),
              CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                painter: PhysicsPainter(engine: engine, showGears: false),
              ),
              if (touchPoint != null)
                Positioned(
                  left: touchPoint!.x - 50,
                  top: touchPoint!.y - 50,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: attractMode ? Colors.cyanAccent : Colors.pinkAccent,
                        width: 2,
                      ),
                      color: (attractMode ? Colors.cyanAccent : Colors.pinkAccent).withOpacity(0.15),
                    ),
                  ),
                ),
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => setState(() => attractMode = !attractMode),
                      icon: Icon(
                        attractMode ? Icons.center_focus_strong_rounded : Icons.radio_button_unchecked_rounded,
                        color: attractMode ? Colors.cyanAccent : Colors.pinkAccent,
                      ),
                      label: Text(
                        attractMode ? 'Force: Attract' : 'Force: Repel',
                        style: const TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E293B)),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => setState(() => _populateMolecules(100)),
                      icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.greenAccent),
                      label: const Text('+100 Particles', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E293B)),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 24,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withOpacity(0.9),
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
                          min: -300.0,
                          max: 800.0,
                          activeColor: Colors.purpleAccent,
                          onChanged: (val) {
                            setState(() {
                              gravityY = val;
                              engine.gravity = Vector2D(0, gravityY);
                            });
                          },
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => isPaused = !isPaused),
                        icon: Icon(isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded, color: Colors.amberAccent),
                      ),
                      IconButton(
                        onPressed: () => setState(() => engine.particles.clear()),
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
