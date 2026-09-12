import 'package:fl_select/fl_select.dart'
    hide SelectBadge, SelectPanel, SelectTabBar, SelectWrapView;
import 'package:fl_select/src/select/select_panel.dart';
import 'package:fl_select/src/select/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Set<SelectEntry<dynamic>> get _categoryEntries => {
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
    children: {SelectTextEntry<dynamic>.name(id: 'b1', name: 'B 1')},
  ),
};

/// Same as [_categoryEntries], but the first category starts with an "Any"
/// placeholder child, which must never badge its tab on its own.
Set<SelectEntry<dynamic>> get _categoryEntriesWithAny => {
  SelectCategoryEntry<dynamic>.children(
    id: 'cate1',
    name: 'Cate 1',
    children: {
      SelectTextEntry<dynamic>.any(parentId: 'cate1', name: 'Any'),
      SelectTextEntry<dynamic>.name(id: 'a1', name: 'A 1'),
    },
  ),
  SelectCategoryEntry<dynamic>.children(
    id: 'cate2',
    name: 'Cate 2',
    children: {SelectTextEntry<dynamic>.name(id: 'b1', name: 'B 1')},
  ),
};

Widget _harness(
  SelectController controller, {
  Set<SelectEntry<dynamic>>? entries,
}) => MaterialApp(
  home: Scaffold(
    // SelectPanel without a SelectActionBarVisibility scope keeps the
    // action bar visible (SelectView hides it for inline usage).
    body: SelectPanel(
      delegate: TabNavSelectDelegate(
        selectionMode: SelectionMode.multiple,
        entries: entries ?? _categoryEntries,
      ),
      controller: controller,
    ),
  ),
);

