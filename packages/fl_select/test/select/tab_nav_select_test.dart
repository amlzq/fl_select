import 'package:fl_select/fl_select.dart';
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
        children: {
          SelectTextEntry<dynamic>.name(id: 'b1', name: 'B 1'),
        },
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
        children: {
          SelectTextEntry<dynamic>.name(id: 'b1', name: 'B 1'),
        },
      ),
    };

Widget _harness(
  SelectController controller, {
  Set<SelectEntry<dynamic>>? entries,
}) =>
    MaterialApp(
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
  testWidgets('Reset clears only the focused tab and keeps the others',
      (tester) async {
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

  testWidgets('a tab is badged while its category holds a real selection',
      (tester) async {
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

  testWidgets('selecting only the "Any" entry does not badge its tab',
      (tester) async {
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
}
