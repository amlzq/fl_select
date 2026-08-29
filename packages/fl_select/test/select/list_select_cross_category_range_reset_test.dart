import 'package:fl_select/fl_select.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression test for cross-category clearing with single-valued layouts.
///
/// When `delegate.selectionMode` is single, committing a custom range in a
/// [SelectRangeLayout] category and then selecting a leaf in another category
/// must deselect the custom entry and reset the range view (slider back to
/// the full bounds, input fields cleared). This exercises the snapshot
/// semantics of the per-level selected-entries set handed to leaf views: the
/// old/new `didUpdateWidget` diff must observe the deselection transition
/// instead of aliasing one live mutated set.
Widget _harness(List<SelectEntries> changes) {
  return MaterialApp(
    home: Scaffold(
      body: SelectView(
        delegate: ListSelectDelegate(
          entries: {
            SelectCategoryEntry.children(
              id: 'cate2',
              name: 'Cate 2',
              children: {
                SelectTextEntry.name(id: 'a', name: 'Tiger'),
                SelectTextEntry.name(id: 'b', name: 'Lion'),
              },
              selectionMode: SelectionMode.multiple,
              layout: const SelectWrapLayout(),
            ),
            SelectCategoryEntry.children(
              id: 'cate5',
              name: 'Cate 5',
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
              layout: const SelectRangeLayout(),
            ),
            SelectCategoryEntry.children(
              id: 'cate6',
              name: 'Cate 6',
              children: {
                SelectTextEntry.name(id: 'a', name: '1'),
                SelectTextEntry.name(id: 'b', name: '2'),
              },
              layout: const SelectCounterLayout(),
            ),
          },
        ),
        onChanged: changes.add,
      ),
    ),
  );
}

void main() {
  testWidgets(
      'selecting in another category resets a committed custom range '
      '(delegate single mode)', (tester) async {
    final changes = <SelectEntries>[];
    await tester.pumpWidget(_harness(changes));
    await tester.pumpAndSettle();

    // Only cate5 renders a field tile / range slider.
    final fieldTile = find.byType(SelectFieldTile);
    expect(fieldTile, findsOneWidget);
    expect(find.byType(SelectRangeSlider), findsOneWidget);

    // Commit a custom range in cate5: type 500000 / 1000000 and unfocus.
    await tester.enterText(
      find.descendant(of: fieldTile, matching: find.byType(TextField)).first,
      '500000',
    );
    await tester.enterText(
      find.descendant(of: fieldTile, matching: find.byType(TextField)).at(1),
      '1000000',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();

    // The custom entry is now selected and the slider reflects the commit.
    final slider =
        tester.widget<SelectRangeSlider>(find.byType(SelectRangeSlider));
    expect(slider.values, const RangeValues(500000, 1000000));

    // Tap a chip in cate2 (a multiple category) — cross-category clearing.
    await tester.tap(find.text('Tiger'));
    await tester.pumpAndSettle();

    // The custom range is deselected: the slider is back to the full bounds
    // and the input fields are cleared.
    final sliderAfter =
        tester.widget<SelectRangeSlider>(find.byType(SelectRangeSlider));
    expect(sliderAfter.values, const RangeValues(0, 2000000));
    final fields = tester
        .widgetList<TextField>(
          find.descendant(of: fieldTile, matching: find.byType(TextField)),
        )
        .map((t) => t.controller?.text)
        .toList();
    expect(fields[0], isEmpty);
    expect(fields[1], isEmpty);

    // The emitted selection no longer carries cate5's custom entry.
    final last = changes.last;
    final emittedCustom = last
        .whereType<SelectRangeEntry>()
        .where((e) => e.isCustom && e.min != null);
    expect(emittedCustom, isEmpty);
  });
}