void main() {
  testWidgets('Reset clears only the focused tab and keeps the others', (
    tester,
  ) async {
    final controller = SelectController(selectionMode: SelectionMode.multiple);
    await tester.pumpWidget(_harness(controller));
    await tester.pumpAndSettle();

    expect(find.text('Reset'), findsOneWidget);

    // Pending selections in the first tab...
    await tester.tap(find.text('A 1'));
    await tester.pumpAndSettle();

    // ...and in the second tab.
    await tester.tap(find.text('Cate 2'));
    await tester.pumpAndSettle();
    expect(find.text('B 1'), findsOneWidget);
    await tester.tap(find.text('B 1'));
    await tester.pumpAndSettle();

    expect(
      controller.selectedEntriesAtLevel(1).map((e) => e.id),
      containsAll(<String>['a1', 'b1']),
    );

    // Reset while Cate 2 is focused...
    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();

    // ...clears only the focused tab's selection...
    final ids = controller.selectedEntriesAtLevel(1).map((e) => e.id);
    expect(ids, containsAll(<String>['a1']));
    expect(ids, isNot(contains('b1')));

    // ...keeps focus on the same tab...
    expect(find.text('B 1'), findsOneWidget);
    expect(find.text('A 1'), findsNothing);

    // ...and the untouched tab's selection survives switching back to it.
    await tester.tap(find.text('Cate 1'));
    await tester.pumpAndSettle();
    expect(find.text('A 1'), findsOneWidget);
  });

  testWidgets('a tab is badged while its category holds a real selection', (
    tester,
  ) async {
    final controller = SelectController(selectionMode: SelectionMode.multiple);
    await tester.pumpWidget(_harness(controller));
    await tester.pumpAndSettle();

    // Nothing is selected yet, so no tab carries a badge.
    expect(find.byType(SelectBadge), findsNothing);

    // Selecting a child badges its own tab...
    await tester.tap(find.text('A 1'));
    await tester.pumpAndSettle();
    expect(find.byType(SelectBadge), findsOneWidget);

    // ...and the badge survives switching away, so the pending selection in
    // the other tab stays visible.
    await tester.tap(find.text('Cate 2'));
    await tester.pumpAndSettle();
    expect(find.byType(SelectBadge), findsOneWidget);

    await tester.tap(find.text('B 1'));
    await tester.pumpAndSettle();
    expect(find.byType(SelectBadge), findsNWidgets(2));

    // Reset clears the focused tab (Cate 2) and with it that tab's badge.
    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();
    expect(find.byType(SelectBadge), findsOneWidget);
  });

  testWidgets('selecting only the "Any" entry does not badge its tab', (
    tester,
  ) async {
    final controller = SelectController(selectionMode: SelectionMode.multiple);
    await tester.pumpWidget(
      _harness(controller, entries: _categoryEntriesWithAny),
    );
    await tester.pumpAndSettle();

    // "Any" is selected by default (initializeAnyIfEmpty)...
    expect(find.text('Any'), findsOneWidget);
    // ...but a placeholder selection alone must not produce a badge.
    expect(find.byType(SelectBadge), findsNothing);

    // A real child selection does.
    await tester.tap(find.text('A 1'));
    await tester.pumpAndSettle();
    expect(find.byType(SelectBadge), findsOneWidget);
  });

  testWidgets(
    'a later category owning "Any" does not steal the initial tab focus',
    (tester) async {
      final controller = SelectController(
        selectionMode: SelectionMode.multiple,
      );
      await tester.pumpWidget(
        _harness(
          controller,
          entries: {
            SelectCategoryEntry<dynamic>.children(
              id: 'cate1',
              name: 'Cate 1',
              children: {SelectTextEntry<dynamic>.name(id: 'a1', name: 'A 1')},
            ),
            SelectCategoryEntry<dynamic>.children(
              id: 'cate2',
              name: 'Cate 2',
              children: {
                SelectTextEntry<dynamic>.any(parentId: 'cate2', name: 'Any'),
              },
            ),
          },
        ),
      );
      await tester.pumpAndSettle();

      // initializeAnyIfEmpty auto-selects Cate 2's "Any" placeholder, but that
      // is not a real selection: the first tab must stay focused and show its
      // children.
      expect(find.text('A 1'), findsOneWidget);
      expect(find.text('Any'), findsNothing);
    },
  );

  testWidgets('a restored real selection drives the initial tab focus', (
    tester,
  ) async {
    final controller = SelectController(
      selectionMode: SelectionMode.multiple,
      selectedEntries: {
        SelectCategoryEntry<dynamic>.children(
          id: 'cate2',
          name: 'Cate 2',
          children: {SelectTextEntry<dynamic>.name(id: 'b1', name: 'B 1')},
        ),
      },
    );
    await tester.pumpWidget(_harness(controller));
    await tester.pumpAndSettle();

    // The restored selection lives in Cate 2, so that tab is focused even
    // though Cate 1 comes first.
    expect(find.text('B 1'), findsOneWidget);
    expect(find.text('A 1'), findsNothing);
  });

  group('TabNavSelect grid category structure', () {
    Widget gridHarness(
      Set<SelectEntry> entries, {
      SelectionMode selectionMode = SelectionMode.single,
      void Function(Set<SelectEntry>)? onChanged,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: SelectView(
            delegate: TabNavSelectDelegate(
              defaultLayout: const SelectGridLayout(crossAxisCount: 3),
              selectionMode: selectionMode,
              entriesLoader: () async => entries,
            ),
            onChanged: onChanged ?? (_) {},
          ),
        ),
      );
    }

    testWidgets('renders category tabs and the focused category grid', (
      tester,
    ) async {
      await tester.pumpWidget(
        gridHarness({
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
                parentId: 'c2',
                id: 'c2-1',
                name: 'Three',
              ),
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

    testWidgets('tapping a tab switches the focused category grid', (
      tester,
    ) async {
      await tester.pumpWidget(
        gridHarness({
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
                parentId: 'c2',
                id: 'c2-1',
                name: 'Three',
              ),
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

  group('TabNavSelect category header/footer', () {
    SelectCategoryEntry<dynamic> categoryWithHeaderFooter() =>
        SelectCategoryEntry<dynamic>(
          id: 'c1',
          name: 'C1',
          layout: const SelectGridLayout(crossAxisCount: 3),
          header: SelectTextEntry<dynamic>(
            parentId: 'c1',
            id: 'header',
            name: 'Header',
            children: {
              SelectTextEntry<dynamic>(
                parentId: 'header',
                id: 'h1',
                name: 'H1',
                immediate: true,
              ),
              SelectTextEntry<dynamic>(
                parentId: 'header',
                id: 'h2',
                name: 'H2',
                immediate: true,
              ),
            },
          ),
          children: {
            SelectTextEntry<dynamic>(parentId: 'c1', id: 'any', name: 'Any'),
            SelectTextEntry<dynamic>(parentId: 'c1', id: 'c1-1', name: 'One'),
          },
          footer: SelectTextEntry<dynamic>(
            parentId: 'c1',
            id: 'footer',
            name: 'Footer',
            children: {
              SelectTextEntry<dynamic>(
                parentId: 'footer',
                id: 'f1',
                name: 'F1',
                immediate: true,
              ),
            },
          ),
        );

    testWidgets('renders header/footer chip bars around the category grid', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectView(
              delegate: TabNavSelectDelegate(
                defaultLayout: const SelectGridLayout(crossAxisCount: 3),
                entriesLoader: () async => {categoryWithHeaderFooter()},
              ),
              onChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SelectWrapView), findsNWidgets(2));
      expect(find.text('H1'), findsOneWidget);
      expect(find.text('H2'), findsOneWidget);
      expect(find.text('One'), findsOneWidget);
      expect(find.text('F1'), findsOneWidget);

      // Vertical order: header chips -> category grid -> footer chips.
      expect(
        tester.getTopLeft(find.text('H1')).dy,
        lessThan(tester.getTopLeft(find.text('One')).dy),
      );
      expect(
        tester.getTopLeft(find.text('One')).dy,
        lessThan(tester.getTopLeft(find.text('F1')).dy),
      );
    });

    testWidgets('tapping header/footer children applies their selections', (
      tester,
    ) async {
      final applied = <Set<SelectEntry>>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectView(
              delegate: TabNavSelectDelegate(
                defaultLayout: const SelectGridLayout(crossAxisCount: 3),
                selectionMode: SelectionMode.multiple,
                entriesLoader: () async => {categoryWithHeaderFooter()},
              ),
              onChanged: applied.add,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('H1'));
      await tester.pumpAndSettle();
      expect(applied, hasLength(1));
      final root1 = applied.last.cast<SelectCategoryEntry<dynamic>>().single;
      expect(root1.header?.children?.map((e) => e.id), contains('h1'));

      await tester.tap(find.text('F1'));
      await tester.pumpAndSettle();
      expect(applied, hasLength(2));
      final root2 = applied.last.cast<SelectCategoryEntry<dynamic>>().single;
      expect(root2.header?.children?.map((e) => e.id), contains('h1'));
      expect(root2.footer?.children?.map((e) => e.id), contains('f1'));
    });
  });
}
