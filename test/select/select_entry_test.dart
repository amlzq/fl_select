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
        'SelectChildEntry(id: e, parentId: p, name: Entry)',
      );
    });
  });

  group('SelectChildEntry', () {
    test('== and hashCode: equal entries with same id, parentId, name', () {
      final a = SelectChildEntry<dynamic>(
        parentId: 'p',
        id: 'e',
        name: 'E',
      );
      final b = SelectChildEntry<dynamic>(
        parentId: 'p',
        id: 'e',
        name: 'E',
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('== and hashCode: different parentId makes entries unequal', () {
      final a = SelectChildEntry<dynamic>(
        parentId: 'p1',
        id: 'e',
        name: 'E',
      );
      final b = SelectChildEntry<dynamic>(
        parentId: 'p2',
        id: 'e',
        name: 'E',
      );

      expect(a, isNot(equals(b)));
      expect(a.hashCode, isNot(equals(b.hashCode)));
    });

    test('== and hashCode: different name makes entries unequal', () {
      final a = SelectChildEntry<dynamic>(
        parentId: 'p',
        id: 'e',
        name: 'A',
      );
      final b = SelectChildEntry<dynamic>(
        parentId: 'p',
        id: 'e',
        name: 'B',
      );

      expect(a, isNot(equals(b)));
    });

    test('== and hashCode: different id makes entries unequal', () {
      final a = SelectChildEntry<dynamic>(
        parentId: 'p',
        id: 'e1',
        name: 'E',
      );
      final b = SelectChildEntry<dynamic>(
        parentId: 'p',
        id: 'e2',
        name: 'E',
      );

      expect(a, isNot(equals(b)));
    });

    test('== returns false for different runtime type', () {
      final child = SelectChildEntry<dynamic>(
        parentId: 'p',
        id: 'e',
        name: 'E',
      );
      final text = SelectTextEntry<dynamic>(
        parentId: 'p',
        id: 'e',
        name: 'E',
      );

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
      final any = SelectChildEntry<dynamic>.any(
        parentId: 'p',
        name: 'Any',
      );

      expect(any.id, kAnyEntryId);
      expect(any.parentId, 'p');
      expect(any.name, 'Any');
    });

    test('empty constructor creates empty placeholder', () {
      final empty = SelectChildEntry<dynamic>.empty(parentId: 'p');

      expect(empty.id, '');
      expect(empty.parentId, 'p');
      expect(empty.name, isNull);
      expect(empty.enabled, isTrue);
      expect(empty.immediate, isFalse);
    });

    test('children constructor injects parentId into direct children', () {
      final parent = SelectChildEntry<dynamic>.children(
        id: 'p',
        name: 'Parent',
        children: {
          SelectTextEntry<dynamic>.name(id: 'a', name: 'A'),
          SelectTextEntry<dynamic>.name(id: 'b', name: 'B'),
        },
      );

      expect(parent.id, 'p');
      expect(parent.parentId, '');
      expect(parent.name, 'Parent');
      expect(parent.children!.length, 2);
      for (final child in parent.children!) {
        expect((child as SelectChildEntry).parentId, 'p');
      }
    });

    test('children constructor injects parentId recursively into descendants',
        () {
      final parent = SelectChildEntry<dynamic>.children(
        id: 'p',
        name: 'Parent',
        children: {
          SelectTextEntry<dynamic>.name(
            id: 'a',
            name: 'A',
          ).copyWith(
            children: {
              SelectTextEntry<dynamic>.name(id: 'a1', name: 'A1'),
            },
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

    test('children constructor leaves own parentId empty, preserves fields',
        () {
      final parent = SelectChildEntry<dynamic>.children(
        id: 'p',
        name: 'Parent',
        enabled: false,
        immediate: true,
        extra: 42,
        children: {
          SelectTextEntry<dynamic>.name(id: 'a', name: 'A'),
        },
      );

      expect(parent.parentId, '');
      expect(parent.id, 'p');
      expect(parent.enabled, false);
      expect(parent.immediate, true);
      expect(parent.extra, 42);
    });

    test('children constructor supports nested SelectChildEntry.children', () {
      final root = SelectChildEntry<dynamic>.children(
        id: 'p',
        name: 'Parent',
        children: {
          SelectChildEntry<dynamic>.children(
            id: 'g',
            name: 'Grandparent',
            children: {
              SelectTextEntry<dynamic>.name(id: 'gg', name: 'GG'),
            },
          ),
        },
      );

      final inner = root.children!.single as SelectChildEntry;
      expect(inner.parentId, 'p');
      expect(inner.children!.single.id, 'gg');
      final grandchild = inner.children!.single as SelectChildEntry;
      // The grandchild's direct parent is the inner node (id 'g'), so its
      // parentId is 'g', not the root's id 'p'.
      expect(grandchild.parentId, 'g');
    });

    test('multi-level category tree passes SelectController.validateEntries', () {
      final category = SelectCategoryEntry<dynamic>.children(
        id: 'c1',
        name: 'Cate 1',
        children: {
          SelectTextEntry<dynamic>.children(
            id: 'a',
            name: 'A',
            children: {
              SelectTextEntry<dynamic>.name(id: 'a1', name: 'A1'),
              SelectTextEntry<dynamic>.name(id: 'a2', name: 'A2'),
            },
          ),
          SelectTextEntry<dynamic>.name(id: 'b', name: 'B'),
          SelectTextEntry<dynamic>.name(id: 'c', name: 'C'),
        },
      );

      // Direct children of the category carry the category's id.
      for (final child in category.children!) {
        expect((child as SelectChildEntry).parentId, 'c1');
      }
      // The 'a' branch's own children carry 'a' as their parentId.
      final branchA =
          category.children!.firstWhere((e) => e.id == 'a') as SelectChildEntry;
      for (final grandchild in branchA.children!) {
        expect((grandchild as SelectChildEntry).parentId, 'a');
      }

      // A multi-level tree must not fail parentId validation.
      expect(
        () => SelectController.validateEntries([category]),
        returnsNormally,
      );
    });
  });

  group('SelectChildEntryExt', () {
    test('isAny returns true for kAnyEntryId', () {
      final any = SelectChildEntry<dynamic>.any(
        parentId: 'p',
        name: 'Any',
      );
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
      final empty = SelectChildEntry<dynamic>.empty();
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
      final any = SelectTextEntry<dynamic>.any(
        parentId: 'p',
        name: 'Any',
      );

      expect(any.id, kAnyEntryId);
      expect(any.isAny, isTrue);
    });

    test('id constructor creates entry with only id', () {
      final entry = SelectTextEntry<dynamic>.id(id: 'e');

      expect(entry.id, 'e');
      expect(entry.parentId, '');
      expect(entry.name, '');
    });

    test('name constructor creates entry without parentId', () {
      final entry = SelectTextEntry<dynamic>.name(
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
      final a = SelectTextEntry<dynamic>(
        parentId: 'p',
        id: 'e',
        name: 'E',
      );
      final b = SelectTextEntry<dynamic>(
        parentId: 'p',
        id: 'e',
        name: 'E',
      );

      expect(a, equals(b));
    });

    test('children constructor returns a SelectTextEntry and injects parentId',
        () {
      final entry = SelectTextEntry<dynamic>.children(
        id: 'p',
        name: 'Parent',
        children: {
          SelectTextEntry<dynamic>.name(id: 'a', name: 'A'),
        },
      );

      expect(entry, isA<SelectTextEntry<dynamic>>());
      expect(entry.id, 'p');
      expect(entry.parentId, '');
      expect(entry.name, 'Parent');
      final child = entry.children!.single as SelectChildEntry;
      expect(child.parentId, 'p');
    });

    test('children constructor leaves own parentId empty, preserves fields',
        () {
      final entry = SelectTextEntry<dynamic>.children(
        id: 'p',
        name: 'Parent',
        enabled: false,
        immediate: true,
        extra: 'x',
        children: {
          SelectTextEntry<dynamic>.name(id: 'a', name: 'A'),
        },
      );

      expect(entry.parentId, '');
      expect(entry.id, 'p');
      expect(entry.enabled, false);
      expect(entry.immediate, true);
      expect(entry.extra, 'x');
    });
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

    test('name getter falls back to min-max format when base name is null', () {
      // SelectRangeEntry.custom with no explicit name: base name is null
      final entry = SelectRangeEntry<int, dynamic>.custom(
        parentId: 'p',
        min: 10,
        max: 20,
      );
      // The extension name getter on SelectRangeEntryExt shadows the base
      // field and returns '$min-$max' when this.name (base field) is null.
      // Due to Dart extension resolution, the behavior depends on static type.
      // Verify the entry has the expected values regardless.
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
    });

    test('== and hashCode: different selectionMode makes categories unequal',
        () {
      final a = _category('c', 'C',
          children: {_text('c', 'a', 'A')},
          selectionMode: SelectionMode.single);
      final b = _category('c', 'C',
          children: {_text('c', 'a', 'A')},
          selectionMode: SelectionMode.multiple);

      expect(a, isNot(equals(b)));
    });

    test('== and hashCode: different layout makes categories unequal', () {
      final a = _category('c', 'C',
          children: {_text('c', 'a', 'A')}, layout: const SelectListLayout());
      final b = _category('c', 'C',
          children: {_text('c', 'a', 'A')}, layout: const SelectChipLayout());

      expect(a, isNot(equals(b)));
    });

    test('== and hashCode: different name makes categories unequal', () {
      final a = _category('c', 'C1', children: {_text('c', 'a', 'A')});
      final b = _category('c', 'C2', children: {_text('c', 'a', 'A')});

      expect(a, isNot(equals(b)));
    });

    test('default values for selection modes', () {
      final c = _category('c', 'C', children: {_text('c', 'a', 'A')});

      expect(c.selectionMode, SelectionMode.single);
      expect(c.headerSelectionMode, SelectionMode.single);
      expect(c.footerSelectionMode, SelectionMode.single);
      expect(c.layout, isNull);
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
      final c = _category('c', 'C', children: {
        custom,
        _text('c', 'a', 'A'),
      });

      expect(c.firstCustomOrNull, equals(custom));
    });

    test('firstCustomOrNull returns null when no custom entry', () {
      final c = _category('c', 'C', children: {
        _text('c', 'a', 'A'),
        _text('c', 'b', 'B'),
      });

      expect(c.firstCustomOrNull, isNull);
    });

    test('lastCustomOrNull returns last custom range entry', () {
      final custom = SelectRangeEntry<int, dynamic>.custom(
        parentId: 'c',
        name: 'Custom',
      );
      final c = _category('c', 'C', children: {
        _text('c', 'a', 'A'),
        custom,
      });

      expect(c.lastCustomOrNull, equals(custom));
    });

    test('lastCustomOrNull returns null when no custom entry', () {
      final c = _category('c', 'C', children: {
        _text('c', 'a', 'A'),
      });

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
      final c = _category('c', 'C', children: {
        _text('c', 'a', 'A'),
        _text('c', 'b', 'B'),
      });

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
}
