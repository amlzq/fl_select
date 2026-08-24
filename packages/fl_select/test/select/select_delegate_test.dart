import 'package:fl_select/fl_select.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

void main() {
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
              children: {
                _text('a', 'a_leaf', 'BranchALeaf'),
              },
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
                  builder: (context) => selector.buildBody(
                    context,
                    [category],
                    previousSelected,
                  ),
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

    testWidgets('reveals restored target item when it is initially offscreen',
        (tester) async {
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
              children: {
                _text('parent', 'target_leaf', 'TargetLeaf'),
              },
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
                  builder: (context) => selector.buildBody(
                    context,
                    [category],
                    previousSelected,
                  ),
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
        SelectTextEntry<dynamic>.name(id: 'a', name: 'A'),
      };
      final delegate = ListSelectDelegate(entries: entries);

      expect(delegate.hasSyncEntries, isTrue);
      expect(delegate.entries, same(entries));
    });

    test('asyncEntries wraps sync entries in a future', () async {
      final entries = <SelectEntry<dynamic>>{
        SelectTextEntry<dynamic>.name(id: 'a', name: 'A'),
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

    test('selectedEntries and selectedEntriesLoader are mutually exclusive',
        () {
      expect(
        () => ListSelectDelegate(
          entries: const <SelectEntry<dynamic>>{},
          selectedEntries: const <SelectEntry<dynamic>>{},
          selectedEntriesLoader: () => const <SelectEntry<dynamic>>{},
        ),
        throwsA(isA<AssertionError>()),
      );
    });

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
        SelectTextEntry<dynamic>.name(id: 'a', name: 'A'),
      };
      final delegate = ListSelectDelegate(
        entries: const <SelectEntry<dynamic>>{},
        selectedEntries: selected,
      );

      expect(delegate.selectedEntries, same(selected));
    });

    test('resetEntries supplied via the constructor is returned as-is', () {
      final reset = <SelectEntry<dynamic>>{
        SelectTextEntry<dynamic>.name(id: 'a', name: 'A'),
      };
      final delegate = ListSelectDelegate(
        entries: const <SelectEntry<dynamic>>{},
        resetEntries: reset,
      );

      expect(delegate.resetEntries, same(reset));
    });

    testWidgets('sync entries render on the first frame without a skeleton',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectView(
              delegate: ListSelectDelegate(
                entries: <SelectEntry<dynamic>>{
                  SelectTextEntry<dynamic>.name(id: 'a', name: 'A'),
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
}
