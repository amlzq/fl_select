import 'package:fl_select/fl_select.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds a [SelectView] backed by a [GridSelectDelegate] so we can assert how
/// [GridSelect] renders flat (parentless) structures.
Widget _gridHarness(
  Set<SelectEntry> entries, {
  SelectionMode selectionMode = SelectionMode.single,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SelectView(
        delegate: GridSelectDelegate(
          crossAxisCount: 3,
          selectionMode: selectionMode,
          entriesLoader: () async => entries,
        ),
        onChanged: (_) {},
      ),
    ),
  );
}

void main() {
  group('GridSelect flat structure', () {
    testWidgets('renders a grid without category tabs', (tester) async {
      await tester.pumpWidget(
        _gridHarness({
          SelectTextEntry<dynamic>.name(id: 'a1', name: 'A 1'),
          SelectTextEntry<dynamic>.name(id: 'a2', name: 'A 2'),
          SelectTextEntry<dynamic>.name(id: 'a3', name: 'A 3'),
        }),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SelectGridView), findsOneWidget);
      expect(find.byType(SelectTabBar), findsNothing);
      expect(find.text('A 1'), findsOneWidget);
      expect(find.text('A 2'), findsOneWidget);
      expect(find.text('A 3'), findsOneWidget);
    });

    testWidgets('single selection taps a flat tile', (tester) async {
      final applied = <Set<SelectEntry>>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectView(
              delegate: GridSelectDelegate(
                crossAxisCount: 3,
                selectionMode: SelectionMode.single,
                entriesLoader: () async => {
                  SelectTextEntry<dynamic>.name(id: 'a1', name: 'A 1'),
                  SelectTextEntry<dynamic>.name(id: 'a2', name: 'A 2'),
                },
              ),
              onChanged: applied.add,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('A 2'));
      await tester.pumpAndSettle();

      expect(applied, hasLength(1));
      final selected = applied.single;
      expect(selected.map((e) => e.id), contains('a2'));
    });
  });
}
