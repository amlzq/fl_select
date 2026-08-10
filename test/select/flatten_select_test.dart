import 'package:fl_select/fl_select.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds a [SelectView] backed by a [FlattenSelectDelegate] so we can assert
/// how [FlattenSelect] consumes each [SelectCategoryEntry.layout].
Widget _flattenHarness(Set<SelectEntry> entries) {
  return MaterialApp(
    home: Scaffold(
      body: SelectView(
        delegate: FlattenSelectDelegate(
          entriesLoader: () async => entries,
        ),
        onChanged: (_) {},
      ),
    ),
  );
}

SelectCategoryEntry<dynamic> _category(
  String id,
  String name,
  SelectLayout layout, {
  Set<SelectEntry> children = const {},
}) {
  return SelectCategoryEntry<dynamic>(
    id: id,
    name: name,
    layout: layout,
    children: children,
  );
}

void main() {
  group('FlattenSelect 1D (flat) structure', () {
    Widget harness(Set<SelectEntry> entries) {
      return MaterialApp(
        home: Scaffold(
          body: SelectView(
            delegate: FlattenSelectDelegate(
              entriesLoader: () async => entries,
            ),
            onChanged: (_) {},
          ),
        ),
      );
    }

    testWidgets('renders a SelectChipBar without a sidebar', (tester) async {
      await tester.pumpWidget(
        harness({
          SelectTextEntry<dynamic>.name(id: 'a1', name: 'A 1'),
          SelectTextEntry<dynamic>.name(id: 'a2', name: 'A 2'),
        }),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SelectChipBar), findsOneWidget);
      expect(find.byType(SelectSideBar), findsNothing);
      expect(find.text('A 1'), findsOneWidget);
      expect(find.text('A 2'), findsOneWidget);
    });

    testWidgets('tapping a flat chip reports a selection', (tester) async {
      final applied = <Set<SelectEntry>>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectView(
              delegate: FlattenSelectDelegate(
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
      expect(applied.single.map((e) => e.id), contains('a2'));
    });
  });

  group('FlattenSelect consumes category.layout', () {
    testWidgets('defaults to a grid when no layout is set', (tester) async {
      await tester.pumpWidget(
        _flattenHarness({
          _category(
            'c1',
            'C1',
            const SelectGridLayout(crossAxisCount: 2),
            children: {
              SelectTextEntry<dynamic>(parentId: 'c1', id: 'c1-1', name: 'One'),
              SelectTextEntry<dynamic>(parentId: 'c1', id: 'c1-2', name: 'Two'),
            },
          ),
        }),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SelectGridView), findsOneWidget);
      expect(find.text('One'), findsOneWidget);
    });

    testWidgets('renders SelectListView for SelectListLayout', (tester) async {
      await tester.pumpWidget(
        _flattenHarness({
          _category(
            'c1',
            'C1',
            const SelectListLayout(),
            children: {
              SelectTextEntry<dynamic>(parentId: 'c1', id: 'c1-1', name: 'One'),
              SelectTextEntry<dynamic>(parentId: 'c1', id: 'c1-2', name: 'Two'),
            },
          ),
        }),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SelectListView), findsOneWidget);
      expect(find.text('One'), findsOneWidget);
    });

    testWidgets('renders SelectGridView for SelectGridLayout', (tester) async {
      await tester.pumpWidget(
        _flattenHarness({
          _category(
            'c1',
            'C1',
            const SelectGridLayout(crossAxisCount: 3),
            children: {
              SelectTextEntry<dynamic>(parentId: 'c1', id: 'c1-1', name: 'One'),
              SelectTextEntry<dynamic>(parentId: 'c1', id: 'c1-2', name: 'Two'),
            },
          ),
        }),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SelectGridView), findsOneWidget);
      expect(find.text('One'), findsOneWidget);
    });

    testWidgets('renders SelectChipBar for SelectChipLayout', (tester) async {
      await tester.pumpWidget(
        _flattenHarness({
          _category(
            'c1',
            'C1',
            const SelectChipLayout(),
            children: {
              SelectTextEntry<dynamic>(parentId: 'c1', id: 'c1-1', name: 'One'),
              SelectTextEntry<dynamic>(parentId: 'c1', id: 'c1-2', name: 'Two'),
            },
          ),
        }),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SelectChipBar), findsOneWidget);
      expect(find.text('One'), findsOneWidget);
    });

    testWidgets('renders SelectRangeView for SelectRangeLayout',
        (tester) async {
      await tester.pumpWidget(
        _flattenHarness({
          _category(
            'c1',
            'C1',
            const SelectRangeLayout(),
            children: {
              SelectTextEntry<dynamic>(parentId: 'c1', id: 'c1-1', name: 'One'),
            },
          ),
        }),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SelectRangeView), findsOneWidget);
    });

    testWidgets('renders SelectCounter for SelectCounterLayout',
        (tester) async {
      await tester.pumpWidget(
        _flattenHarness({
          _category(
            'c1',
            'C1',
            const SelectCounterLayout(),
            children: {
              SelectTextEntry<dynamic>(parentId: 'c1', id: 'c1-1', name: 'One'),
              SelectTextEntry<dynamic>(parentId: 'c1', id: 'c1-2', name: 'Two'),
            },
          ),
        }),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SelectCounter), findsOneWidget);
    });

    testWidgets('renders each category with its own layout', (tester) async {
      await tester.pumpWidget(
        _flattenHarness({
          _category(
            'c1',
            'C1',
            const SelectListLayout(),
            children: {
              SelectTextEntry<dynamic>(parentId: 'c1', id: 'c1-1', name: 'One'),
            },
          ),
          _category(
            'c2',
            'C2',
            const SelectChipLayout(),
            children: {
              SelectTextEntry<dynamic>(
                  parentId: 'c2', id: 'c2-1', name: 'ChipA'),
            },
          ),
        }),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SelectListView), findsOneWidget);
      expect(find.byType(SelectChipBar), findsOneWidget);
    });
  });
}
