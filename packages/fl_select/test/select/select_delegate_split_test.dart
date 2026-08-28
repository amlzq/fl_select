import 'package:fl_select/fl_select.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Direct coverage for the four delegates introduced by the split:
/// [WrapSelectDelegate], [TabNavSelectDelegate], [SideNavSelectDelegate]
/// and [ExpandableSelectDelegate]. Each new delegate accepts exactly one
/// data shape and asserts on the other; the deprecated dual-mode paths in
/// [GridSelectDelegate], [FlattenSelectDelegate] and [ListSelectDelegate]
/// are covered by their existing test files.

Set<SelectEntry> get _flatEntries => {
      SelectTextEntry<dynamic>.name(id: 'a', name: 'A'),
      SelectTextEntry<dynamic>.name(id: 'b', name: 'B'),
    };

Set<SelectEntry> get _categoryEntries => {
      SelectCategoryEntry<dynamic>.children(
        id: 'cate1',
        name: 'Cate 1',
        children: {
          SelectTextEntry<dynamic>.name(id: 'a1', name: 'A 1'),
          SelectTextEntry<dynamic>.name(id: 'a2', name: 'A 2'),
        },
      ),
      SelectCategoryEntry<dynamic>.children(
        id: 'cate2',
        name: 'Cate 2',
        children: {
          SelectTextEntry<dynamic>.name(id: 'b1', name: 'B 1'),
        },
      ),
    };

Widget _harness(SelectDelegate delegate,
    {void Function(Set<SelectEntry>)? onChanged}) {
  return MaterialApp(
    home: Scaffold(
      body: SelectView(
        delegate: delegate,
        onChanged: onChanged ?? (_) {},
      ),
    ),
  );
}

void main() {
  group('TabNavSelectDelegate', () {
    testWidgets('renders category tabs and applies a selection',
        (tester) async {
      final applied = <Set<SelectEntry>>[];
      await tester.pumpWidget(
        _harness(
          TabNavSelectDelegate(
            selectionMode: SelectionMode.single,
            entries: _categoryEntries,
          ),
          onChanged: applied.add,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cate 1'), findsOneWidget);
      expect(find.text('Cate 2'), findsOneWidget);
      expect(find.text('A 1'), findsOneWidget);

      await tester.tap(find.text('A 1'));
      await tester.pumpAndSettle();
      expect(applied, isNotEmpty);
    });

    test('asserts on flat data', () {
      expect(
        () => TabNavSelectDelegate(entries: _flatEntries),
        throwsAssertionError,
      );
    });
  });

  group('SideNavSelectDelegate', () {
    testWidgets('renders a sidebar and applies a selection', (tester) async {
      final applied = <Set<SelectEntry>>[];
      await tester.pumpWidget(
        _harness(
          SideNavSelectDelegate(
            selectionMode: SelectionMode.single,
            entries: _categoryEntries,
          ),
          onChanged: applied.add,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SelectSideBar), findsOneWidget);
      // Once in the sidebar, once as the right column's section header.
      expect(find.text('Cate 1'), findsNWidgets(2));
      expect(find.text('A 1'), findsOneWidget);

      await tester.tap(find.text('A 1'));
      await tester.pumpAndSettle();
      expect(applied, isNotEmpty);
    });

    test('asserts on flat data', () {
      expect(
        () => SideNavSelectDelegate(entries: _flatEntries),
        throwsAssertionError,
      );
    });
  });

  group('WrapSelectDelegate', () {
    testWidgets('renders a chip bar and applies a selection', (tester) async {
      final applied = <Set<SelectEntry>>[];
      await tester.pumpWidget(
        _harness(
          WrapSelectDelegate(
            selectionMode: SelectionMode.single,
            entries: _flatEntries,
          ),
          onChanged: applied.add,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SelectChipBar), findsOneWidget);
      expect(find.byType(SelectSideBar), findsNothing);
      expect(find.text('A'), findsOneWidget);

      await tester.tap(find.text('A'));
      await tester.pumpAndSettle();
      expect(applied, isNotEmpty);
    });

    test('asserts on category data', () {
      expect(
        () => WrapSelectDelegate(entries: _categoryEntries),
        throwsAssertionError,
      );
    });
  });

  group('ExpandableSelectDelegate', () {
    testWidgets(
        'renders one expandable tile per category and applies a '
        'selection', (tester) async {
      final applied = <Set<SelectEntry>>[];
      await tester.pumpWidget(
        _harness(
          ExpandableSelectDelegate(
            selectionMode: SelectionMode.single,
            entries: _categoryEntries,
          ),
          onChanged: applied.add,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SelectExpansionTile), findsNWidgets(2));
      expect(find.text('Cate 1'), findsOneWidget);
      expect(find.text('A 1'), findsOneWidget);

      await tester.tap(find.text('A 1'));
      await tester.pumpAndSettle();
      expect(applied, isNotEmpty);
    });

    test('asserts on flat data', () {
      expect(
        () => ExpandableSelectDelegate(entries: _flatEntries),
        throwsAssertionError,
      );
    });
  });
}
