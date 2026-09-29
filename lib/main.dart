import 'package:flutter/material.dart';
import 'scenes/scene_container.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const LafikobraPhysicsApp());
}

class LafikobraPhysicsApp extends StatelessWidget {
  const LafikobraPhysicsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lafikobra Physics Simulations',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SceneContainer(),
    );
  }
}
