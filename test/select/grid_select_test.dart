import 'package:fl_select/fl_select.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds a [SelectView] backed by a [GridSelectDelegate] so we can assert how
/// [GridSelect] handles both flat and two-level (category) structures.
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

  group('GridSelect two-level (category) structure', () {
    testWidgets('renders category tabs and the focused category grid',
        (tester) async {
      await tester.pumpWidget(
        _gridHarness({
          SelectCategoryEntry<dynamic>(
            id: 'c1',
            name: 'C1',
            children: {
              SelectTextEntry<dynamic>(parentId: 'c1', id: 'c1-1', name: 'One'),
              SelectTextEntry<dynamic>(parentId: 'c1', id: 'c1-2', name: 'Two'),
            },
          ),
          SelectCategoryEntry<dynamic>(
            id: 'c2',
            name: 'C2',
            children: {
              SelectTextEntry<dynamic>(
                  parentId: 'c2', id: 'c2-1', name: 'Three'),
            },
          ),
        }),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SelectTabBar), findsOneWidget);
      expect(find.text('C1'), findsOneWidget);
      expect(find.text('C2'), findsOneWidget);
      // Focused category is C1 by default, so only its children are visible.
      expect(find.text('One'), findsOneWidget);
      expect(find.text('Three'), findsNothing);
    });

    testWidgets('tapping a tab switches the focused category grid',
        (tester) async {
      await tester.pumpWidget(
        _gridHarness({
          SelectCategoryEntry<dynamic>(
            id: 'c1',
            name: 'C1',
            children: {
              SelectTextEntry<dynamic>(parentId: 'c1', id: 'c1-1', name: 'One'),
            },
          ),
          SelectCategoryEntry<dynamic>(
            id: 'c2',
            name: 'C2',
            children: {
              SelectTextEntry<dynamic>(
                  parentId: 'c2', id: 'c2-1', name: 'Three'),
            },
          ),
        }),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('C2'));
      await tester.pumpAndSettle();

      expect(find.text('One'), findsNothing);
      expect(find.text('Three'), findsOneWidget);
    });
  });
}
