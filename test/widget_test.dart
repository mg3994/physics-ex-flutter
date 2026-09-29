import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:physics_simulations/main.dart';

void main() {
  testWidgets('App renders SceneContainer and shows Tetris Shredder Machine title', (WidgetTester tester) async {
    await tester.pumpWidget(const LafikobraPhysicsApp());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Tetris Shredder Machine'), findsOneWidget);
  });

  testWidgets('End drawer opens and displays scene switching choices', (WidgetTester tester) async {
    await tester.pumpWidget(const LafikobraPhysicsApp());
    await tester.pump(const Duration(milliseconds: 100));

    final drawerButton = find.byIcon(Icons.grid_view_rounded);
    expect(drawerButton, findsOneWidget);

    await tester.tap(drawerButton);
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Lafikobra Physics Lab'), findsOneWidget);
    expect(find.text('Laser Cutter Shredder'), findsOneWidget);
    expect(find.text('Lava Melt Chamber'), findsOneWidget);
    expect(find.text('Molecular Physics Sandbox'), findsOneWidget);
  });
}
