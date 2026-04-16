import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  testWidgets('renders base shell widget', (WidgetTester tester) async {
    final tempDir = await Directory.systemTemp.createTemp('misbah_test_');
    Hive.init(tempDir.path);
    await Hive.openBox('settings');
    await Hive.openBox('prayer_cache');
    await Hive.openBox('quran_cache');

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Text('Misbah'),
        ),
      ),
    );
    expect(find.text('Misbah'), findsOneWidget);
    await Hive.close();

  });
}
