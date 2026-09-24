import 'package:fl_select/fl_select.dart';
import 'package:fl_select/src/select/select_panel.dart';
import 'package:fl_select/src/select/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Direct coverage for the delegates introduced by the split:
/// [WrapSelectDelegate], [TabNavSelectDelegate], [SideNavSelectDelegate]
/// and [ExpandableSelectDelegate]. Every delegate accepts exactly one data
/// shape and asserts on the other.
Set<SelectEntry> get _flatEntries => {
  SelectTextEntry<dynamic>(id: 'a', name: 'A'),
  SelectTextEntry<dynamic>(id: 'b', name: 'B'),
};

Set<SelectEntry> get _categoryEntries => {
  SelectCategoryEntry<dynamic>(
    id: 'cate1',
    name: 'Cate 1',
    children: {
      SelectTextEntry<dynamic>(id: 'a1', name: 'A 1'),
      SelectTextEntry<dynamic>(id: 'a2', name: 'A 2'),
    },
  ),
  SelectCategoryEntry<dynamic>(
    id: 'cate2',
    name: 'Cate 2',
    children: {SelectTextEntry<dynamic>(id: 'b1', name: 'B 1')},
  ),
};

Widget _harness(
  SelectDelegate delegate, {
  void Function(Set<SelectEntry>)? onChanged,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SelectView(delegate: delegate, onChanged: onChanged ?? (_) {}),
    ),
  );
}

SelectTextEntry<dynamic> _text(
  String parentId,
  String id,
  String name, {
  Set<SelectEntry<dynamic>>? children,
}) {
  return SelectTextEntry<dynamic>(
    parentId: parentId,
    id: id,
    name: name,
    children: children,
  );
}

SelectCategoryEntry<dynamic> _category(
  String id,
  String name, {
  required Set<SelectEntry<dynamic>> children,
  SelectionMode selectionMode = SelectionMode.single,
}) {
  return SelectCategoryEntry<dynamic>(
    id: id,
    name: name,
    children: children,
    selectionMode: selectionMode,
  );
}

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
    return InkWell(onTap: onTap, child: Text(selected ? '[$label]' : label));
  }
}

/// Builds a [_CustomItem] showing the entry's name.
SelectItemBuilder get _itemBuilder =>
    (context, entry, {required bool selected, required onTap, categoryId}) =>
        _CustomItem(label: entry.name ?? '', selected: selected, onTap: onTap);

/// Builds a [_CustomItem] whose label carries the owning category id, so
/// tests can assert the `categoryId` passed to the builder.
SelectItemBuilder get _categoryIdItemBuilder =>
    (context, entry, {required bool selected, required onTap, categoryId}) =>
        _CustomItem(
          label: '${entry.name ?? ''}@${categoryId ?? 'null'}',
          selected: selected,
          onTap: onTap,
        );

/// Returns null for entries owned by category `catA` so they fall back to
/// the default item widget; every other category renders a [_CustomItem].
SelectItemBuilder get _partialItemBuilder =>
    (context, entry, {required bool selected, required onTap, categoryId}) =>
        categoryId == 'catA'
        ? null
        : _CustomItem(
            label: entry.name ?? '',
            selected: selected,
            onTap: onTap,
          );

/// Flat entries: three regular items plus a trailing custom range entry.
///
/// The first item deliberately avoids the id `any`: entries with that id are
/// auto-selected when the selection starts empty, which would make the
/// initial `selected` assertions non-deterministic.
Set<SelectEntry> _ibFlatEntries() => {
  SelectTextEntry<dynamic>(id: 'all', name: 'All'),
  SelectTextEntry<dynamic>(id: 'a', name: 'A'),
  SelectTextEntry<dynamic>(id: 'b', name: 'B'),
  SelectRangeEntry.custom(name: 'Custom'),
};

