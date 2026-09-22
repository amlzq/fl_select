import 'package:fl_select/fl_select.dart';
import 'package:fl_select/src/select/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Renders a [SelectChipBar] directly so we can assert how it handles the
/// entries it is given.
///
/// The bar is a single horizontally scrolling row of chips and has no room for
/// an input field, so a custom range entry is rejected with a [FlutterError]
/// instead of being rendered (for a min/max field see `SelectWrapView`,
/// `SelectGridView` / `SelectListView` or a category's `SelectRangeLayout`).
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
            parentId: '',
            id: 'cate1',
            name: 'Cate 1',
          ),
          entries: entries,
          selectedEntries: selectedEntries,
          onChanged: onChanged ?? (_, _) {},
        ),
      ),
    ),
  );
}

/// Asserts that rendering a bar holding [entries] fails with the
/// custom-range-entry error pointing at the views that do support it.
Future<void> _expectCustomEntryError(
  WidgetTester tester,
  List<SelectEntry> entries,
) async {
  await tester.pumpWidget(_harness(entries));

  final error = tester.takeException();
  expect(error, isA<FlutterError>());
  expect(
    '$error',
    contains('SelectChipBar does not support custom range entries'),
  );
  // The offending entry is named, so the caller can find it.
  expect('$error', contains('custom'));
  // And the error points at the views that render the input field.
  expect('$error', contains('SelectWrapView'));
  // Nothing was rendered in its place, not even a min/max field.
  expect(find.byType(SelectFieldTile), findsNothing);
}

void main() {
  testWidgets('renders every entry as a chip', (tester) async {
    final results = <(int, SelectEntry)>[];
    await tester.pumpWidget(
      _harness([
        SelectTextEntry<dynamic>(parentId: 'cate1', id: 'a', name: 'A'),
        SelectTextEntry<dynamic>(parentId: 'cate1', id: 'b', name: 'B'),
      ], onChanged: (i, e) => results.add((i, e))),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);

    await tester.tap(find.text('B'));
    await tester.pumpAndSettle();

    expect(results.single.$1, 1);
  });

  testWidgets('a header custom range entry throws', (tester) async {
    await _expectCustomEntryError(tester, [
      SelectRangeEntry<int, dynamic>.custom(parentId: 'cate1'),
      SelectTextEntry<dynamic>(parentId: 'cate1', id: 'a', name: 'A'),
    ]);
  });

  testWidgets('a footer custom range entry throws', (tester) async {
    await _expectCustomEntryError(tester, [
      SelectTextEntry<dynamic>(parentId: 'cate1', id: 'a', name: 'A'),
      SelectTextEntry<dynamic>(parentId: 'cate1', id: 'b', name: 'B'),
      SelectRangeEntry<int, dynamic>.custom(parentId: 'cate1'),
    ]);
  });
}
