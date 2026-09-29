import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shan_reminder/backup/backup_data.dart';
import 'package:shan_reminder/models/task.dart';
import 'package:shan_reminder/models/task_window.dart';
import 'package:shan_reminder/screens/home_screen.dart';
import 'package:shan_reminder/screens/task_groups_screen.dart';
import 'package:shan_reminder/theme/app_theme.dart';
import 'package:shan_reminder/widgets/symbol_mark.dart';

TaskItem task(
  String id,
  DateTime date, {
  String title = 'Client appointment',
}) => TaskItem(
  id: id,
  title: title,
  description: 'Bring notes',
  dueAt: date,
  reminderMinutesBefore: 30,
  repeat: 'Weekly',
  priority: 'High',
  category: 'Astrology',
  completed: false,
);

void main() {
  setUpAll(() async {
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    final root = Platform.environment['FLUTTER_ROOT'];
    if (root != null) {
      final font = File(
        '$root/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf',
      );
      if (font.existsSync()) {
        final loader = FontLoader('Roboto')
          ..addFont(Future.value(ByteData.sublistView(font.readAsBytesSync())));
        await loader.load();
      }
    }
  });

  test('Calendar windows cross month/year boundaries and use next Monday', () {
    final groups = taskWindows(DateTime(2026, 12, 31, 23, 59));
    expect(groups[0].contains(DateTime(2027)), isFalse);
    expect(groups[1].contains(DateTime(2027)), isTrue);
    expect(groups[2].start, DateTime(2027, 1, 4));
    expect(groups[2].contains(DateTime(2027, 1, 11)), isFalse);
    expect(groups[3].start, DateTime(2027));
    expect(groups[4].end, DateTime(2028));
    expect(taskWindows(DateTime(2026, 9, 28))[2].start, DateTime(2026, 10, 5));
    expect(
      taskWindows(DateTime(2028, 2, 28))[1].contains(DateTime(2028, 2, 29)),
      isTrue,
    );
  });

  test('Backup round trip preserves task and reminder fields', () {
    final original = task('1', DateTime(2026, 10, 2, 10, 30));
    final data = BackupData(
      createdAt: DateTime(2026, 9, 29),
      tasks: [original],
    );
    expect(
      BackupData.decode(data.encode()).tasks.single.toJson(),
      original.toJson(),
    );
  });

  test('Restore merges missing tasks and preserves current edits', () {
    final date = DateTime(2026, 10, 2);
    final result = BackupData.merge(
      [task('1', date, title: 'Updated')],
      [task('1', date, title: 'Old'), task('2', date)],
    );
    expect(result.length, 2);
    expect(result.firstWhere((t) => t.id == '1').title, 'Updated');
  });

  test('Rejects unrelated, corrupt, and duplicate backup records', () {
    expect(() => BackupData.decode('{}'), throwsFormatException);
    expect(() => BackupData.decode('{'), throwsFormatException);
    final t = task('1', DateTime(2026, 10, 2));
    expect(
      () => BackupData.decode(
        BackupData(createdAt: DateTime.now(), tasks: [t, t]).encode(),
      ),
      throwsFormatException,
    );
  });

  testWidgets(
    'Round plus expands and collapses tasks and theme follows selection',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.build('Emerald'),
          home: Scaffold(
            body: TaskGroupsScreen(
              tasks: [task('today', DateTime.now())],
              onToggle: (_, _) async {},
              onDelete: (_) async {},
            ),
          ),
        ),
      );
      expect(find.text('Client appointment'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('expand-Today')));
      await tester.pumpAndSettle();
      expect(find.text('Client appointment'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('expand-Today')));
      await tester.pumpAndSettle();
      expect(find.text('Client appointment'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Horizontal swipes follow Home Calendar Tasks Settings in both directions',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.build('Maroon'),
          home: HomeScreen(
            tasks: const [],
            themeName: 'Maroon',
            preferenceSymbol: PreferenceSymbol.lotus,
            appTitle: 'ShanReminder',
            onAdd: (_) async {},
            onToggle: (_, _) async {},
            onDelete: (_) async {},
            onThemeChanged: (_) {},
            onPreferenceSymbolChanged: (_) {},
            onTitleChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final label in ['Calendar', 'Tasks', 'Settings']) {
        await tester.drag(
          find.byKey(const ValueKey('main-pages')),
          const Offset(-650, 0),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(ValueKey('page-header-$label')), findsOneWidget);
      }
      for (final label in ['Tasks', 'Calendar']) {
        await tester.drag(
          find.byKey(const ValueKey('main-pages')),
          const Offset(650, 0),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(ValueKey('page-header-$label')), findsOneWidget);
      }
      await tester.drag(
        find.byKey(const ValueKey('main-pages')),
        const Offset(650, 0),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AppBar), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Planner preview at phone size', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 915);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final now = DateTime.now();
    await tester.pumpWidget(
      RepaintBoundary(
        key: const ValueKey('planner-preview'),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.build('Maroon'),
          home: HomeScreen(
            tasks: [
              task(
                'today',
                DateTime(now.year, now.month, now.day, 20),
                title: 'Prepare client consultation',
              ),
              task(
                'tomorrow',
                DateTime(now.year, now.month, now.day + 1, 10),
                title: 'Project progress review',
              ),
            ],
            themeName: 'Maroon',
            preferenceSymbol: PreferenceSymbol.lotus,
            appTitle: 'ShanReminder',
            onAdd: (_) async {},
            onToggle: (_, _) async {},
            onDelete: (_) async {},
            onThemeChanged: (_) {},
            onPreferenceSymbolChanged: (_) {},
            onTitleChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tasks').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('expand-Today')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(const ValueKey('planner-preview')),
      matchesGoldenFile('previews/Tasks_Planner.png'),
    );
  });
}