/// Two-level entries: two list-layout categories, so category-based
/// delegates have two switchable groups of children.
Set<SelectEntry> _ibCategoryEntries() => {
  SelectCategoryEntry<dynamic>(
    id: 'catA',
    name: 'Tab A',
    layout: const SelectListLayout(),
    children: {
      SelectTextEntry<dynamic>(id: 'a', name: 'A'),
      SelectTextEntry<dynamic>(id: 'b', name: 'B'),
      SelectTextEntry<dynamic>(id: 'c', name: 'C'),
    },
  ),
  SelectCategoryEntry<dynamic>(
    id: 'catB',
    name: 'Tab B',
    layout: const SelectListLayout(),
    children: {
      SelectTextEntry<dynamic>(id: 'd', name: 'D'),
      SelectTextEntry<dynamic>(id: 'e', name: 'E'),
      SelectTextEntry<dynamic>(id: 'f', name: 'F'),
    },
  ),
};

/// Two-level entries whose categories render as wrapped chips, exercising
/// the chip-host path of the item builder.
Set<SelectEntry> _wrapCategoryEntries() => {
  SelectCategoryEntry<dynamic>(
    id: 'catA',
    name: 'Group A',
    layout: const SelectWrapLayout(),
    children: {
      SelectTextEntry<dynamic>(id: 'a', name: 'A'),
      SelectTextEntry<dynamic>(id: 'b', name: 'B'),
      SelectTextEntry<dynamic>(id: 'c', name: 'C'),
    },
  ),
};

Widget _ibHarness(
  SelectDelegate delegate, {
  void Function(Set<SelectEntry>)? onChanged,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SelectView(delegate: delegate, onChanged: onChanged ?? (_) {}),
    ),
  );
}

