import 'package:fl_select/fl_select.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A marker item widget returned by the [SelectItemBuilder] under test.
///
/// Renders `label` wrapped in brackets when [selected] so tests can assert
/// both the content and the selection state through [find.text].
class _CustomItem extends StatelessWidget {
  const _CustomItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Text(selected ? '[$label]' : label),
    );
  }
}

/// Builds a [_CustomItem] whose label is `name@displayIndex`.
SelectItemBuilder get _itemBuilder =>
    (context, index, entry, {required bool selected, required onTap}) =>
        _CustomItem(
          label: '${entry.name}@$index',
          selected: selected,
          onTap: onTap,
        );

/// Flat entries: three regular items plus a trailing custom range entry.
///
/// The set literal is a [LinkedHashSet], so the insertion order (and thus the
/// display indexes) is stable: All=0, A=1, B=2. The custom range entry is
/// excluded from the builder's display indexes. The first item deliberately
/// avoids the id `any`: entries with that id are auto-selected when the
/// selection starts empty, which would make the initial `selected` assertions
/// non-deterministic.
Set<SelectEntry> _flatEntries() => {
      SelectTextEntry<dynamic>.name(id: 'all', name: 'All'),
      SelectTextEntry<dynamic>.name(id: 'a', name: 'A'),
      SelectTextEntry<dynamic>.name(id: 'b', name: 'B'),
      SelectRangeEntry.custom(name: 'Custom'),
    };

