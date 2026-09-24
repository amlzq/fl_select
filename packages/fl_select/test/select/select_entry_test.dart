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
  SelectLayout? layout,
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
    layout: layout,
  );
}

void main() {
  group('SelectEntry base', () {
    test('default values are correct', () {
      final entry = SelectChildEntry<dynamic>(
        parentId: 'p',
        id: 'e',
        name: 'Entry',
      );

      expect(entry.enabled, isTrue);
      expect(entry.immediate, isFalse);
      expect(entry.extra, isNull);
    });

    test('toString returns expected format', () {
      final entry = SelectChildEntry<dynamic>(
        parentId: 'p',
        id: 'e',
        name: 'Entry',
      );

      expect(
        entry.toString(),
        'SelectChildEntry(id: e, parentId: p, name: Entry, children: null)',
      );
    });
  });

  group('SelectChildEntry', () {
    test('== and hashCode: equal entries with same id, parentId, name', () {
      final a = SelectChildEntry<dynamic>(parentId: 'p', id: 'e', name: 'E');
      final b = SelectChildEntry<dynamic>(parentId: 'p', id: 'e', name: 'E');

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('== and hashCode: different parentId makes entries unequal', () {
      final a = SelectChildEntry<dynamic>(parentId: 'p1', id: 'e', name: 'E');
      final b = SelectChildEntry<dynamic>(parentId: 'p2', id: 'e', name: 'E');

      expect(a, isNot(equals(b)));
      expect(a.hashCode, isNot(equals(b.hashCode)));
    });

    test('== and hashCode: name does not participate in identity', () {
      // `name` is mutable presentation state (e.g. the custom range entry
      // rewrites it on every commit), so it must not be part of equality —
      // otherwise an entry mutated while sitting in a Set can no longer be
      // found by contains/remove.
      final a = SelectChildEntry<dynamic>(parentId: 'p', id: 'e', name: 'A');
      final b = SelectChildEntry<dynamic>(parentId: 'p', id: 'e', name: 'B');

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));

      // Renaming an entry already inside a set keeps it addressable.
      final set = <SelectChildEntry<dynamic>>{a};
      a.name = 'C';
      expect(set.contains(a), isTrue);
      expect(set.remove(a), isTrue);
    });

    test('== and hashCode: different id makes entries unequal', () {
      final a = SelectChildEntry<dynamic>(parentId: 'p', id: 'e1', name: 'E');
      final b = SelectChildEntry<dynamic>(parentId: 'p', id: 'e2', name: 'E');

      expect(a, isNot(equals(b)));
    });

    test('== returns false for different runtime type', () {
      final child = SelectChildEntry<dynamic>(
        parentId: 'p',
        id: 'e',
        name: 'E',
      );
      final text = SelectTextEntry<dynamic>(parentId: 'p', id: 'e', name: 'E');

      // Different runtimeType (SelectChildEntry vs SelectTextEntry)
      expect(child, isNot(equals(text)));
    });

    test('copyWith creates a copy with modified fields', () {
      final entry = SelectChildEntry<dynamic>(
        parentId: 'p',
        id: 'e',
        name: 'Old',
      );

      final copied = entry.copyWith(name: 'New', parentId: 'p2');

      expect(copied.name, 'New');
      expect(copied.parentId, 'p2');
      expect(copied.id, 'e'); // unchanged
    });

    test('copyWith preserves unchanged fields', () {
      final entry = SelectChildEntry<dynamic>(
        parentId: 'p',
        id: 'e',
        name: 'E',
        children: {_text('e', 'c', 'C')},
        enabled: false,
        immediate: true,
        extra: 42,
      );

      final copied = entry.copyWith();

      expect(copied.parentId, 'p');
      expect(copied.id, 'e');
      expect(copied.name, 'E');
      expect(copied.children!.length, 1);
      expect(copied.enabled, false);
      expect(copied.immediate, true);
      expect(copied.extra, 42);
    });

    test('any constructor sets id to kAnyEntryId', () {
      final any = SelectChildEntry<dynamic>.any(parentId: 'p', name: 'Any');

      expect(any.id, kAnyEntryId);
      expect(any.parentId, 'p');
      expect(any.name, 'Any');
    });

    test('leaves parentId to derivation', () {
      final parent = SelectChildEntry<dynamic>(
        id: 'p',
        name: 'Parent',
        children: {
          SelectTextEntry<dynamic>(id: 'a', name: 'A'),
          SelectTextEntry<dynamic>(id: 'b', name: 'B'),
        },
      );

      expect(parent.id, 'p');
      expect(parent.parentId, '');
      expect(parent.name, 'Parent');
      expect(parent.children!.length, 2);
      // Nothing is injected at construction time any more: the parent links are
      // derived from the tree structure when the entries are bound.
      for (final child in parent.children!) {
        expect((child as SelectChildEntry).parentId, '');
      }
    });

    test('preserves enabled, immediate and extra', () {
      final parent = SelectChildEntry<dynamic>(
        id: 'p',
        name: 'Parent',
        enabled: false,
        immediate: true,
        extra: 42,
        children: {SelectTextEntry<dynamic>(id: 'a', name: 'A')},
      );

      expect(parent.parentId, '');
      expect(parent.id, 'p');
      expect(parent.enabled, false);
      expect(parent.immediate, true);
      expect(parent.extra, 42);
    });

    test(
      'multi-level category tree passes SelectController.validateEntries',
      () {
        final category = SelectCategoryEntry<dynamic>(
          id: 'c1',
          name: 'Cate 1',
          children: {
            SelectTextEntry<dynamic>(
              id: 'a',
              name: 'A',
              children: {
                SelectTextEntry<dynamic>(id: 'a1', name: 'A1'),
                SelectTextEntry<dynamic>(id: 'a2', name: 'A2'),
              },
            ),
            SelectTextEntry<dynamic>(id: 'b', name: 'B'),
            SelectTextEntry<dynamic>(id: 'c', name: 'C'),
          },
        );

        // Plain constructors leave every parentId empty; the links are derived
        // from the tree structure on binding, each node taking the id of its
        // direct parent ('a1' -> 'a' -> 'c1').
        for (final child in category.children!) {
          expect((child as SelectChildEntry).parentId, '');
        }

        // A multi-level tree must not fail parentId validation.
        expect(
          () => SelectController.validateEntries([category]),
          returnsNormally,
        );
      },
    );
  });

  group('SelectChildEntryExt', () {
    test('isAny returns true for kAnyEntryId', () {
      final any = SelectChildEntry<dynamic>.any(parentId: 'p', name: 'Any');
      expect(any.isAny, isTrue);
    });

    test('isAny returns false for non-any entries', () {
      final entry = SelectChildEntry<dynamic>(
        parentId: 'p',
        id: 'e',
        name: 'E',
      );
      expect(entry.isAny, isFalse);
    });

    test('isEmpty returns true for empty id', () {
      final empty = SelectChildEntry<dynamic>(id: '');
      expect(empty.isEmpty, isTrue);
      expect(empty.isNotEmpty, isFalse);
    });

    test('isNotEmpty returns true for non-empty id', () {
      final entry = SelectChildEntry<dynamic>(
        parentId: 'p',
        id: 'e',
        name: 'E',
      );
      expect(entry.isNotEmpty, isTrue);
      expect(entry.isEmpty, isFalse);
    });
  });

  group('SelectTextEntry', () {
    test('any constructor sets id to kAnyEntryId', () {
      final any = SelectTextEntry<dynamic>.any(parentId: 'p', name: 'Any');

      expect(any.id, kAnyEntryId);
      expect(any.isAny, isTrue);
    });

    test('default constructor creates entry without parentId', () {
      final entry = SelectTextEntry<dynamic>(
        id: 'e',
        name: 'Entry',
        enabled: false,
        immediate: true,
      );

      expect(entry.id, 'e');
      expect(entry.name, 'Entry');
      expect(entry.parentId, '');
      expect(entry.enabled, false);
      expect(entry.immediate, true);
    });

    test('inherits SelectChildEntry == (runtimeType, id, parentId, name)', () {
      final a = SelectTextEntry<dynamic>(parentId: 'p', id: 'e', name: 'E');
      final b = SelectTextEntry<dynamic>(parentId: 'p', id: 'e', name: 'E');

      expect(a, equals(b));
    });

    test('carries children without injecting their parentId', () {
      final entry = SelectTextEntry<dynamic>(
        id: 'p',
        name: 'Parent',
        children: {SelectTextEntry<dynamic>(id: 'a', name: 'A')},
      );

      expect(entry, isA<SelectTextEntry<dynamic>>());
      expect(entry.id, 'p');
      expect(entry.parentId, '');
      expect(entry.name, 'Parent');
      final child = entry.children!.single as SelectChildEntry;
      expect(child.parentId, '');
    });

    test(
      'leaves own parentId empty, preserves fields',
      () {
        final entry = SelectTextEntry<dynamic>(
          id: 'p',
          name: 'Parent',
          enabled: false,
          immediate: true,
          extra: 'x',
          children: {SelectTextEntry<dynamic>(id: 'a', name: 'A')},
        );

        expect(entry.parentId, '');
        expect(entry.id, 'p');
        expect(entry.enabled, false);
        expect(entry.immediate, true);
        expect(entry.extra, 'x');
      },
    );
  });

  group('SelectRangeEntry', () {
    test('custom constructor sets id to kCustomEntryId', () {
      final custom = SelectRangeEntry<int, dynamic>.custom(
        parentId: 'p',
        name: 'Custom',
        min: 10,
        max: 20,
      );

      expect(custom.id, kCustomEntryId);
      expect(custom.isCustom, isTrue);
      expect(custom.min, 10);
      expect(custom.max, 20);
    });

    test('any constructor sets id to kAnyEntryId', () {
      final any = SelectRangeEntry<int, dynamic>.any(
        parentId: 'p',
        name: 'Any',
      );

      expect(any.id, kAnyEntryId);
      expect(any.isAny, isTrue);
    });

    test('copyWith creates copy with modified range fields', () {
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
      );

      final copied = entry.copyWith(
        min: 50,
        max: 200,
        divisions: 5,
        inputLabel: 'New',
      );

      expect(copied.min, 50);
      expect(copied.max, 200);
      expect(copied.divisions, 5);
      expect(copied.inputLabel, 'New');
      expect(copied.minHintText, 'Min'); // unchanged
      expect(copied.maxHintText, 'Max'); // unchanged
    });

    test('copyWith preserves unchanged range fields', () {
      final entry = SelectRangeEntry<int, dynamic>.custom(
        parentId: 'p',
        name: 'Custom',
        min: 0,
        max: 100,
        divisions: 10,
      );

      final copied = entry.copyWith();

      expect(copied.parentId, 'p');
      expect(copied.id, kCustomEntryId);
      expect(copied.min, 0);
      expect(copied.max, 100);
      expect(copied.divisions, 10);
    });
  });

  group('SelectRangeEntryExt', () {
    test('isCustom returns true for custom id', () {
      final custom = SelectRangeEntry<int, dynamic>.custom(
        parentId: 'p',
        name: 'Custom',
      );
      expect(custom.isCustom, isTrue);
    });

    test('isCustom returns false for non-custom entries', () {
      final entry = SelectRangeEntry<int, dynamic>(
        parentId: 'p',
        id: 'e',
        name: 'E',
      );
      expect(entry.isCustom, isFalse);
    });

    test('hasCustomValue returns true when min is set', () {
      final entry = SelectRangeEntry<int, dynamic>.custom(
        parentId: 'p',
        name: 'Custom',
        min: 10,
      );
      expect(entry.hasCustomValue, isTrue);
    });

    test('hasCustomValue returns true when max is set', () {
      final entry = SelectRangeEntry<int, dynamic>.custom(
        parentId: 'p',
        name: 'Custom',
        max: 20,
      );
      expect(entry.hasCustomValue, isTrue);
    });

    test('hasCustomValue returns false when no values set', () {
      final entry = SelectRangeEntry<int, dynamic>.custom(
        parentId: 'p',
        name: 'Custom',
      );
      expect(entry.hasCustomValue, isFalse);
    });

    test('custom entry name stays null until the view commits the range', () {
      // SelectRangeEntry.custom with no explicit name: base name is null.
      // The former extension `name` getter (falling back to '$min-$max') was
      // removed: an extension member can never shadow the instance field
      // [SelectEntry.name], so it was unreachable dead code. Instead, the
      // hosting view writes the formatted name back on commit (e.g.
      // _SelectGridViewState._commitCustomRange), mirroring the slider.
      final entry = SelectRangeEntry<int, dynamic>.custom(
        parentId: 'p',
        min: 10,
        max: 20,
      );
      expect(entry.name, isNull);
      expect(entry.min, 10);
      expect(entry.max, 20);
      expect(entry.isCustom, isTrue);
      // hasCustomValue relies on min/max being non-null
      expect(entry.hasCustomValue, isTrue);
    });
  });

  group('SelectCategoryEntry', () {
    test(
      '== and hashCode: equal categories with same id, name, selectionMode, layout',
      () {
        final a = _category('c', 'C', children: {_text('c', 'a', 'A')});
        final b = _category('c', 'C', children: {_text('c', 'a', 'A')});

        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      },
    );

    test(
      '== and hashCode: different selectionMode makes categories unequal',
      () {
        final a = _category(
          'c',
          'C',
          children: {_text('c', 'a', 'A')},
          selectionMode: SelectionMode.single,
        );
        final b = _category(
          'c',
          'C',
          children: {_text('c', 'a', 'A')},
          selectionMode: SelectionMode.multiple,
        );

        expect(a, isNot(equals(b)));
      },
    );

    test('== and hashCode: different layout makes categories unequal', () {
      final a = _category(
        'c',
        'C',
        children: {_text('c', 'a', 'A')},
        layout: const SelectListLayout(),
      );
      final b = _category(
        'c',
        'C',
        children: {_text('c', 'a', 'A')},
        layout: const SelectWrapLayout(),
      );

      expect(a, isNot(equals(b)));
    });

    test('== and hashCode: different name makes categories unequal', () {
      final a = _category('c', 'C1', children: {_text('c', 'a', 'A')});
      final b = _category('c', 'C2', children: {_text('c', 'a', 'A')});

      expect(a, isNot(equals(b)));
    });

    test('selection modes default to null (inherit the delegate mode)', () {
      final c = SelectCategoryEntry<dynamic>(
        id: 'c',
        name: 'C',
        children: {_text('c', 'a', 'A')},
      );

      expect(c.selectionMode, isNull);
      expect(c.headerSelectionMode, isNull);
      expect(c.footerSelectionMode, isNull);
      expect(c.layout, isNull);
    });

    test('effective selection modes resolve the inheritance chain', () {
      // All modes null: everything falls back to the delegate-level mode.
      final inherited = SelectCategoryEntry<dynamic>(
        id: 'c1',
        name: 'C1',
        children: {_text('c1', 'a', 'A')},
      );
      expect(
        inherited.effectiveSelectionMode(SelectionMode.multiple),
        SelectionMode.multiple,
      );
      expect(
        inherited.effectiveHeaderSelectionMode(SelectionMode.multiple),
        SelectionMode.multiple,
      );
      expect(
        inherited.effectiveFooterSelectionMode(SelectionMode.multiple),
        SelectionMode.multiple,
      );

      // selectionMode set, header/footer null: header/footer follow the
      // category's effective mode.
      final mixed = SelectCategoryEntry<dynamic>(
        id: 'c2',
        name: 'C2',
        children: {_text('c2', 'a', 'A')},
        selectionMode: SelectionMode.single,
      );
      expect(
        mixed.effectiveSelectionMode(SelectionMode.multiple),
        SelectionMode.single,
      );
      expect(
        mixed.effectiveHeaderSelectionMode(SelectionMode.multiple),
        SelectionMode.single,
      );
      expect(
        mixed.effectiveFooterSelectionMode(SelectionMode.multiple),
        SelectionMode.single,
      );

      // Explicit header/footer modes override the inheritance chain.
      final explicit = SelectCategoryEntry<dynamic>(
        id: 'c3',
        name: 'C3',
        children: {_text('c3', 'a', 'A')},
        headerSelectionMode: SelectionMode.single,
        footerSelectionMode: SelectionMode.multiple,
      );
      expect(
        explicit.effectiveHeaderSelectionMode(SelectionMode.multiple),
        SelectionMode.single,
      );
      expect(
        explicit.effectiveFooterSelectionMode(SelectionMode.single),
        SelectionMode.multiple,
      );
    });

    test('copyWith creates copy with modified selectionMode', () {
      final c = _category('c', 'C', children: {_text('c', 'a', 'A')});

      final copied = c.copyWith(selectionMode: SelectionMode.multiple);

      expect(copied.selectionMode, SelectionMode.multiple);
      expect(copied.id, 'c'); // unchanged
    });

    test('copyWith creates copy with header and footer', () {
      final c = _category('c', 'C', children: {_text('c', 'a', 'A')});
      final newHeader = _text('c', 'h', 'H');
      final newFooter = _text('c', 'f', 'F');

      final copied = c.copyWith(
        header: newHeader,
        footer: newFooter,
        headerSelectionMode: SelectionMode.multiple,
        footerSelectionMode: SelectionMode.multiple,
      );

      expect(copied.header, equals(newHeader));
      expect(copied.footer, equals(newFooter));
      expect(copied.headerSelectionMode, SelectionMode.multiple);
      expect(copied.footerSelectionMode, SelectionMode.multiple);
    });

    test('copyWith preserves unchanged fields', () {
      final header = _text('c', 'h', 'H');
      final c = _category(
        'c',
        'C',
        children: {_text('c', 'a', 'A')},
        header: header,
        headerSelectionMode: SelectionMode.multiple,
        selectionMode: SelectionMode.multiple,
      );

      final copied = c.copyWith(name: 'NewName');

      expect(copied.name, 'NewName');
      expect(copied.header, equals(header));
      expect(copied.headerSelectionMode, SelectionMode.multiple);
      expect(copied.selectionMode, SelectionMode.multiple);
    });

    test('copyWith with layout', () {
      final c = _category('c', 'C', children: {_text('c', 'a', 'A')});

      const gridLayout = SelectGridLayout(crossAxisCount: 3);
      final copied = c.copyWith(layout: gridLayout);

      expect(copied.layout, equals(gridLayout));
    });

    test('header is mutable', () {
      final c = _category('c', 'C', children: {_text('c', 'a', 'A')});
      final newHeader = _text('c', 'h', 'H');

      c.header = newHeader;
      expect(c.header, equals(newHeader));
    });

    test('footer is mutable', () {
      final c = _category('c', 'C', children: {_text('c', 'a', 'A')});
      final newFooter = _text('c', 'f', 'F');

      c.footer = newFooter;
      expect(c.footer, equals(newFooter));
    });
  });

  group('SelectCategoryEntryExtension', () {
    test('firstCustomOrNull returns first custom range entry', () {
      final custom = SelectRangeEntry<int, dynamic>.custom(
        parentId: 'c',
        name: 'Custom',
      );
      final c = _category('c', 'C', children: {custom, _text('c', 'a', 'A')});

      expect(c.firstCustomOrNull, equals(custom));
    });

    test('firstCustomOrNull returns null when no custom entry', () {
      final c = _category(
        'c',
        'C',
        children: {_text('c', 'a', 'A'), _text('c', 'b', 'B')},
      );

      expect(c.firstCustomOrNull, isNull);
    });

    test('lastCustomOrNull returns last custom range entry', () {
      final custom = SelectRangeEntry<int, dynamic>.custom(
        parentId: 'c',
        name: 'Custom',
      );
      final c = _category('c', 'C', children: {_text('c', 'a', 'A'), custom});

      expect(c.lastCustomOrNull, equals(custom));
    });

    test('lastCustomOrNull returns null when no custom entry', () {
      final c = _category('c', 'C', children: {_text('c', 'a', 'A')});

      expect(c.lastCustomOrNull, isNull);
    });

    test('hasCustomOrNull returns true when custom exists', () {
      final custom = SelectRangeEntry<int, dynamic>.custom(
        parentId: 'c',
        name: 'Custom',
      );
      final c = _category('c', 'C', children: {custom});

      expect(c.hasCustomOrNull, isTrue);
    });

    test('hasCustomOrNull returns false when no custom exists', () {
      final c = _category('c', 'C', children: {_text('c', 'a', 'A')});

      expect(c.hasCustomOrNull, isFalse);
    });
  });

  group('SelectEntryExt', () {
    test('firstChild returns first child', () {
      final a = _text('c', 'a', 'A');
      final b = _text('c', 'b', 'B');
      final c = _category('c', 'C', children: {a, b});

      // Note: Set ordering is insertion-order based
      expect(c.firstChild, isNotNull);
    });

    test('firstChild returns null for leaf entry', () {
      final a = _text('c', 'a', 'A');
      expect(a.firstChild, isNull);
    });

    test('lastChild returns last child', () {
      final a = _text('c', 'a', 'A');
      final b = _text('c', 'b', 'B');
      final c = _category('c', 'C', children: {a, b});

      expect(c.lastChild, isNotNull);
    });

    test('lastChild returns null for leaf entry', () {
      final a = _text('c', 'a', 'A');
      expect(a.lastChild, isNull);
    });

    test('hasChildren returns true when children exist', () {
      final c = _category('c', 'C', children: {_text('c', 'a', 'A')});
      expect(c.hasChildren, isTrue);
    });

    test('hasChildren returns false for leaf entry', () {
      final a = _text('c', 'a', 'A');
      expect(a.hasChildren, isFalse);
    });

    test('hasChildren returns false for null children', () {
      final entry = SelectChildEntry<dynamic>(
        parentId: 'p',
        id: 'e',
        name: 'E',
      );
      expect(entry.hasChildren, isFalse);
    });

    test('maxLevel returns 1 for leaf entry', () {
      final a = _text('c', 'a', 'A');
      expect(a.maxLevel, 1);
    });

    test('maxLevel returns depth for nested tree', () {
      final leaf = _text('p', 'l', 'L');
      final parent = _text('c', 'p', 'P', children: {leaf});
      final c = _category('c', 'C', children: {parent});

      expect(c.maxLevel, 3);
    });

    test('maxLevel for category with flat children', () {
      final c = _category(
        'c',
        'C',
        children: {_text('c', 'a', 'A'), _text('c', 'b', 'B')},
      );

      expect(c.maxLevel, 2);
    });
  });

  group('Constants', () {
    test('kAnyEntryId is "any"', () {
      expect(kAnyEntryId, 'any');
    });

    test('kCustomEntryId is "custom"', () {
      expect(kCustomEntryId, 'custom');
    });
  });

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
      final c = _category('c', 'C', children: {_text('c', 'a', 'A'), range});

      final ranges = {c}.childRangesOf('c');
      expect(ranges.length, 1);
      expect(ranges.first, equals(range));
    });

    test('returns empty list for non-existent category', () {
      final c = _category('c', 'C', children: {_text('c', 'a', 'A')});

      expect({c}.childRangesOf('missing'), isEmpty);
    });

    test('returns empty list when no range entries exist', () {
      final c = _category(
        'c',
        'C',
        children: {_text('c', 'a', 'A'), _text('c', 'b', 'B')},
      );

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
    },
  );

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

  group('SelectEntriesExtension – toQueryMap', () {
    test('maps category children to key=leafId pairs', () {
      final cate3 = _category(
        'cate3',
        'Cate 3',
        children: {_text('cate3', 'b', 'B')},
      );
      final cate4 = _category(
        'cate4',
        'Cate 4',
        children: {_text('cate4', 'd', 'D')},
      );

      expect({cate3, cate4}.toQueryMap(), {
        'cate3': ['b'],
        'cate4': ['d'],
      });
    });

    test('groups the deepest leaves under one key in cascading trees', () {
      final cate1 = _category(
        'cate1',
        'Cate 1',
        children: {
          _text(
            'cate1',
            'l1-a',
            'A',
            children: {
              _text('l1-a', 'l2-a', 'Football'),
              _text('l1-a', 'l2-b', 'Basketball'),
            },
          ),
        },
      );

      expect({cate1}.toQueryMap(), {
        'cate1': ['l2-a', 'l2-b'],
      });
    });

    test('resolves any leaves to their parent id', () {
      final cate1 = _category(
        'cate1',
        'Cate 1',
        children: {
          _text('cate1', 'l1-a', 'A', children: {_text('l1-a', 'any', 'Any')}),
        },
      );

      expect({cate1}.toQueryMap(), {
        'cate1': ['l1-a'],
      });
    });

    test('keys header/footer subtrees by their own ids', () {
      final cate3 = _category(
        'cate3',
        'Cate 3',
        children: {_text('cate3', 'a', 'Football')},
        header: _text(
          'cate3',
          'c3-h',
          'Header',
          children: {_text('c3-h', 'h-a', 'Red')},
        ),
        footer: _text(
          'cate3',
          'c3-f',
          'Footer',
          children: {_text('c3-f', 'f-a', 'Blue')},
        ),
      );

      expect({cate3}.toQueryMap(), {
        'c3-h': ['h-a'],
        'cate3': ['a'],
        'c3-f': ['f-a'],
      });
    });

    test('formats custom range entries as min-max', () {
      final cate1 = _category(
        'cate1',
        'Cate 1',
        children: {
          SelectRangeEntry<int, dynamic>(
            parentId: 'cate1',
            id: 'custom',
            name: null,
            min: 111,
            max: 222,
          ),
        },
      );

      expect({cate1}.toQueryMap(), {
        'cate1': ['111-222'],
      });
    });

    test('returns empty map for empty set', () {
      expect(<SelectEntry<dynamic>>{}.toQueryMap(), isEmpty);
    });

    test('throws StateError for flat (non-category) selections', () {
      final flat = <SelectEntry<dynamic>>{_text('', 'a', 'A')};

      expect(() => flat.toQueryMap(), throwsStateError);
    });

    test('throws StateError for mixed category and flat entries', () {
      final c = _category('c', 'C', children: {_text('c', 'a', 'A')});
      final mixed = <SelectEntry<dynamic>>{c, _text('', 'b', 'B')};

      expect(() => mixed.toQueryMap(), throwsStateError);
    });
  });

  group('SelectEntriesExtension – toQueryParameters', () {
    Set<SelectEntry<dynamic>> multiValueSelection() => {
      _category(
        'cate1',
        'Cate 1',
        children: {
          _text('cate1', 'l2-a', 'Football'),
          _text('cate1', 'l2-b', 'Basketball'),
        },
      ),
      _category('cate2', 'Cate 2', children: {_text('cate2', 'c', 'Lion')}),
    };

    test('defaults to repeat format', () {
      expect(
        multiValueSelection().toQueryParameters(),
        'cate1=l2-a&cate1=l2-b&cate2=c',
      );
    });

    test('repeat format repeats the key per value', () {
      expect(
        multiValueSelection().toQueryParameters(
          arrayFormat: SelectArrayFormat.repeat,
        ),
        'cate1=l2-a&cate1=l2-b&cate2=c',
      );
    });

    test('brackets format appends [] to the key', () {
      expect(
        multiValueSelection().toQueryParameters(
          arrayFormat: SelectArrayFormat.brackets,
        ),
        'cate1%5B%5D=l2-a&cate1%5B%5D=l2-b&cate2%5B%5D=c',
      );
    });

    test('comma format joins values with commas', () {
      expect(
        multiValueSelection().toQueryParameters(
          arrayFormat: SelectArrayFormat.comma,
        ),
        'cate1=l2-a,l2-b&cate2=c',
      );
    });

    test('indices format numbers each value', () {
      expect(
        multiValueSelection().toQueryParameters(
          arrayFormat: SelectArrayFormat.indices,
        ),
        'cate1%5B0%5D=l2-a&cate1%5B1%5D=l2-b&cate2%5B0%5D=c',
      );
    });

    test('delimited format joins values with the delimiter', () {
      expect(
        multiValueSelection().toQueryParameters(
          arrayFormat: SelectArrayFormat.delimited,
          delimiter: '|',
        ),
        'cate1=l2-a|l2-b&cate2=c',
      );
    });

    test('delimited format defaults delimiter to comma', () {
      expect(
        multiValueSelection().toQueryParameters(
          arrayFormat: SelectArrayFormat.delimited,
        ),
        'cate1=l2-a,l2-b&cate2=c',
      );
    });

    test('encode=false keeps reserved characters raw', () {
      expect(
        multiValueSelection().toQueryParameters(
          arrayFormat: SelectArrayFormat.brackets,
          encode: false,
        ),
        'cate1[]=l2-a&cate1[]=l2-b&cate2[]=c',
      );
      expect(
        multiValueSelection().toQueryParameters(
          arrayFormat: SelectArrayFormat.delimited,
          delimiter: '|',
          encode: false,
        ),
        'cate1=l2-a|l2-b&cate2=c',
      );
    });

    test('percent-encodes values with special characters', () {
      final cate = _category(
        'cate',
        'Cate',
        children: {_text('cate', 'a&b=c', 'Weird')},
      );

      expect({cate}.toQueryParameters(), 'cate=a%26b%3Dc');
    });

    test('mixes cascading and direct children under the same key', () {
      final cate1 = _category(
        'cate1',
        'Cate 1',
        children: {
          _text('cate1', 'l1-a', 'A', children: {_text('l1-a', 'any', 'Any')}),
          _text('cate1', 'l1-b', 'B'),
        },
      );

      expect({cate1}.toQueryParameters(), 'cate1=l1-a&cate1=l1-b');
    });

    test('returns empty string for empty set', () {
      expect(<SelectEntry<dynamic>>{}.toQueryParameters(), '');
    });

    test('throws StateError for flat selections (propagates toQueryMap)', () {
      final flat = <SelectEntry<dynamic>>{_text('', 'a', 'A')};

      expect(() => flat.toQueryParameters(), throwsStateError);
    });
  });

  group('SelectEntriesExtension – toIdList', () {
    test('collects leaf ids in selection order', () {
      final entries = <SelectEntry<dynamic>>{
        _text('', 'a', 'A'),
        _text('', 'b', 'B'),
      };

      expect(entries.toIdList(), ['a', 'b']);
    });

    test('walks to the deepest leaves of top-level branches', () {
      final entries = <SelectEntry<dynamic>>{
        _text(
          '',
          'p',
          'P',
          children: {_text('p', 'l1', 'L1'), _text('p', 'l2', 'L2')},
        ),
      };

      expect(entries.toIdList(), ['l1', 'l2']);
    });

    test('formats custom range entries as min-max', () {
      final entries = <SelectEntry<dynamic>>{
        SelectRangeEntry<int, dynamic>(
          parentId: '',
          id: 'custom',
          name: null,
          min: 111,
          max: 222,
        ),
      };

      expect(entries.toIdList(), ['111-222']);
    });

    test('resolves any leaves to their parent id', () {
      final entries = <SelectEntry<dynamic>>{_text('p', 'any', 'Any')};

      expect(entries.toIdList(), ['p']);
    });

    test('throws StateError for category trees', () {
      final c = _category('c', 'C', children: {_text('c', 'a', 'A')});

      expect(() => {c}.toIdList(), throwsStateError);
    });

    test('returns empty list for empty set', () {
      expect(<SelectEntry<dynamic>>{}.toIdList(), isEmpty);
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

    test(
      'hasCustomItem returns true when iterable contains custom range entry',
      () {
        final custom = SelectRangeEntry<int, dynamic>.custom(
          parentId: 'p',
          name: 'Custom',
        );
        final a = _text('p', 'a', 'A');

        final entries = <SelectEntry<dynamic>>{custom, a};
        expect(entries.hasCustomItem, isTrue);
      },
    );

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
    test(
      'testMultipleElement returns true for multiple-selection category',
      () {
        final c = _category(
          'c',
          'C',
          children: {_text('c', 'a', 'A')},
          selectionMode: SelectionMode.multiple,
        );
        expect(testMultipleElement(c), isTrue);
      },
    );

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
      },
    );

    test(
      'testSameParentAnyOrCustomElement returns true for custom with matching parentId',
      () {
        final custom = SelectRangeEntry<int, dynamic>.custom(
          parentId: 'c',
          name: 'Custom',
        );
        expect(testSameParentAnyOrCustomElement(custom, 'c'), isTrue);
      },
    );

    test(
      'testSameParentAnyOrCustomElement returns false for non-any/non-custom with matching parentId',
      () {
        final a = _text('c', 'a', 'A');
        expect(testSameParentAnyOrCustomElement(a, 'c'), isFalse);
      },
    );

    test(
      'testSameParentAnyOrCustomElement returns false for wrong parentId',
      () {
        final any = SelectTextEntry<dynamic>.any(parentId: 'c', name: 'Any');
        expect(testSameParentAnyOrCustomElement(any, 'other'), isFalse);
      },
    );
  });

  group('deprecated named constructors', () {
    // These constructors remain for backward compatibility and are scheduled
    // for removal in a future minor version: parentId is derived from the tree
    // structure now, so all they still contribute is the eager injection they
    // used to perform.

    test('SelectChildEntry.empty still creates an empty placeholder', () {
      // ignore: deprecated_member_use_from_same_package
      final empty = SelectChildEntry<dynamic>.empty(parentId: 'p');

      expect(empty.id, '');
      expect(empty.parentId, 'p');
      expect(empty.name, isNull);
      expect(empty.enabled, isTrue);
      expect(empty.immediate, isFalse);
    });

    test('SelectTextEntry.id still creates an entry with a blank name', () {
      // ignore: deprecated_member_use_from_same_package
      final entry = SelectTextEntry<dynamic>.id(id: 'e');

      expect(entry.id, 'e');
      expect(entry.parentId, '');
      expect(entry.name, '');
    });

    test('SelectTextEntry.name matches the default constructor', () {
      // ignore: deprecated_member_use_from_same_package
      final legacy = SelectTextEntry<dynamic>.name(id: 'e', name: 'Entry');
      final current = SelectTextEntry<dynamic>(id: 'e', name: 'Entry');

      expect(legacy, equals(current));
    });

    test('SelectChildEntry.children still injects parentId into children', () {
      // ignore: deprecated_member_use_from_same_package
      final parent = SelectChildEntry<dynamic>.children(
        id: 'p',
        name: 'Parent',
        children: {
          SelectTextEntry<dynamic>(id: 'a', name: 'A'),
          SelectTextEntry<dynamic>(id: 'b', name: 'B'),
        },
      );

      expect(parent.parentId, '');
      for (final child in parent.children!) {
        expect((child as SelectChildEntry).parentId, 'p');
      }
    });

    test('SelectChildEntry.children injects recursively', () {
      // ignore: deprecated_member_use_from_same_package
      final parent = SelectChildEntry<dynamic>.children(
        id: 'p',
        name: 'Parent',
        children: {
          SelectTextEntry<dynamic>(id: 'a', name: 'A').copyWith(
            children: {SelectTextEntry<dynamic>(id: 'a1', name: 'A1')},
          ),
        },
      );

      final child = parent.children!.single as SelectChildEntry;
      expect(child.parentId, 'p');
      final grandchild = child.children!.single as SelectChildEntry;
      // Each node's parentId matches its direct parent: the grandchild's direct
      // parent is the child (id 'a'), not the root (id 'p').
      expect(grandchild.parentId, 'a');
    });

    test('SelectChildEntry.children overwrites explicit child parentIds', () {
      // ignore: deprecated_member_use_from_same_package
      final parent = SelectChildEntry<dynamic>.children(
        id: 'p',
        name: 'Parent',
        children: {
          SelectTextEntry<dynamic>(parentId: 'stale', id: 'a', name: 'A'),
        },
      );

      // The tree shape stays authoritative for this factory.
      expect((parent.children!.single as SelectChildEntry).parentId, 'p');
    });

    test('SelectTextEntry.children keeps the concrete type and injects', () {
      // ignore: deprecated_member_use_from_same_package
      final entry = SelectTextEntry<dynamic>.children(
        id: 'p',
        name: 'Parent',
        children: {SelectTextEntry<dynamic>(id: 'a', name: 'A')},
      );

      expect(entry, isA<SelectTextEntry<dynamic>>());
      expect(entry.parentId, '');
      expect((entry.children!.single as SelectChildEntry).parentId, 'p');
    });

    test('SelectCategoryEntry.children injects parentId into every branch', () {
      // ignore: deprecated_member_use_from_same_package
      final category = SelectCategoryEntry<dynamic>.children(
        id: 'c1',
        name: 'Cate 1',
        children: {
          SelectTextEntry<dynamic>(
            id: 'a',
            name: 'A',
            children: {
              SelectTextEntry<dynamic>(id: 'a1', name: 'A1'),
              SelectTextEntry<dynamic>(id: 'a2', name: 'A2'),
            },
          ),
          SelectTextEntry<dynamic>(id: 'b', name: 'B'),
        },
        header: SelectTextEntry<dynamic>(id: 'h', name: 'H'),
        footer: SelectTextEntry<dynamic>(
          id: 'f',
          name: 'F',
          children: {SelectTextEntry<dynamic>(id: 'f1', name: 'F1')},
        ),
      );

      for (final child in category.children!) {
        expect((child as SelectChildEntry).parentId, 'c1');
      }
      final branchA =
          category.children!.firstWhere((e) => e.id == 'a')
              as SelectChildEntry;
      for (final grandchild in branchA.children!) {
        expect((grandchild as SelectChildEntry).parentId, 'a');
      }
      expect((category.header! as SelectChildEntry).parentId, 'c1');
      final footer = category.footer! as SelectChildEntry;
      expect(footer.parentId, 'c1');
      expect((footer.children!.single as SelectChildEntry).parentId, 'f');

      expect(
        () => SelectController.validateEntries([category]),
        returnsNormally,
      );
    });
  });
}