void main() {
  group('TabNavSelectDelegate', () {
    testWidgets('renders category tabs and applies a selection', (
      tester,
    ) async {
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

      expect(find.byType(SelectWrapView), findsOneWidget);
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
    testWidgets('renders one expandable tile per category and applies a '
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

  group('GridSelectDelegate', () {
    test('asserts on category data', () {
      expect(
        () => GridSelectDelegate(crossAxisCount: 3, entries: _categoryEntries),
        throwsAssertionError,
      );
    });
  });

  group('ListSelectDelegate', () {
    test('asserts on category data', () {
      expect(
        () => ListSelectDelegate(entries: _categoryEntries),
        throwsAssertionError,
      );
    });
  });

  group('CascadingSelect', () {
    testWidgets('restores a connected deepest focused path', (tester) async {
      final branchALeaf = _text('a', 'a_leaf', 'BranchALeaf');
      final branchA = _text('c', 'a', 'BranchA', children: {branchALeaf});
      final branchBLeaf = _text('b', 'b_leaf', 'BranchBLeaf');
      final branchB = _text('c', 'b', 'BranchB', children: {branchBLeaf});
      final category = _category(
        'c',
        'Category',
        children: {branchA, branchB},
        selectionMode: SelectionMode.multiple,
      );

      final previousSelected = <SelectEntry<dynamic>>{
        _category(
          'c',
          'Category',
          children: {
            _text(
              'c',
              'a',
              'BranchA',
              children: {_text('a', 'a_leaf', 'BranchALeaf')},
            ),
            _text('c', 'b', 'BranchB'),
          },
          selectionMode: SelectionMode.multiple,
        ),
      };

      final selector = CascadingSelectDelegate(
        selectionMode: SelectionMode.multiple,
        entriesLoader: () async => <SelectEntry<dynamic>>{},
      );
      final controller = SelectController(
        selectionMode: SelectionMode.multiple,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectTheme(
              data: SelectThemeData.fallback(ThemeData()),
              child: SelectControllerProvider(
                controller: controller,
                child: Builder(
                  builder: (context) =>
                      selector.buildBody(context, [category], previousSelected),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('BranchA'), findsOneWidget);
      expect(find.text('BranchB'), findsOneWidget);
      expect(find.text('BranchALeaf'), findsOneWidget);
      expect(find.text('BranchBLeaf'), findsNothing);
    });

    testWidgets('reveals restored target item when it is initially offscreen', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 320));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final targetLeaf = _text('parent', 'target_leaf', 'TargetLeaf');
      final leaves = <SelectEntry<dynamic>>{
        for (int i = 0; i < 16; i++) _text('parent', 'leaf_$i', 'Leaf $i'),
        targetLeaf,
      };
      final parent = _text('c', 'parent', 'Parent', children: leaves);
      final category = _category(
        'c',
        'Category',
        children: {parent},
        selectionMode: SelectionMode.multiple,
      );

      final previousSelected = <SelectEntry<dynamic>>{
        _category(
          'c',
          'Category',
          children: {
            _text(
              'c',
              'parent',
              'Parent',
              children: {_text('parent', 'target_leaf', 'TargetLeaf')},
            ),
          },
          selectionMode: SelectionMode.multiple,
        ),
      };

      final selector = CascadingSelectDelegate(
        selectionMode: SelectionMode.multiple,
        entriesLoader: () async => <SelectEntry<dynamic>>{},
      );
      final controller = SelectController(
        selectionMode: SelectionMode.multiple,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectTheme(
              data: SelectThemeData.fallback(ThemeData()),
              child: SelectControllerProvider(
                controller: controller,
                child: Builder(
                  builder: (context) =>
                      selector.buildBody(context, [category], previousSelected),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Parent'), findsOneWidget);
      expect(find.text('TargetLeaf'), findsOneWidget);
      expect(find.text('Leaf 0'), findsNothing);
    });
  });

  group('sync data', () {
    test('entries can be supplied without a loader', () {
      final entries = <SelectEntry<dynamic>>{
        SelectTextEntry<dynamic>(id: 'a', name: 'A'),
      };
      final delegate = ListSelectDelegate(entries: entries);

      expect(delegate.hasSyncEntries, isTrue);
      expect(delegate.entries, same(entries));
    });

    test('asyncEntries wraps sync entries in a future', () async {
      final entries = <SelectEntry<dynamic>>{
        SelectTextEntry<dynamic>(id: 'a', name: 'A'),
      };
      final delegate = ListSelectDelegate(entries: entries);

      expect(await delegate.asyncEntries, same(entries));
    });

    test('entries and entriesLoader are mutually exclusive', () {
      expect(
        () => ListSelectDelegate(
          entries: const <SelectEntry<dynamic>>{},
          entriesLoader: () async => <SelectEntry<dynamic>>{},
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test(
      'selectedEntries and selectedEntriesLoader are mutually exclusive',
      () {
        expect(
          () => ListSelectDelegate(
            entries: const <SelectEntry<dynamic>>{},
            selectedEntries: const <SelectEntry<dynamic>>{},
            selectedEntriesLoader: () => const <SelectEntry<dynamic>>{},
          ),
          throwsA(isA<AssertionError>()),
        );
      },
    );

    test('resetEntries and resetEntriesLoader are mutually exclusive', () {
      expect(
        () => ListSelectDelegate(
          entries: const <SelectEntry<dynamic>>{},
          resetEntries: const <SelectEntry<dynamic>>{},
          resetEntriesLoader: () => const <SelectEntry<dynamic>>{},
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('selectedEntries supplied via the constructor is returned as-is', () {
      final selected = <SelectEntry<dynamic>>{
        SelectTextEntry<dynamic>(id: 'a', name: 'A'),
      };
      final delegate = ListSelectDelegate(
        entries: const <SelectEntry<dynamic>>{},
        selectedEntries: selected,
      );

      expect(delegate.selectedEntries, same(selected));
    });

    test('resetEntries supplied via the constructor is returned as-is', () {
      final reset = <SelectEntry<dynamic>>{
        SelectTextEntry<dynamic>(id: 'a', name: 'A'),
      };
      final delegate = ListSelectDelegate(
        entries: const <SelectEntry<dynamic>>{},
        resetEntries: reset,
      );

      expect(delegate.resetEntries, same(reset));
    });

    testWidgets('sync entries render on the first frame without a skeleton', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectView(
              delegate: ListSelectDelegate(
                entries: <SelectEntry<dynamic>>{
                  SelectTextEntry<dynamic>(id: 'a', name: 'A'),
                },
              ),
              onChanged: (_) {},
            ),
          ),
        ),
      );
      // No pumpAndSettle: sync entries must be visible on the very first
      // frame, proving the skeleton pass is skipped entirely.
      expect(find.text('A'), findsOneWidget);
    });
  });

  group('nav scrollability defaults', () {
    test('TabNavSelectDelegate.isScrollable defaults to false', () {
      final delegate = TabNavSelectDelegate(
        entriesLoader: () async => <SelectEntry<dynamic>>{},
      );
      expect(delegate.isScrollable, isFalse);
    });

    test('SideNavSelectDelegate.isScrollable defaults to true', () {
      final delegate = SideNavSelectDelegate(
        entriesLoader: () async => <SelectEntry<dynamic>>{},
      );
      expect(delegate.isScrollable, isTrue);
    });
  });
  group('ListSelectDelegate.itemBuilder', () {
    testWidgets('replaces the default list tiles', (tester) async {
      await tester.pumpWidget(
        _ibHarness(
          ListSelectDelegate(
            itemBuilder: _itemBuilder,
            entriesLoader: () async => _ibFlatEntries(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(_CustomItem), findsNWidgets(3));
      expect(find.text('All'), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(find.byType(SelectRadioListTile), findsNothing);
    });

    testWidgets('taps flow through the normal selection flow (single)', (
      tester,
    ) async {
      final applied = <Set<SelectEntry>>[];
      await tester.pumpWidget(
        _ibHarness(
          ListSelectDelegate(
            itemBuilder: _itemBuilder,
            entriesLoader: () async => _ibFlatEntries(),
          ),
          onChanged: applied.add,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('A'));
      await tester.pumpAndSettle();

      expect(applied.last.map((e) => e.id), contains('a'));
      // The `selected` flag updates after the tap.
      expect(find.text('[A]'), findsOneWidget);
    });

    testWidgets('selections accumulate until applied (multiple)', (
      tester,
    ) async {
      final applied = <Set<SelectEntry>>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            // SelectView hides the action bar for inline usage; SelectPanel
            // keeps it so the multi-selection can be applied.
            body: SelectPanel(
              delegate: ListSelectDelegate(
                selectionMode: SelectionMode.multiple,
                applyText: 'Apply',
                itemBuilder: _itemBuilder,
                entriesLoader: () async => _ibFlatEntries(),
              ),
              onApplyTap: applied.add,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('A'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('B'));
      await tester.pumpAndSettle();

      // Pending selections are visible through `selected` before applying.
      expect(find.text('[A]'), findsOneWidget);
      expect(find.text('[B]'), findsOneWidget);

      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(applied.last.map((e) => e.id), containsAll(['a', 'b']));
    });

    testWidgets(
      'custom range entry still renders as the built-in input field',
      (tester) async {
        await tester.pumpWidget(
          _ibHarness(
            ListSelectDelegate(
              itemBuilder: _itemBuilder,
              entriesLoader: () async => _ibFlatEntries(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // The custom entry renders as an input field, never through the
        // builder, so only the three regular items build [_CustomItem]s.
        expect(find.byType(SelectFieldTile), findsOneWidget);
        expect(find.byType(_CustomItem), findsNWidgets(3));
      },
    );

    testWidgets('search-filtered entries still pass through the builder', (
      tester,
    ) async {
      await tester.pumpWidget(
        _ibHarness(
          ListSelectDelegate(
            searchEnabled: true,
            searchHintText: 'Search',
            itemBuilder: _itemBuilder,
            entriesLoader: () async => _ibFlatEntries(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The custom range min/max fields are TextFields too; target the search
      // field through its hint text.
      await tester.enterText(find.widgetWithText(TextField, 'Search'), 'B');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.byType(_CustomItem), findsOneWidget);
      // Match within the custom item: the search field's EditableText holds
      // the typed 'B' as well.
      expect(find.widgetWithText(_CustomItem, 'B'), findsOneWidget);
    });

    testWidgets('default tiles render when itemBuilder is omitted', (
      tester,
    ) async {
      await tester.pumpWidget(
        _ibHarness(
          ListSelectDelegate(entriesLoader: () async => _ibFlatEntries()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(_CustomItem), findsNothing);
      expect(find.byType(SelectRadioListTile), findsNWidgets(3));
    });
  });

  group('GridSelectDelegate.itemBuilder', () {
    testWidgets('replaces the default grid tiles', (tester) async {
      await tester.pumpWidget(
        _ibHarness(
          GridSelectDelegate(
            crossAxisCount: 3,
            itemBuilder: _itemBuilder,
            entriesLoader: () async => _ibFlatEntries(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(_CustomItem), findsNWidgets(3));
      expect(find.text('All'), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(find.byType(SelectGridTile), findsNothing);
    });

    testWidgets('taps flow through the normal selection flow (single)', (
      tester,
    ) async {
      final applied = <Set<SelectEntry>>[];
      await tester.pumpWidget(
        _ibHarness(
          GridSelectDelegate(
            crossAxisCount: 3,
            itemBuilder: _itemBuilder,
            entriesLoader: () async => _ibFlatEntries(),
          ),
          onChanged: applied.add,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('A'));
      await tester.pumpAndSettle();

      expect(applied.last.map((e) => e.id), contains('a'));
      expect(find.text('[A]'), findsOneWidget);
    });

    testWidgets(
      'custom range entry still renders as the built-in input field',
      (tester) async {
        await tester.pumpWidget(
          _ibHarness(
            GridSelectDelegate(
              crossAxisCount: 3,
              itemBuilder: _itemBuilder,
              entriesLoader: () async => _ibFlatEntries(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // The custom entry renders as an input field, never through the
        // builder, so only the three regular items build [_CustomItem]s.
        expect(find.byType(SelectFieldTile), findsOneWidget);
        expect(find.byType(_CustomItem), findsNWidgets(3));
      },
    );

    testWidgets('default tiles render when itemBuilder is omitted', (
      tester,
    ) async {
      await tester.pumpWidget(
        _ibHarness(
          GridSelectDelegate(
            crossAxisCount: 3,
            entriesLoader: () async => _ibFlatEntries(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(_CustomItem), findsNothing);
      expect(find.byType(SelectGridTile), findsNWidgets(3));
    });
  });

  group('WrapSelectDelegate.itemBuilder', () {
    testWidgets('replaces the default chips', (tester) async {
      await tester.pumpWidget(
        _ibHarness(
          WrapSelectDelegate(
            itemBuilder: _itemBuilder,
            entriesLoader: () async => _ibFlatEntries(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(_CustomItem), findsNWidgets(3));
      expect(find.text('All'), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
    });

    testWidgets('taps flow through the normal selection flow (single)', (
      tester,
    ) async {
      final applied = <Set<SelectEntry>>[];
      await tester.pumpWidget(
        _ibHarness(
          WrapSelectDelegate(
            itemBuilder: _itemBuilder,
            entriesLoader: () async => _ibFlatEntries(),
          ),
          onChanged: applied.add,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('A'));
      await tester.pumpAndSettle();

      expect(applied.last.map((e) => e.id), contains('a'));
      expect(find.text('[A]'), findsOneWidget);
    });

    testWidgets(
      'custom range entry still renders as the built-in input field',
      (tester) async {
        await tester.pumpWidget(
          _ibHarness(
            WrapSelectDelegate(
              itemBuilder: _itemBuilder,
              entriesLoader: () async => _ibFlatEntries(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // The custom entry renders as an input field, never through the
        // builder, so only the three regular items build [_CustomItem]s.
        expect(find.byType(SelectFieldTile), findsOneWidget);
        expect(find.byType(_CustomItem), findsNWidgets(3));
      },
    );

    testWidgets('default chips render when itemBuilder is omitted', (
      tester,
    ) async {
      await tester.pumpWidget(
        _ibHarness(
          WrapSelectDelegate(entriesLoader: () async => _ibFlatEntries()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(_CustomItem), findsNothing);
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
    });
  });

  group('TabNavSelectDelegate.itemBuilder', () {
    testWidgets('replaces the default tiles and receives categoryId', (
      tester,
    ) async {
      await tester.pumpWidget(
        _ibHarness(
          TabNavSelectDelegate(
            itemBuilder: _categoryIdItemBuilder,
            entriesLoader: () async => _ibCategoryEntries(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Only the focused category's children render through the builder,
      // with the owning category's id passed as categoryId.
      expect(find.byType(_CustomItem), findsNWidgets(3));
      expect(find.text('A@catA'), findsOneWidget);
      expect(find.text('B@catA'), findsOneWidget);
      expect(find.byType(SelectRadioListTile), findsNothing);
    });

    testWidgets('categoryId follows the focused tab', (tester) async {
      await tester.pumpWidget(
        _ibHarness(
          TabNavSelectDelegate(
            itemBuilder: _categoryIdItemBuilder,
            entriesLoader: () async => _ibCategoryEntries(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tab B'));
      await tester.pumpAndSettle();

      expect(find.byType(_CustomItem), findsNWidgets(3));
      expect(find.text('D@catB'), findsOneWidget);
      expect(find.text('A@catA'), findsNothing);
    });

    testWidgets('taps flow through the normal selection flow', (tester) async {
      final applied = <Set<SelectEntry>>[];
      await tester.pumpWidget(
        _ibHarness(
          TabNavSelectDelegate(
            itemBuilder: _categoryIdItemBuilder,
            entriesLoader: () async => _ibCategoryEntries(),
          ),
          onChanged: applied.add,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('B@catA'));
      await tester.pumpAndSettle();

      // Category delegates report the clipped selection tree, so the tapped
      // child is nested inside its category.
      final appliedCategory = applied.last.single as SelectCategoryEntry;
      expect(appliedCategory.id, 'catA');
      expect(appliedCategory.children!.map((e) => e.id), contains('b'));
      expect(find.text('[B@catA]'), findsOneWidget);
    });

    testWidgets('null falls back to the default tiles per category', (
      tester,
    ) async {
      await tester.pumpWidget(
        _ibHarness(
          TabNavSelectDelegate(
            itemBuilder: _partialItemBuilder,
            entriesLoader: () async => _ibCategoryEntries(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // catA's builder returns null -> default tiles.
      expect(find.byType(SelectRadioListTile), findsNWidgets(3));
      expect(find.byType(_CustomItem), findsNothing);

      await tester.tap(find.text('Tab B'));
      await tester.pumpAndSettle();

      // catB still renders custom items.
      expect(find.byType(_CustomItem), findsNWidgets(3));
      expect(find.byType(SelectRadioListTile), findsNothing);
    });
  });

  group('ExpandableSelectDelegate.itemBuilder', () {
    testWidgets('replaces the default chips and receives categoryId', (
      tester,
    ) async {
      await tester.pumpWidget(
        _ibHarness(
          ExpandableSelectDelegate(
            itemBuilder: _categoryIdItemBuilder,
            entriesLoader: () async => _wrapCategoryEntries(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Category tiles start expanded, so children render right away.
      expect(find.byType(_CustomItem), findsNWidgets(3));
      expect(find.text('A@catA'), findsOneWidget);
      expect(find.text('B@catA'), findsOneWidget);
    });

    testWidgets('taps flow through the normal selection flow', (tester) async {
      final applied = <Set<SelectEntry>>[];
      await tester.pumpWidget(
        _ibHarness(
          ExpandableSelectDelegate(
            itemBuilder: _categoryIdItemBuilder,
            entriesLoader: () async => _wrapCategoryEntries(),
          ),
          onChanged: applied.add,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('C@catA'));
      await tester.pumpAndSettle();

      final appliedCategory = applied.last.single as SelectCategoryEntry;
      expect(appliedCategory.id, 'catA');
      expect(appliedCategory.children!.map((e) => e.id), contains('c'));
      expect(find.text('[C@catA]'), findsOneWidget);
    });
  });
}
