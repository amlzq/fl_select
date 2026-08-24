import 'package:fl_select/fl_select.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds a [SelectView] backed by a [ListSelectDelegate] with several
/// categories, each owning its own custom range entry. All custom entries share
/// the id `custom` and the whole level-1 selection set is handed to every
/// category view, so this exercises the per-category scoping that prevents a
/// value committed in one category from leaking into another category's input.
Widget _harness() {
  return MaterialApp(
    home: Scaffold(
      body: SelectView(
        delegate: ListSelectDelegate(
          selectionMode: SelectionMode.single,
          entriesLoader: () async => {
            SelectCategoryEntry.children(
              id: 'cate1',
              name: 'Cate 1',
              children: {
                SelectRangeEntry.custom(),
                SelectTextEntry.name(id: 'a', name: 'A'),
              },
            ),
            SelectCategoryEntry.children(
              id: 'cate3',
              name: 'Cate 3',
              children: {
                SelectTextEntry.name(id: 'a', name: 'A'),
                SelectRangeEntry.custom(),
              },
            ),
            SelectCategoryEntry.children(
              id: 'cate4',
              name: 'Cate 4',
              children: {
                SelectRangeEntry(
                  id: 'a',
                  name: r'$0-$2000000',
                  min: 0,
                  max: 2000000,
                  divisions: 80,
                ),
                SelectRangeEntry.custom(),
              },
            ),
          },
        ),
        onChanged: (_) {},
      ),
    ),
  );
}

void main() {
  testWidgets('committing cate1 custom range does not pollute other categories',
      (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    // All three categories are rendered as expanded tiles in ListSelect.
    expect(find.text('Cate 1'), findsOneWidget);
    expect(find.text('Cate 3'), findsOneWidget);
    expect(find.text('Cate 4'), findsOneWidget);
    // Three custom input fields (one per category).
    expect(find.byType(SelectFieldTile), findsNWidgets(3));

    // cate1's custom is at the header, so its tile is the first
    // [SelectFieldTile]. Commit a value into cate1's fields.
    final cate1Tile = find.byType(SelectFieldTile).first;
    await tester.enterText(
      find.descendant(of: cate1Tile, matching: find.byType(TextField)).first,
      '100',
    );
    await tester.enterText(
      find.descendant(of: cate1Tile, matching: find.byType(TextField)).at(1),
      '200',
    );
    // Unfocus so _onFocusChanged commits.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();

    // cate1's own min value must be preserved after committing both fields
    // (typing min first then max must not clear the min field).
    final cate1Fields = tester
        .widgetList<TextField>(
          find.descendant(of: cate1Tile, matching: find.byType(TextField)),
        )
        .map((t) => t.controller?.text)
        .toList();
    expect(cate1Fields[0], '100');
    expect(cate1Fields[1], '200');

    // cate3 and cate4's fields (the other tiles) must NOT be polluted with
    // cate1's committed values.
    final otherFields = tester
        .widgetList<TextField>(find.byType(TextField))
        .map((t) => t.controller?.text)
        .toList();
    expect(otherFields[2], isEmpty);
    expect(otherFields[3], isEmpty);
    expect(otherFields[4], isEmpty);
    expect(otherFields[5], isEmpty);
  });

  testWidgets('typing max does not swap during editing; swap only on commit',
      (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    final cate1Tile = find.byType(SelectFieldTile).first;
    List<String?> cate1Fields() => tester
        .widgetList<TextField>(
          find.descendant(of: cate1Tile, matching: find.byType(TextField)),
        )
        .map((t) => t.controller?.text)
        .toList();

    // Type min = 222.
    await tester.enterText(
      find.descendant(of: cate1Tile, matching: find.byType(TextField)).first,
      '222',
    );
    await tester.pump();
    expect(cate1Fields()[0], '222');

    // Type a single digit into the max field. This must NOT immediately swap
    // the fields (previously it flipped min to '1' and max to '222').
    await tester.enterText(
      find.descendant(of: cate1Tile, matching: find.byType(TextField)).at(1),
      '1',
    );
    await tester.pump();
    expect(cate1Fields()[0], '222');
    expect(cate1Fields()[1], '1');

    // Finish typing max = 111.
    await tester.enterText(
      find.descendant(of: cate1Tile, matching: find.byType(TextField)).at(1),
      '111',
    );
    await tester.pump();
    expect(cate1Fields()[0], '222');
    expect(cate1Fields()[1], '111');

    // On commit (unfocus), the inverted range is normalized to min 111 / max 222.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    expect(cate1Fields()[0], '111');
    expect(cate1Fields()[1], '222');
  });
}
