import 'package:fl_select/fl_select.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Renders a [SelectChipBar] directly so we can assert how custom range
/// entries are handled: rendered as an input field instead of a chip.
Widget _harness(
  List<SelectEntry> entries, {
  SelectEntries? selectedEntries,
  void Function(int index, SelectEntry entry)? onChanged,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: SelectChipBar(
          category: SelectTextEntry<dynamic>(
              parentId: '', id: 'cate1', name: 'Cate 1'),
          entries: entries,
          selectedEntries: selectedEntries,
          onChanged: onChanged ?? (_, __) {},
        ),
      ),
    ),
  );
}

List<String?> fieldTexts(WidgetTester tester, Finder tile) => tester
    .widgetList<TextField>(
      find.descendant(of: tile, matching: find.byType(TextField)),
    )
    .map((t) => t.controller?.text)
    .toList();

void main() {
  testWidgets('header custom renders as a field tile above the chips',
      (tester) async {
    await tester.pumpWidget(_harness([
      SelectRangeEntry<int, dynamic>.custom(parentId: 'cate1'),
      SelectTextEntry<dynamic>(parentId: 'cate1', id: 'a', name: 'A'),
      SelectTextEntry<dynamic>(parentId: 'cate1', id: 'b', name: 'B'),
    ]));
    await tester.pumpAndSettle();

    expect(find.byType(SelectFieldTile), findsOneWidget);
    // Only the two regular entries render as chips.
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);

    // Vertical order: field tile -> chips.
    expect(
      tester.getTopLeft(find.byType(SelectFieldTile)).dy,
      lessThan(tester.getTopLeft(find.text('A')).dy),
    );
  });

  testWidgets('footer custom renders as a field tile below the chips',
      (tester) async {
    await tester.pumpWidget(_harness([
      SelectTextEntry<dynamic>(parentId: 'cate1', id: 'a', name: 'A'),
      SelectTextEntry<dynamic>(parentId: 'cate1', id: 'b', name: 'B'),
      SelectRangeEntry<int, dynamic>.custom(parentId: 'cate1'),
    ]));
    await tester.pumpAndSettle();

    expect(find.byType(SelectFieldTile), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('A')).dy,
      lessThan(tester.getTopLeft(find.byType(SelectFieldTile)).dy),
    );
  });

  testWidgets('committing the inputs on focus loss reports the custom entry',
      (tester) async {
    final custom = SelectRangeEntry<int, dynamic>.custom(parentId: 'cate1');
    final results = <(int, SelectEntry)>[];
    await tester.pumpWidget(_harness([
      SelectTextEntry<dynamic>(parentId: 'cate1', id: 'a', name: 'A'),
      custom,
    ], onChanged: (i, e) => results.add((i, e))));
    await tester.pumpAndSettle();

    await tester.enterText(
      find
          .descendant(
              of: find.byType(SelectFieldTile),
              matching: find.byType(TextField))
          .first,
      '100',
    );
    // Typing alone must not commit.
    expect(results, isEmpty);

    // Unfocusing both fields commits, with the custom entry's original index.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();

    expect(results, hasLength(1));
    expect(results.single.$1, 1);
    final committed = results.single.$2 as SelectRangeEntry;
    expect(committed, same(custom));
    expect(committed.min, 100);
    expect(committed.max, null);
  });

  testWidgets('an inverted range is normalized on commit', (tester) async {
    await tester.pumpWidget(_harness([
      SelectRangeEntry<int, dynamic>.custom(parentId: 'cate1'),
      SelectTextEntry<dynamic>(parentId: 'cate1', id: 'a', name: 'A'),
    ]));
    await tester.pumpAndSettle();

    final tile = find.byType(SelectFieldTile);
    await tester.enterText(
      find.descendant(of: tile, matching: find.byType(TextField)).first,
      '222',
    );
    await tester.enterText(
      find.descendant(of: tile, matching: find.byType(TextField)).at(1),
      '111',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();

    final texts = fieldTexts(tester, tile);
    expect(texts[0], '111');
    expect(texts[1], '222');
  });

  testWidgets('a committed custom selection restores the input texts',
      (tester) async {
    // A foreign category's custom entry must not leak into this bar's inputs.
    final foreign = SelectRangeEntry<int, dynamic>.custom(
      parentId: 'other',
      min: 999,
      max: 888,
    );
    final own = SelectRangeEntry<int, dynamic>.custom(
      parentId: 'cate1',
      min: 100,
      max: 200,
    );

    await tester.pumpWidget(_harness([
      own,
      SelectTextEntry<dynamic>(parentId: 'cate1', id: 'a', name: 'A'),
    ], selectedEntries: {
      foreign,
      own
    }));
    await tester.pumpAndSettle();

    final texts = fieldTexts(tester, find.byType(SelectFieldTile));
    // Restored from the bar's own custom entry (parentId == 'cate1').
    expect(texts[0], '100');
    expect(texts[1], '200');
  });

  testWidgets('tapping a chip clears the custom inputs and unfocuses them',
      (tester) async {
    final results = <(int, SelectEntry)>[];
    final a = SelectTextEntry<dynamic>(parentId: 'cate1', id: 'a', name: 'A');
    await tester.pumpWidget(_harness([
      SelectRangeEntry<int, dynamic>.custom(parentId: 'cate1'),
      a,
    ], onChanged: (i, e) => results.add((i, e))));
    await tester.pumpAndSettle();

    await tester.enterText(
      find
          .descendant(
              of: find.byType(SelectFieldTile),
              matching: find.byType(TextField))
          .first,
      '100',
    );
    await tester.tap(find.text('A'));
    await tester.pumpAndSettle();

    // The custom inputs were cleared.
    expect(
      fieldTexts(tester, find.byType(SelectFieldTile)).every((t) => t!.isEmpty),
      isTrue,
    );
    // The chip tap is reported with the chip's original index.
    expect(results.any((r) => r.$2 == a && r.$1 == 1), isTrue);
    // Focus changes are applied on the next frame, so the unfocus triggered by
    // the tap commits the (now cleared) custom value last — effectively
    // cancelling the custom selection.
    final last = results.last.$2;
    expect(last, isA<SelectRangeEntry>());
    expect((last as SelectRangeEntry).min, isNull);
    expect(last.max, isNull);
  });
}
