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
/// placeholder child, which must never badge its tile on its own.
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
          delegate: ExpandableSelectDelegate(
            selectionMode: SelectionMode.multiple,
            entries: entries ?? _categoryEntries,
          ),
          controller: controller,
        ),
      ),
    );

void main() {
  testWidgets('a tile is badged while its category holds a real selection',
      (tester) async {
    final controller = SelectController(selectionMode: SelectionMode.multiple);
    await tester.pumpWidget(_harness(controller));
    await tester.pumpAndSettle();

    // Nothing is selected yet, so no tile carries a badge.
    expect(find.byType(SelectBadge), findsNothing);

    await tester.tap(find.text('A 1'));
    await tester.pumpAndSettle();
    expect(find.byType(SelectBadge), findsOneWidget);

    await tester.tap(find.text('B 1'));
    await tester.pumpAndSettle();
    expect(find.byType(SelectBadge), findsNWidgets(2));
  });

  testWidgets('a collapsed tile keeps its badge', (tester) async {
    final controller = SelectController(selectionMode: SelectionMode.multiple);
    await tester.pumpWidget(_harness(controller));
    await tester.pumpAndSettle();

    await tester.tap(find.text('A 1'));
    await tester.pumpAndSettle();

    // Collapsing hides the children...
    await tester.tap(find.text('Cate 1'));
    await tester.pumpAndSettle();
    expect(find.text('A 1'), findsNothing);

    // ...but the badge keeps the pending selection visible.
    expect(find.byType(SelectBadge), findsOneWidget);

    // Expanding again restores the children and drops nothing.
    await tester.tap(find.text('Cate 1'));
    await tester.pumpAndSettle();
    expect(find.text('A 1'), findsOneWidget);
    expect(find.byType(SelectBadge), findsOneWidget);
  });

  testWidgets('selecting only the "Any" entry does not badge its tile',
      (tester) async {
    final controller = SelectController(selectionMode: SelectionMode.multiple);
    await tester.pumpWidget(
        _harness(controller, entries: _categoryEntriesWithAny));
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

  testWidgets('Reset clears every badge', (tester) async {
    final controller = SelectController(selectionMode: SelectionMode.multiple);
    await tester.pumpWidget(_harness(controller));
    await tester.pumpAndSettle();

    await tester.tap(find.text('A 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('B 1'));
    await tester.pumpAndSettle();
    expect(find.byType(SelectBadge), findsNWidgets(2));

    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();

    expect(controller.selectedEntriesAtLevel(1), isEmpty);
    expect(find.byType(SelectBadge), findsNothing);
  });
}
