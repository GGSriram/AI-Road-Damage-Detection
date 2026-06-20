import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:road_damage_detector/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('SmartRoad AI'), findsWidgets);
  });
}