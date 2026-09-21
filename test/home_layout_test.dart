import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shan_reminder/models/task.dart';
import 'package:shan_reminder/screens/home_screen.dart';
import 'package:shan_reminder/theme/app_theme.dart';
import 'package:shan_reminder/screens/settings_screen.dart';

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

  testWidgets('Header stays fixed while the task area scrolls', (tester) async {
    await mount(tester, 'Maroon', populated: true);
    final before = tester.getTopLeft(find.text('ShanReminder'));
    final list = find.byKey(const ValueKey('today-task-list'));
    await tester.drag(list, const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('ShanReminder')), before);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Priority labels have distinct accessible colours', (tester) async {
    await mount(tester, 'Maroon', populated: true);
    final high = tester.widget<Text>(find.text('High priority'));
    final medium = tester.widget<Text>(find.text('Medium priority'));
    expect(high.style?.color, const Color(0xFFB42318));
    expect(medium.style?.color, const Color(0xFF946200));
  });

  testWidgets('Custom title validates and saves trimmed text', (tester) async {
    String? saved;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SettingsScreen(
      themeName: 'Maroon', appTitle: 'ShanReminder', onThemeChanged: (_) {},
      onTitleChanged: (title) async { saved = title; },
    ))));
    await tester.tap(find.text('App title'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '   ');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a name'), findsOneWidget);
    expect(saved, isNull);
    await tester.enterText(find.byType(TextFormField), '  My Executive Planner  ');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(saved, 'My Executive Planner');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Small screen with enlarged text and working navigation', (tester) async {
    await mount(tester, 'Cream', width: 320, scale: 1.6);
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(find.text('Plan my first task'), 150,
      scrollable: find.descendant(of: find.byKey(const ValueKey('today-task-list')), matching: find.byType(Scrollable)));
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
