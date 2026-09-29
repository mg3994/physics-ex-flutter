import 'package:flutter/material.dart';

class ControlPanel extends StatelessWidget {
  final double gravityY;
  final ValueChanged<double> onGravityChanged;
  final double? shredderSpeed;
  final ValueChanged<double>? onShredderSpeedChanged;
  final bool? laserActive;
  final ValueChanged<bool>? onLaserActiveChanged;
  final VoidCallback onSpawnBlock;
  final VoidCallback onClearAll;
  final VoidCallback onTogglePause;
  final bool isPaused;

  const ControlPanel({
    super.key,
    required this.gravityY,
    required this.onGravityChanged,
    this.shredderSpeed,
    this.onShredderSpeedChanged,
    this.laserActive,
    this.onLaserActiveChanged,
    required this.onSpawnBlock,
    required this.onClearAll,
    required this.onTogglePause,
    required this.isPaused,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton.icon(
                onPressed: onSpawnBlock,
                icon: const Icon(Icons.add_box_rounded, color: Colors.cyanAccent),
                label: const Text('Drop Tetris Block', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF334155)),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: onTogglePause,
                    icon: Icon(
                      isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                      color: Colors.amberAccent,
                      size: 28,
                    ),
                  ),
                  IconButton(
                    onPressed: onClearAll,
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 26),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Gravity Slider (0.0 to 1200.0)
          Row(
            children: [
              const Icon(Icons.arrow_downward_rounded, size: 18, color: Colors.white70),
              const SizedBox(width: 8),
              const Text('Gravity:', style: TextStyle(color: Colors.white70, fontSize: 13)),
              Expanded(
                child: Slider(
                  value: gravityY.clamp(0.0, 1200.0),
                  min: 0.0,
                  max: 1200.0,
                  activeColor: Colors.cyanAccent,
                  onChanged: onGravityChanged,
                ),
              ),
              Text('${gravityY.round()}', style: const TextStyle(color: Colors.cyanAccent, fontSize: 12)),
            ],
          ),
          if (onShredderSpeedChanged != null && shredderSpeed != null) ...[
            Row(
              children: [
                const Icon(Icons.sync_rounded, size: 18, color: Colors.orangeAccent),
                const SizedBox(width: 8),
                const Text('Gear Speed:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                Expanded(
                  child: Slider(
                    value: shredderSpeed!,
                    min: 0.0,
                    max: 15.0,
                    activeColor: Colors.orangeAccent,
                    onChanged: onShredderSpeedChanged,
                  ),
                ),
                Text(shredderSpeed!.toStringAsFixed(1), style: const TextStyle(color: Colors.orangeAccent, fontSize: 12)),
              ],
            ),
          ],
          if (onLaserActiveChanged != null && laserActive != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.bolt_rounded, size: 18, color: Colors.pinkAccent),
                    SizedBox(width: 8),
                    Text('Laser Cutter Line:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
                Switch(
                  value: laserActive!,
                  activeColor: Colors.pinkAccent,
                  onChanged: onLaserActiveChanged,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
