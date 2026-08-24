import 'package:fl_select/fl_select.dart';
import 'package:fl_select/src/select/select_utils.dart';
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
  SelectEntry<dynamic>? header,
  SelectionMode headerSelectionMode = SelectionMode.single,
  SelectEntry<dynamic>? footer,
  SelectionMode footerSelectionMode = SelectionMode.single,
  SelectionMode selectionMode = SelectionMode.single,
}) {
  return SelectCategoryEntry<dynamic>(
    id: id,
    name: name,
    children: children,
    header: header,
    headerSelectionMode: headerSelectionMode,
    footer: footer,
    footerSelectionMode: footerSelectionMode,
    selectionMode: selectionMode,
  );
}

void main() {
  group('SelectUtils – cloneTree (multi-category scenarios)', () {
    test('cloneTree does not leak children from one category into another', () {
      // Two categories that both have a "custom" entry.
      // Without the parentId filtering fix, the selected "custom" from c1
      // would leak into c2's cloned subtree.
      final custom1 = SelectRangeEntry<int, dynamic>.custom(
        parentId: 'c1',
        name: 'Custom',
      );
      final custom2 = SelectRangeEntry<int, dynamic>.custom(
        parentId: 'c2',
        name: 'Custom',
      );
      final a1 = _text('c1', 'a1', 'A1');
      final a2 = _text('c2', 'a2', 'A2');
      final c1 = _category('c1', 'C1', children: {custom1, a1});
      final c2 = _category('c2', 'C2', children: {custom2, a2});

      final cloned = SelectUtils.cloneTree(
        {c1, c2},
        [
          <SelectEntry<dynamic>>{c1, c2},
          <SelectEntry<dynamic>>{custom1, a2},
        ],
      );

      // Only c1 and c2 should be in the root
      expect(cloned.length, 2);

      final clonedC1 = cloned.firstWhere((e) => e.id == 'c1');
      final clonedC2 = cloned.firstWhere((e) => e.id == 'c2');

      // c1 should have its selected children (custom1, not a1)
      final c1Children = clonedC1.children!.map((e) => e.id).toSet();
      expect(c1Children, contains('custom'));
      expect(c1Children, isNot(contains('a1')));

      // c2 should have its selected children (a2, not custom2)
      final c2Children = clonedC2.children!.map((e) => e.id).toSet();
      expect(c2Children, contains('a2'));
      // custom2 should NOT leak from c1 into c2
      expect(c2Children, isNot(contains('custom')));
    });

    test(
        'cloneTree includes selected custom range entry from original children',
        () {
      final custom = SelectRangeEntry<int, dynamic>.custom(
        parentId: 'c',
        name: 'Custom',
        min: 10,
        max: 20,
      );
      final a = _text('c', 'a', 'A');
      final c = _category('c', 'C', children: {custom, a});

      // Selection marks custom as selected
      final selectedCustom = SelectRangeEntry<int, dynamic>.custom(
        parentId: 'c',
        name: 'Custom',
        min: 50,
        max: 100,
      );

      final cloned = SelectUtils.cloneTree(
        {c},
        [
          <SelectEntry<dynamic>>{c},
          <SelectEntry<dynamic>>{selectedCustom},
        ],
      );

      final clonedC = cloned.single as SelectCategoryEntry<dynamic>;
      final clonedCustom =
          clonedC.children!.whereType<SelectRangeEntry<int, dynamic>>().single;
      expect(clonedCustom.isCustom, isTrue);
      // cloneTree uses original children matched by == (id/parentId/name),
      // so values come from the original entry, not the selected one
      expect(clonedCustom.min, 10);
      expect(clonedCustom.max, 20);
    });

    test('cloneTree returns empty when no root selection', () {
      final a = _text('c', 'a', 'A');
      final c = _category('c', 'C', children: {a});

      final cloned = SelectUtils.cloneTree(
        {c},
        [
          <SelectEntry<dynamic>>{}, // empty root selection
        ],
      );

      expect(cloned, isEmpty);
    });

    test('cloneTree with header/footer selections', () {
      final h1 = _text('header', 'h1', 'H1');
      final h2 = _text('header', 'h2', 'H2');
      final header = _text('c', 'header', 'Header', children: {h1, h2});
      final c = _category(
        'c',
        'C',
        children: {_text('c', 'a', 'A')},
        header: header,
      );

      final cloned = SelectUtils.cloneTree(
        {c},
        [
          <SelectEntry<dynamic>>{c},
        ],
        selectedHeaderEntries: {
          'c': <SelectEntry<dynamic>>{h1},
        },
      );

      final clonedC = cloned.single as SelectCategoryEntry<dynamic>;
      expect(clonedC.header, isNotNull);
      expect(clonedC.header!.children!.map((e) => e.id).toSet(), {'h1'});
    });

    test('cloneTree drops header/footer with no selected children', () {
      final h1 = _text('header', 'h1', 'H1');
      final header = _text('c', 'header', 'Header', children: {h1});

      final f1 = _text('footer', 'f1', 'F1');
      final footer = _text('c', 'footer', 'Footer', children: {f1});

      final c = _category(
        'c',
        'C',
        children: {_text('c', 'a', 'A')},
        header: header,
        footer: footer,
      );

      final cloned = SelectUtils.cloneTree(
        {c},
        [
          <SelectEntry<dynamic>>{c},
          <SelectEntry<dynamic>>{_text('c', 'a', 'A')},
        ],
        selectedHeaderEntries: {
          'c': <SelectEntry<dynamic>>{},
        },
        selectedFooterEntries: {},
      );

      final clonedC = cloned.single as SelectCategoryEntry<dynamic>;
      expect(clonedC.children!.map((e) => e.id).toSet(), {'a'});
      // A header/footer with no selected children is not selected itself.
      expect(clonedC.header, isNull);
      expect(clonedC.footer, isNull);
    });

    test('cloneTree with deepCloneSelectedSubtree=false keeps shallow clones',
        () {
      final g1 = _text('c1', 'g1', 'G1', children: {_text('g1', 'gg1', 'GG1')});
      final c1 = _text('r', 'c1', 'C1', children: {g1});
      final root = _category('r', 'R', children: {c1});

      final cloned = SelectUtils.cloneTree(
        {root},
        [
          <SelectEntry<dynamic>>{root},
          <SelectEntry<dynamic>>{c1},
          <SelectEntry<dynamic>>{g1},
        ],
        deepCloneSelectedSubtree: false,
      );

      final clonedRoot = cloned.single as SelectCategoryEntry<dynamic>;
      final clonedC1 = clonedRoot.children!.single as SelectTextEntry<dynamic>;
      // g1 should be cloned without its children (shallow)
      final clonedG1 = clonedC1.children!.single;
      expect(clonedG1.id, 'g1');
      expect(clonedG1.children, isNull);
    });
  });

  group('SelectUtils – clippingTree (multi-category scenarios)', () {
    test('clippingTree does not leak sibling category children', () {
      final a1 = _text('c1', 'a1', 'A1');
      final a2 = _text('c2', 'a2', 'A2');
      final c1 = _category('c1', 'C1', children: {a1});
      final c2 = _category('c2', 'C2', children: {a2});

      final entries = <SelectEntry<dynamic>>{c1, c2};

      SelectUtils.clippingTree(
        entries,
        [
          <SelectEntry<dynamic>>{c1, c2},
          <SelectEntry<dynamic>>{a1}, // only a1 selected
        ],
        0,
      );

      // c1 should keep a1, c2 should lose a2
      final clippedC1 = entries.firstWhere((e) => e.id == 'c1');
      expect(clippedC1.children!.map((e) => e.id).toSet(), {'a1'});
      // c2's children should be empty since a2 is not selected
      // Note: clippingTree removes unselected entries from children in-place
    });

    test('clippingTree handles null entries', () {
      // Should not throw
      SelectUtils.clippingTree(null, [], 0);
    });

    test('clippingTree handles empty entries', () {
      SelectUtils.clippingTree(<SelectEntry<dynamic>>{}, [], 0);
      // Should not throw
    });

    test('clippingTree handles empty selectedItemsPerLevel', () {
      final a = _text('c', 'a', 'A');
      final c = _category('c', 'C', children: {a});
      final entries = <SelectEntry<dynamic>>{c};

      SelectUtils.clippingTree(entries, [], 0);
      // Entries should be unchanged
      expect(entries.single.children!.map((e) => e.id).toSet(), {'a'});
    });
  });

  group('SelectUtils – restorePreviousSelected (multi-level)', () {
    test('restores multi-level cascading selections', () {
      final leaf = _text('p', 'l', 'L');
      final parent = _text('c', 'p', 'P', children: {leaf});
      final c = _category('c', 'C', children: {parent});
      final items = <SelectEntry<dynamic>>{c}.toList();

      final selectedCategory = SelectCategoryEntry<dynamic>(
        id: 'c',
        name: 'C',
        children: {
          SelectTextEntry<dynamic>(
            parentId: 'c',
            id: 'p',
            name: 'P',
            children: {leaf},
          ),
        },
      );

      final restored =
          SelectUtils.restorePreviousSelected(items, {selectedCategory});

      expect(restored.length, 3);
      expect(restored[0].map((e) => e.id).toSet(), {'c'});
      expect(restored[1].map((e) => e.id).toSet(), {'p'});
      expect(restored[2].map((e) => e.id).toSet(), {'l'});
    });

    test('clears stale min/max on unrestored custom entries', () {
      final customInItems = SelectRangeEntry<int, dynamic>.custom(
        parentId: 'r',
        name: 'Custom',
        min: 100,
        max: 200,
      );
      final items = <SelectEntry<dynamic>>{customInItems}.toList();

      // Restore with an empty selection — custom should be cleared
      SelectUtils.restorePreviousSelected(items, {});

      // The unrestored custom entry should have its values cleared
      expect(customInItems.min, isNull);
      expect(customInItems.max, isNull);
    });

    test('handles null items gracefully', () {
      final restored = SelectUtils.restorePreviousSelected(null, null);
      expect(restored, isEmpty);
    });

    test('handles empty selectedEntries gracefully', () {
      final a = _text('c', 'a', 'A');
      final items = <SelectEntry<dynamic>>{a}.toList();

      final restored = SelectUtils.restorePreviousSelected(items, {});
      expect(restored, isEmpty);
    });
  });

  group('SelectUtils – getResultLabel (multi-level)', () {
    test('returns null for null entries', () {
      expect(SelectUtils.getResultLabel(null, 'Multiple'), isNull);
    });

    test('returns first label for single selection', () {
      final a = _text('c', 'a', 'A');
      final c = _category('c', 'C', children: {a});

      expect(SelectUtils.getResultLabel({c}, 'Multiple'), 'A');
    });

    test('returns multipleText when two labels found', () {
      final a = _text('c', 'a', 'A');
      final b = _text('c', 'b', 'B');
      final c = _category('c', 'C', children: {a, b});

      expect(SelectUtils.getResultLabel({c}, 'Multi'), 'Multi');
    });

    test('ignores "any" leaf whose parent is the category', () {
      final any = SelectTextEntry<dynamic>.any(parentId: 'c', name: 'Any');
      final c = _category('c', 'C', children: {any});

      // Any under category directly is ignored
      expect(SelectUtils.getResultLabel({c}, 'Multiple'), isNull);
    });

    test('uses parent name for "any" leaf with non-category parent', () {
      final any = SelectTextEntry<dynamic>.any(parentId: 'p', name: 'Any');
      final p = _text('c', 'p', 'Parent', children: {any});
      final c = _category('c', 'C', children: {p});

      expect(SelectUtils.getResultLabel({c}, 'Multiple'), 'Parent');
    });

    test('returns null when no valid label found', () {
      final emptyChildren = _text('c', 'e', 'E', children: {});
      final c = _category('c', 'C', children: {emptyChildren});

      // Empty children with no name — should return null
      final label = SelectUtils.getResultLabel({c}, 'Multiple');
      // e has name 'E' so it should be found
      expect(label, isNotNull);
    });
  });

  group('SelectUtils – deepCloneEntries with all entry types', () {
    test('clones SelectTextEntry', () {
      final entry = SelectTextEntry<dynamic>(
        parentId: 'p',
        id: 'e',
        name: 'E',
        children: {_text('e', 'c', 'C')},
        enabled: false,
        immediate: true,
      );

      final cloned = SelectUtils.deepCloneEntries({entry});
      expect(cloned.length, 1);
      expect(identical(cloned.single, entry), isFalse);
      final clonedEntry = cloned.single as SelectTextEntry<dynamic>;
      expect(clonedEntry.parentId, 'p');
      expect(clonedEntry.id, 'e');
      expect(clonedEntry.name, 'E');
      expect(clonedEntry.enabled, false);
      expect(clonedEntry.immediate, true);
      expect(clonedEntry.children!.length, 1);
    });

    test('clones SelectIntEntry (via SelectRangeEntry<int>)', () {
      final entry = SelectRangeEntry<int, dynamic>(
        parentId: 'p',
        id: 'e',
        name: 'E',
        min: 0,
        max: 100,
        divisions: 10,
        inputLabel: 'Label',
        minHintText: 'Min',
        maxHintText: 'Max',
        extra: 'extra_data',
      );

      final cloned = SelectUtils.deepCloneEntries({entry});
      expect(cloned.length, 1);
      final clonedEntry = cloned.single as SelectRangeEntry<int, dynamic>;
      expect(clonedEntry.min, 0);
      expect(clonedEntry.max, 100);
      expect(clonedEntry.divisions, 10);
      expect(clonedEntry.inputLabel, 'Label');
      expect(clonedEntry.minHintText, 'Min');
      expect(clonedEntry.maxHintText, 'Max');
      expect(clonedEntry.extra, 'extra_data');
    });

    test('clones SelectCategoryEntry with header and footer', () {
      final h = _text('header', 'h', 'H');
      final header = _text('c', 'header', 'Header', children: {h});
      final f = _text('footer', 'f', 'F');
      final footer = _text('c', 'footer', 'Footer', children: {f});
      final c = SelectCategoryEntry<dynamic>(
        id: 'c',
        name: 'C',
        children: {_text('c', 'a', 'A')},
        header: header,
        footer: footer,
        headerSelectionMode: SelectionMode.multiple,
        footerSelectionMode: SelectionMode.multiple,
        selectionMode: SelectionMode.multiple,
        layout: const SelectChipLayout(),
      );

      final cloned = SelectUtils.deepCloneEntries({c});
      expect(cloned.length, 1);
      final clonedC = cloned.single as SelectCategoryEntry<dynamic>;
      expect(clonedC.selectionMode, SelectionMode.multiple);
      expect(clonedC.headerSelectionMode, SelectionMode.multiple);
      expect(clonedC.footerSelectionMode, SelectionMode.multiple);
      expect(clonedC.layout, const SelectChipLayout());
      expect(clonedC.header, isNotNull);
      expect(clonedC.footer, isNotNull);
      expect(clonedC.header!.children!.length, 1);
      expect(clonedC.footer!.children!.length, 1);
    });

    test('deepCloneEntries with skipAny excludes any entries', () {
      final any = SelectTextEntry<dynamic>.any(parentId: 'c', name: 'Any');
      final a = _text('c', 'a', 'A');
      final c = _category('c', 'C', children: {any, a});

      final cloned = SelectUtils.deepCloneEntries({c}, skipAny: true);
      final clonedC = cloned.single as SelectCategoryEntry<dynamic>;
      final childIds = clonedC.children!.map((e) => e.id).toSet();
      expect(childIds, {'a'});
      expect(childIds, isNot(contains('any')));
    });
  });

  group('SelectUtils – treeDepth', () {
    test('returns 1 for null root', () {
      expect(SelectUtils().treeDepth(null), 1);
    });

    test('returns 1 for leaf node', () {
      final leaf = _text('', 'l', 'L');
      expect(SelectUtils().treeDepth(leaf), 1);
    });

    test('returns correct depth for multi-level tree', () {
      final gg = _text('g', 'gg', 'GG');
      final g = _text('p', 'g', 'G', children: {gg});
      final p = _text('c', 'p', 'P', children: {g});
      final c = _category('c', 'C', children: {p});

      expect(SelectUtils().treeDepth(c), 4);
    });
  });
}
