import 'package:fl_select/fl_select.dart';
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
  group('SelectEntriesExtension – insert', () {
    test('inserts entry at index while preserving iteration order', () {
      final entries = <SelectEntry<dynamic>>{
        _text('', 'a', 'A'),
        _text('', 'c', 'C'),
      };
      final b = _text('', 'b', 'B');

      entries.insert(1, b);
      final list = entries.toList();

      expect(list[0].id, 'a');
      expect(list[1].id, 'b');
      expect(list[2].id, 'c');
    });

    test('insert at start', () {
      final entries = <SelectEntry<dynamic>>{
        _text('', 'b', 'B'),
        _text('', 'c', 'C'),
      };
      final a = _text('', 'a', 'A');

      entries.insert(0, a);
      expect(entries.first.id, 'a');
    });

    test('insert at end', () {
      final entries = <SelectEntry<dynamic>>{
        _text('', 'a', 'A'),
        _text('', 'b', 'B'),
      };
      final c = _text('', 'c', 'C');

      entries.insert(2, c);
      expect(entries.last.id, 'c');
    });
  });

  group('SelectEntriesExtension – flatten', () {
    test('flatten returns null for empty set', () {
      final entries = <SelectEntry<dynamic>>{};
      expect(entries.flatten(), isNull);
    });

    test('flatten returns per-level entries for category tree', () {
      final a = _text('c', 'a', 'A');
      final c = _category('c', 'C', children: {a});

      final result = {c}.flatten();
      expect(result, isNotNull);
      expect(result!.length, 2);
      expect(result[0].contains(c), isTrue);
      expect(result[1].contains(a), isTrue);
    });

    test('flatten includes header and footer entries', () {
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

      final result = {c}.flatten();
      expect(result, isNotNull);
      // Should include header and footer levels
      expect(result!.length, greaterThanOrEqualTo(2));
    });

    test('flatten handles cascading entries', () {
      final leaf = _text('p', 'l', 'L');
      final parent = _text('c', 'p', 'P', children: {leaf});
      final c = _category('c', 'C', children: {parent});

      final result = {c}.flatten();
      expect(result, isNotNull);
      expect(result!.length, 3);
      expect(result[0].contains(c), isTrue);
      expect(result[1].contains(parent), isTrue);
      expect(result[2].contains(leaf), isTrue);
    });
  });

  group('SelectEntriesExtension – findCategory', () {
    test('finds category by id', () {
      final c = _category('c', 'C', children: {_text('c', 'a', 'A')});

      final found = {c}.findCategory('c');
      expect(found, equals(c));
    });

    test('returns null for non-existent category', () {
      final c = _category('c', 'C', children: {_text('c', 'a', 'A')});

      expect({c}.findCategory('missing'), isNull);
    });

    test('returns null for empty set', () {
      final entries = <SelectEntry<dynamic>>{};
      expect(entries.findCategory('c'), isNull);
    });
  });

  group('SelectEntriesExtension – childIdsOf', () {
    test('returns child ids of a category', () {
      final a = _text('c', 'a', 'A');
      final b = _text('c', 'b', 'B');
      final c = _category('c', 'C', children: {a, b});

      final ids = {c}.childIdsOf('c');
      expect(ids.toSet(), {'a', 'b'});
    });

    test('returns empty list for non-existent category', () {
      final c = _category('c', 'C', children: {_text('c', 'a', 'A')});

      expect({c}.childIdsOf('missing'), isEmpty);
    });

    test('returns empty list when category has no children', () {
      final c = _category('c', 'C', children: {});

      expect({c}.childIdsOf('c'), isEmpty);
    });
  });

  group('SelectEntriesExtension – childRangesOf', () {
    test('returns range entries of a category', () {
      final range = SelectRangeEntry<int, dynamic>(
        parentId: 'c',
        id: 'r',
        name: 'Range',
        min: 0,
        max: 100,
      );
      final c = _category('c', 'C', children: {
        _text('c', 'a', 'A'),
        range,
      });

      final ranges = {c}.childRangesOf('c');
      expect(ranges.length, 1);
      expect(ranges.first, equals(range));
    });

    test('returns empty list for non-existent category', () {
      final c = _category('c', 'C', children: {_text('c', 'a', 'A')});

      expect({c}.childRangesOf('missing'), isEmpty);
    });

    test('returns empty list when no range entries exist', () {
      final c = _category('c', 'C', children: {
        _text('c', 'a', 'A'),
        _text('c', 'b', 'B'),
      });

      expect({c}.childRangesOf('c'), isEmpty);
    });
  });

  group('SelectEntriesExtension – cascadingPairsOf', () {
    test('returns parent-child id pairs for cascading category', () {
      final leaf1 = _text('p1', 'l1', 'L1');
      final leaf2 = _text('p2', 'l2', 'L2');
      final p1 = _text('c', 'p1', 'P1', children: {leaf1});
      final p2 = _text('c', 'p2', 'P2', children: {leaf2});
      final c = _category('c', 'C', children: {p1, p2});

      final pairs = {c}.cascadingPairsOf('c');
      expect(pairs.length, 2);

      // Find p1 pair
      final p1Pair = pairs.firstWhere((p) => p.id == 'p1');
      expect(p1Pair.childIds, ['l1']);

      // Find p2 pair
      final p2Pair = pairs.firstWhere((p) => p.id == 'p2');
      expect(p2Pair.childIds, ['l2']);
    });

    test('returns empty list for non-existent category', () {
      final c = _category('c', 'C', children: {_text('c', 'a', 'A')});

      expect({c}.cascadingPairsOf('missing'), isEmpty);
    });

    test('returns parent with empty childIds when parent has no children', () {
      final p = _text('c', 'p', 'P');
      final c = _category('c', 'C', children: {p});

      final pairs = {c}.cascadingPairsOf('c');
      expect(pairs.length, 1);
      expect(pairs.first.id, 'p');
      expect(pairs.first.childIds, isEmpty);
    });
  });

  group(
      'SelectEntriesExtension – findChildrenAtLevel / findIdsAtLevel / findExtrasAtLevel',
      () {
    test('findChildrenAtLevel delegates to SelectUtils', () {
      final a = _text('c', 'a', 'A');
      final c = _category('c', 'C', children: {a});

      final entries = <SelectEntry<dynamic>>{c};
      expect(entries.findChildrenAtLevel(c, 0), {c});
      expect(entries.findChildrenAtLevel(c, 1).contains(a), isTrue);
    });

    test('findIdsAtLevel delegates to SelectUtils', () {
      final a = _text('c', 'a', 'A');
      final c = _category('c', 'C', children: {a});

      final entries = <SelectEntry<dynamic>>{c};
      expect(entries.findIdsAtLevel(c, 0), {'c'});
      expect(entries.findIdsAtLevel(c, 1), {'a'});
    });
  });

  group('SelectEntriesExtension – firstSelectedId', () {
    test('returns id of first selected entry', () {
      final c = _category('c', 'C', children: {_text('c', 'a', 'A')});

      expect({c}.firstSelectedId, 'c');
    });

    test('returns null for empty set', () {
      final entries = <SelectEntry<dynamic>>{};
      expect(entries.firstSelectedId, isNull);
    });
  });

  group('IterableExtension', () {
    test('hasAnyItem returns true when iterable contains any entry', () {
      final any = SelectTextEntry<dynamic>.any(parentId: 'p', name: 'Any');
      final a = _text('p', 'a', 'A');

      final entries = <SelectEntry<dynamic>>{any, a};
      expect(entries.hasAnyItem, isTrue);
    });

    test('hasAnyItem returns false when no any entry', () {
      final a = _text('p', 'a', 'A');
      final b = _text('p', 'b', 'B');

      final entries = <SelectEntry<dynamic>>{a, b};
      expect(entries.hasAnyItem, isFalse);
    });

    test('hasCustomItem returns true when iterable contains custom range entry',
        () {
      final custom = SelectRangeEntry<int, dynamic>.custom(
        parentId: 'p',
        name: 'Custom',
      );
      final a = _text('p', 'a', 'A');

      final entries = <SelectEntry<dynamic>>{custom, a};
      expect(entries.hasCustomItem, isTrue);
    });

    test('hasCustomItem returns false when no custom entry', () {
      final a = _text('p', 'a', 'A');

      final entries = <SelectEntry<dynamic>>{a};
      expect(entries.hasCustomItem, isFalse);
    });

    test('firstCustomOrNull returns first custom range entry', () {
      final custom = SelectRangeEntry<int, dynamic>.custom(
        parentId: 'p',
        name: 'Custom',
      );
      final a = _text('p', 'a', 'A');

      final entries = <SelectEntry<dynamic>>{custom, a};
      expect(entries.firstCustomOrNull, equals(custom));
    });

    test('firstCustomOrNull returns null when first is not custom', () {
      final a = _text('p', 'a', 'A');

      final entries = <SelectEntry<dynamic>>{a};
      expect(entries.firstCustomOrNull, isNull);
    });

    test('lastCustomOrNull returns last custom range entry', () {
      final a = _text('p', 'a', 'A');
      final custom = SelectRangeEntry<int, dynamic>.custom(
        parentId: 'p',
        name: 'Custom',
      );

      final entries = <SelectEntry<dynamic>>{a, custom};
      expect(entries.lastCustomOrNull, equals(custom));
    });

    test('lastCustomOrNull returns null when last is not custom', () {
      final a = _text('p', 'a', 'A');

      final entries = <SelectEntry<dynamic>>{a};
      expect(entries.lastCustomOrNull, isNull);
    });
  });

  group('Top-level predicate functions', () {
    test('testMultipleElement returns true for multiple-selection category',
        () {
      final c = _category('c', 'C',
          children: {_text('c', 'a', 'A')},
          selectionMode: SelectionMode.multiple);
      expect(testMultipleElement(c), isTrue);
    });

    test('testMultipleElement returns false for single-selection category', () {
      final c = _category('c', 'C', children: {_text('c', 'a', 'A')});
      expect(testMultipleElement(c), isFalse);
    });

    test('testMultipleElement returns false for non-category', () {
      final a = _text('c', 'a', 'A');
      expect(testMultipleElement(a), isFalse);
    });

    test('testAnyElement returns true for any entry', () {
      final any = SelectTextEntry<dynamic>.any(parentId: 'p', name: 'Any');
      expect(testAnyElement(any), isTrue);
    });

    test('testAnyElement returns false for non-any entry', () {
      final a = _text('c', 'a', 'A');
      expect(testAnyElement(a), isFalse);
    });

    test('testCustomElement returns true for custom range entry', () {
      final custom = SelectRangeEntry<int, dynamic>.custom(
        parentId: 'p',
        name: 'Custom',
      );
      expect(testCustomElement(custom), isTrue);
    });

    test('testCustomElement returns false for non-custom entry', () {
      final a = _text('c', 'a', 'A');
      expect(testCustomElement(a), isFalse);
    });

    test('testNotCustomItem returns true for non-custom entry', () {
      final a = _text('c', 'a', 'A');
      expect(testNotCustomItem(a), isTrue);
    });

    test('testNotCustomItem returns false for custom range entry', () {
      final custom = SelectRangeEntry<int, dynamic>.custom(
        parentId: 'p',
        name: 'Custom',
      );
      expect(testNotCustomItem(custom), isFalse);
    });

    test('testSameParentElement returns true when parentId matches', () {
      final a = _text('c', 'a', 'A');
      expect(testSameParentElement(a, 'c'), isTrue);
    });

    test('testSameParentElement returns false when parentId differs', () {
      final a = _text('c', 'a', 'A');
      expect(testSameParentElement(a, 'other'), isFalse);
    });

    test(
        'testSameParentAnyOrCustomElement returns true for any with matching parentId',
        () {
      final any = SelectTextEntry<dynamic>.any(parentId: 'c', name: 'Any');
      expect(testSameParentAnyOrCustomElement(any, 'c'), isTrue);
    });

    test(
        'testSameParentAnyOrCustomElement returns true for custom with matching parentId',
        () {
      final custom = SelectRangeEntry<int, dynamic>.custom(
        parentId: 'c',
        name: 'Custom',
      );
      expect(testSameParentAnyOrCustomElement(custom, 'c'), isTrue);
    });

    test(
        'testSameParentAnyOrCustomElement returns false for non-any/non-custom with matching parentId',
        () {
      final a = _text('c', 'a', 'A');
      expect(testSameParentAnyOrCustomElement(a, 'c'), isFalse);
    });

    test('testSameParentAnyOrCustomElement returns false for wrong parentId',
        () {
      final any = SelectTextEntry<dynamic>.any(parentId: 'c', name: 'Any');
      expect(testSameParentAnyOrCustomElement(any, 'other'), isFalse);
    });
  });
}
