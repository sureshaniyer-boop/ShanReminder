import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shan_reminder/models/task.dart';
import 'package:shan_reminder/screens/home_screen.dart';
import 'package:shan_reminder/theme/app_theme.dart';

void main() {
  setUpAll(() async {
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    final root = Platform.environment['FLUTTER_ROOT'];
    if (root != null) {
      final font = File('$root/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf');
      if (font.existsSync()) {
        final loader = FontLoader('Roboto')
          ..addFont(Future.value(ByteData.sublistView(font.readAsBytesSync())));
        await loader.load();
      }
    }
  });

  Future<void> mount(WidgetTester tester, String theme,
      {bool populated = false, double width = 412, double scale = 1}) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, 915);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final now = DateTime.now();
    final tasks = populated ? [
      TaskItem(id: '1', title: 'Prepare the weekly project update',
        description: '', dueAt: DateTime(now.year, now.month, now.day, 16),
        reminderMinutesBefore: 10, repeat: 'None', priority: 'High',
        category: 'Work', completed: false),
      TaskItem(id: '2', title: 'A moment for prayer',
        description: '', dueAt: DateTime(now.year, now.month, now.day, 12),
        reminderMinutesBefore: 10, repeat: 'None', priority: 'Medium',
        category: 'Personal', completed: true),
    ] : <TaskItem>[];
    await tester.pumpWidget(RepaintBoundary(
      key: const ValueKey('home-preview'),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.build(theme),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale), padding: const EdgeInsets.only(top: 24)),
          child: child!),
        home: HomeScreen(tasks: tasks, themeName: theme,
          onAdd: (_) async {}, onToggle: (_, _) async {},
          onDelete: (_) async {}, onThemeChanged: (_) {}),
      ),
    ));
    await tester.pumpAndSettle();
  }

  for (final theme in AppTheme.themeColors.keys) {
    for (final populated in [false, true]) {
      testWidgets('$theme renders ${populated ? "tasks" : "empty state"}', (tester) async {
        await mount(tester, theme, populated: populated);
        expect(tester.takeException(), isNull);
        expect(find.byType(FloatingActionButton), populated ? findsOneWidget : findsNothing);
        await expectLater(find.byKey(const ValueKey('home-preview')),
          matchesGoldenFile('previews/${theme.replaceAll(" ", "_")}_${populated ? "tasks" : "empty"}.png'));
      });
    }
  }

  testWidgets('Small screen with enlarged text and working navigation', (tester) async {
    await mount(tester, 'Cream', width: 320, scale: 1.6);
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(find.text('Plan my first task'), 150,
      scrollable: find.byType(Scrollable).first);
    expect(tester.takeException(), isNull);
    await mount(tester, 'Emerald');
    await tester.ensureVisible(find.text('Plan my first task'));
    await tester.tap(find.text('Plan my first task'));
    await tester.pumpAndSettle();
    expect(find.text('Save Task & Reminder'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tasks').last);
    await tester.pumpAndSettle();
    expect(find.text('No tasks yet. Tap + to create your first reminder.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
