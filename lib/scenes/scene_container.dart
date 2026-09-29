import 'package:flutter/material.dart';
import 'tetris_shredder_scene.dart';
import 'laser_cutter_scene.dart';
import 'lava_melt_scene.dart';
import 'molecular_sandbox_scene.dart';

class SceneContainer extends StatefulWidget {
  const SceneContainer({super.key});

  @override
  State<SceneContainer> createState() => _SceneContainerState();
}

class _SceneContainerState extends State<SceneContainer> {
  int _selectedSceneIndex = 0;

  final List<Map<String, dynamic>> _scenes = [
    {
      'title': 'Tetris Shredder Machine',
      'subtitle': 'Dual rotating gears grinding Tetris shapes into fragment debris',
      'icon': Icons.settings_brightness_rounded,
      'widget': const TetrisShredderScene(),
      'color': Colors.cyanAccent,
    },
    {
      'title': 'Laser Cutter Shredder',
      'subtitle': 'High-power laser beam slicing falling blocks with spark effects',
      'icon': Icons.bolt_rounded,
      'widget': const LaserCutterScene(),
      'color': Colors.pinkAccent,
    },
    {
      'title': 'Lava Melt Chamber',
      'subtitle': 'Hot shredder and lava pool disintegrating shapes into burning fluid',
      'icon': Icons.local_fire_department_rounded,
      'widget': const LavaMeltScene(),
      'color': Colors.deepOrangeAccent,
    },
    {
      'title': 'Molecular Physics Sandbox',
      'subtitle': 'Thousands of interactive fluid molecules with touch force fields',
      'icon': Icons.bubble_chart_rounded,
      'widget': const MolecularSandboxScene(),
      'color': Colors.purpleAccent,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final currentScene = _scenes[_selectedSceneIndex];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(currentScene['icon'], color: currentScene['color']),
            const SizedBox(width: 10),
            Text(
              currentScene['title'],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F172A),
        elevation: 4,
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.grid_view_rounded, color: Colors.white70),
              tooltip: 'Select Physics Scene',
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      endDrawer: Drawer(
        backgroundColor: const Color(0xFF1E293B),
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.science_rounded, color: Colors.cyanAccent, size: 36),
                    const SizedBox(height: 6),
                    const Text(
                      'Lafikobra Physics Lab',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Select Simulation Mode',
                      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _scenes.length,
                itemBuilder: (context, index) {
                  final item = _scenes[index];
                  final isSelected = index == _selectedSceneIndex;

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    child: Material(
                      color: isSelected ? (item['color'] as Color).withOpacity(0.15) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      clipBehavior: Clip.antiAlias,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected ? Border.all(color: item['color'] as Color, width: 1.5) : null,
                        ),
                        child: ListTile(
                          leading: Icon(item['icon'], color: item['color']),
                          title: Text(
                            item['title'],
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            item['subtitle'],
                            style: const TextStyle(color: Colors.white38, fontSize: 11),
                          ),
                          onTap: () {
                            setState(() {
                              _selectedSceneIndex = index;
                            });
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _selectedSceneIndex,
        children: _scenes.map((s) => s['widget'] as Widget).toList(),
      ),
    );
  }
}