Widget _harness(
  SelectDelegate delegate, {
  void Function(Set<SelectEntry>)? onChanged,
}) {
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
  group('ListSelectDelegate.itemBuilder', () {
    testWidgets('replaces the default list tiles', (tester) async {
      await tester.pumpWidget(_harness(ListSelectDelegate(
        itemBuilder: _itemBuilder,
        entriesLoader: () async => _flatEntries(),
      )));
      await tester.pumpAndSettle();

      expect(find.byType(_CustomItem), findsNWidgets(3));
      expect(find.text('All@0'), findsOneWidget);
      expect(find.text('A@1'), findsOneWidget);
      expect(find.text('B@2'), findsOneWidget);
      expect(find.byType(SelectRadioListTile), findsNothing);
    });

    testWidgets('taps flow through the normal selection flow (single)',
        (tester) async {
      final applied = <Set<SelectEntry>>[];
      await tester.pumpWidget(_harness(
        ListSelectDelegate(
          itemBuilder: _itemBuilder,
          entriesLoader: () async => _flatEntries(),
        ),
        onChanged: applied.add,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('A@1'));
      await tester.pumpAndSettle();

      expect(applied.last.map((e) => e.id), contains('a'));
      // The `selected` flag updates after the tap.
      expect(find.text('[A@1]'), findsOneWidget);
    });

    testWidgets('selections accumulate until applied (multiple)',
        (tester) async {
      final applied = <Set<SelectEntry>>[];
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          // SelectView hides the action bar for inline usage; SelectPanel
          // keeps it so the multi-selection can be applied.
          body: SelectPanel(
            delegate: ListSelectDelegate(
              selectionMode: SelectionMode.multiple,
              applyText: 'Apply',
              itemBuilder: _itemBuilder,
              entriesLoader: () async => _flatEntries(),
            ),
            onApplyTap: applied.add,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('A@1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('B@2'));
      await tester.pumpAndSettle();

      // Pending selections are visible through `selected` before applying.
      expect(find.text('[A@1]'), findsOneWidget);
      expect(find.text('[B@2]'), findsOneWidget);

      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(applied.last.map((e) => e.id), containsAll(['a', 'b']));
    });

    testWidgets('custom range entry still renders as the built-in input field',
        (tester) async {
      await tester.pumpWidget(_harness(ListSelectDelegate(
        itemBuilder: _itemBuilder,
        entriesLoader: () async => _flatEntries(),
      )));
      await tester.pumpAndSettle();

      // The custom entry renders as an input field, never through the builder.
      expect(find.byType(SelectFieldTile), findsOneWidget);
      expect(find.byType(_CustomItem), findsNWidgets(3));
      expect(find.text('Custom@3'), findsNothing);
    });

    testWidgets('index follows the search-filtered display list',
        (tester) async {
      await tester.pumpWidget(_harness(ListSelectDelegate(
        searchEnabled: true,
        searchHintText: 'Search',
        itemBuilder: _itemBuilder,
        entriesLoader: () async => _flatEntries(),
      )));
      await tester.pumpAndSettle();

      // The custom range min/max fields are TextFields too; target the search
      // field through its hint text.
      await tester
          .enterText(find.widgetWithText(TextField, 'Search'), 'B');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.byType(_CustomItem), findsOneWidget);
      expect(find.text('B@0'), findsOneWidget);
    });

    testWidgets('default tiles render when itemBuilder is omitted',
        (tester) async {
      await tester.pumpWidget(_harness(ListSelectDelegate(
        entriesLoader: () async => _flatEntries(),
      )));
      await tester.pumpAndSettle();

      expect(find.byType(_CustomItem), findsNothing);
      expect(find.byType(SelectRadioListTile), findsNWidgets(3));
    });
  });

  group('GridSelectDelegate.itemBuilder', () {
    testWidgets('replaces the default grid tiles', (tester) async {
      await tester.pumpWidget(_harness(GridSelectDelegate(
        crossAxisCount: 3,
        itemBuilder: _itemBuilder,
        entriesLoader: () async => _flatEntries(),
      )));
      await tester.pumpAndSettle();

      expect(find.byType(_CustomItem), findsNWidgets(3));
      expect(find.text('All@0'), findsOneWidget);
      expect(find.text('A@1'), findsOneWidget);
      expect(find.text('B@2'), findsOneWidget);
      expect(find.byType(SelectGridTile), findsNothing);
    });

    testWidgets('taps flow through the normal selection flow (single)',
        (tester) async {
      final applied = <Set<SelectEntry>>[];
      await tester.pumpWidget(_harness(
        GridSelectDelegate(
          crossAxisCount: 3,
          itemBuilder: _itemBuilder,
          entriesLoader: () async => _flatEntries(),
        ),
        onChanged: applied.add,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('A@1'));
      await tester.pumpAndSettle();

      expect(applied.last.map((e) => e.id), contains('a'));
      expect(find.text('[A@1]'), findsOneWidget);
    });

    testWidgets('custom range entry still renders as the built-in input field',
        (tester) async {
      await tester.pumpWidget(_harness(GridSelectDelegate(
        crossAxisCount: 3,
        itemBuilder: _itemBuilder,
        entriesLoader: () async => _flatEntries(),
      )));
      await tester.pumpAndSettle();

      expect(find.byType(SelectFieldTile), findsOneWidget);
      expect(find.byType(_CustomItem), findsNWidgets(3));
      expect(find.text('Custom@3'), findsNothing);
    });

    testWidgets('default tiles render when itemBuilder is omitted',
        (tester) async {
      await tester.pumpWidget(_harness(GridSelectDelegate(
        crossAxisCount: 3,
        entriesLoader: () async => _flatEntries(),
      )));
      await tester.pumpAndSettle();

      expect(find.byType(_CustomItem), findsNothing);
      expect(find.byType(SelectGridTile), findsNWidgets(3));
    });
  });

  group('WrapSelectDelegate.itemBuilder', () {
    testWidgets('replaces the default chips', (tester) async {
      await tester.pumpWidget(_harness(WrapSelectDelegate(
        itemBuilder: _itemBuilder,
        entriesLoader: () async => _flatEntries(),
      )));
      await tester.pumpAndSettle();

      expect(find.byType(_CustomItem), findsNWidgets(3));
      expect(find.text('All@0'), findsOneWidget);
      expect(find.text('A@1'), findsOneWidget);
      expect(find.text('B@2'), findsOneWidget);
      // The default chip label (plain name) is gone.
      expect(find.text('A'), findsNothing);
    });

    testWidgets('taps flow through the normal selection flow (single)',
        (tester) async {
      final applied = <Set<SelectEntry>>[];
      await tester.pumpWidget(_harness(
        WrapSelectDelegate(
          itemBuilder: _itemBuilder,
          entriesLoader: () async => _flatEntries(),
        ),
        onChanged: applied.add,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('A@1'));
      await tester.pumpAndSettle();

      expect(applied.last.map((e) => e.id), contains('a'));
      expect(find.text('[A@1]'), findsOneWidget);
    });

    testWidgets('custom range entry still renders as the built-in input field',
        (tester) async {
      await tester.pumpWidget(_harness(WrapSelectDelegate(
        itemBuilder: _itemBuilder,
        entriesLoader: () async => _flatEntries(),
      )));
      await tester.pumpAndSettle();

      expect(find.byType(SelectFieldTile), findsOneWidget);
      expect(find.byType(_CustomItem), findsNWidgets(3));
      expect(find.text('Custom@3'), findsNothing);
    });

    testWidgets('default chips render when itemBuilder is omitted',
        (tester) async {
      await tester.pumpWidget(_harness(WrapSelectDelegate(
        entriesLoader: () async => _flatEntries(),
      )));
      await tester.pumpAndSettle();

      expect(find.byType(_CustomItem), findsNothing);
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
    });
  });
}
