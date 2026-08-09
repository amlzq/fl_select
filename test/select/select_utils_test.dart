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

SelectRangeEntry<int, dynamic> _customRange(
  String parentId, {
  int? min,
  int? max,
  String? name,
}) {
  return SelectRangeEntry<int, dynamic>.custom(
    parentId: parentId,
    name: name,
    min: min,
    max: max,
  );
}

SelectCategoryEntry<dynamic> _category(
  String id,
  String name, {
  required Set<SelectEntry<dynamic>> children,
  SelectEntry<dynamic>? header,
  SelectEntry<dynamic>? footer,
  SelectionMode selectionMode = SelectionMode.single,
}) {
  return SelectCategoryEntry<dynamic>(
    id: id,
    name: name,
    selectionMode: selectionMode,
    children: children,
    header: header,
    footer: footer,
  );
}

void main() {
  group('SelectUtils.find*AtLevel', () {
    test('findChildrenAtLevel/findIdsAtLevel/findExtrasAtLevel work for leafs',
        () {
      final root = _text('', 'root', 'Root');

      expect(SelectUtils.findChildrenAtLevel(root, 0), {root});
      expect(SelectUtils.findChildrenAtLevel(root, 1), isEmpty);

      expect(SelectUtils.findIdsAtLevel(root, 0), {'root'});
      expect(SelectUtils.findIdsAtLevel(root, 1), isEmpty);

      expect(SelectUtils.findExtrasAtLevel<dynamic>(root, 0), [null]);
      expect(SelectUtils.findExtrasAtLevel<dynamic>(root, 1), isEmpty);
    });

    test('find*AtLevel traverses correctly', () {
      final a1 = SelectChildEntry<dynamic>(
        parentId: 'a',
        id: 'a1',
        name: 'A1',
        extra: 'ea1',
      );
      final a2 = SelectChildEntry<dynamic>(
        parentId: 'a',
        id: 'a2',
        name: 'A2',
        extra: 'ea2',
      );
      final a = SelectChildEntry<dynamic>(
        parentId: 'root',
        id: 'a',
        name: 'A',
        extra: 'ea',
        children: {a1, a2},
      );
      final b = SelectChildEntry<dynamic>(
        parentId: 'root',
        id: 'b',
        name: 'B',
        extra: 'eb',
      );
      final root = _category('root', 'Root', children: {a, b});

      expect(SelectUtils.findIdsAtLevel(root, 1), {'a', 'b'});
      expect(SelectUtils.findIdsAtLevel(root, 2), {'a1', 'a2'});
      expect(SelectUtils.findChildrenAtLevel(root, 2), containsAll({a1, a2}));
      expect(
        SelectUtils.findExtrasAtLevel<String>(root, 2),
        containsAll(<String>['ea1', 'ea2']),
      );
    });
  });

  group('SelectUtils.flattenTree/treeDepth', () {
    test('flattenTree returns per-level sets in BFS order', () {
      final c1 = _text('r', 'c1', 'C1');
      final c2 = _text('r', 'c2', 'C2', children: {_text('c2', 'g1', 'G1')});
      final root = _category('r', 'R', children: {c1, c2});

      final levels = SelectUtils.flattenTree(root);
      expect(levels.length, 3);
      expect(levels[0], {root});
      expect(levels[1], containsAll({c1, c2}));
      expect(levels[2].map((e) => e.id).toSet(), {'g1'});

      expect(SelectUtils().treeDepth(root), 3);
      expect(SelectUtils().treeDepth(null), 1);
    });
  });

  group('SelectUtils.removeAnyEntries/deepCloneEntries', () {
    test('removeAnyEntries removes "any" at all levels without cloning', () {
      final any = SelectChildEntry<dynamic>.any(parentId: 'r', name: 'Any');
      final leafAny =
          SelectChildEntry<dynamic>.any(parentId: 'a', name: 'AnyLeaf');
      final a = _text('r', 'a', 'A', children: {leafAny, _text('a', 'x', 'X')});
      final root = _category('r', 'R', children: {any, a});

      final entries = <SelectEntry<dynamic>>{root};
      SelectUtils.removeAnyEntries(entries);

      final rootAfter = entries.single as SelectCategoryEntry<dynamic>;
      expect(rootAfter.children!.any((e) => e is SelectChildEntry && e.isAny),
          isFalse);
      final aAfter = rootAfter.children!.singleWhere((e) => e.id == 'a')
          as SelectTextEntry;
      expect(
        aAfter.children!.any((e) => e is SelectChildEntry && e.isAny),
        isFalse,
      );
    });

    test('deepCloneEntries creates deep copies and can skip any', () {
      final any = SelectChildEntry<dynamic>.any(parentId: 'r', name: 'Any');
      final leaf = _text('r', 'a', 'A', children: {_text('a', 'x', 'X')});
      final root = _category('r', 'R', children: {any, leaf});

      final clonedAll = SelectUtils.deepCloneEntries({root});
      expect(clonedAll.length, 1);
      expect(identical(clonedAll.single, root), isFalse);

      final clonedSkipAny = SelectUtils.deepCloneEntries({root}, skipAny: true);
      final clonedRoot = clonedSkipAny.single as SelectCategoryEntry<dynamic>;
      expect(
        clonedRoot.children!.any((e) => e is SelectChildEntry && e.isAny),
        isFalse,
      );

      final originalLeaf =
          (root.children!.singleWhere((e) => e.id == 'a') as SelectTextEntry);
      final clonedLeaf = (clonedRoot.children!.singleWhere((e) => e.id == 'a')
          as SelectTextEntry);
      expect(identical(originalLeaf, clonedLeaf), isFalse);
      expect(
        identical(originalLeaf.children!.first, clonedLeaf.children!.first),
        isFalse,
      );
    });
  });

  group('SelectUtils.clippingTree/cloneTree', () {
    test('clippingTree prunes unselected nodes and header/footer children', () {
      final c1 = _text('r', 'c1', 'C1', children: {_text('c1', 'c1a', 'C1A')});
      final c2 = _text('r', 'c2', 'C2', children: {_text('c2', 'c2a', 'C2A')});

      final h1 = _text('header', 'h1', 'H1');
      final h2 = _text('header', 'h2', 'H2');
      final header = _text('r', 'header', 'Header', children: {h1, h2});

      final f1 = _text('footer', 'f1', 'F1');
      final f2 = _text('footer', 'f2', 'F2');
      final footer = _text('r', 'footer', 'Footer', children: {f1, f2});

      final root = _category(
        'r',
        'R',
        children: {c1, c2},
        header: header,
        footer: footer,
      );

      final entries = <SelectEntry<dynamic>>{root};

      SelectUtils.clippingTree(
        entries,
        [
          <SelectEntry<dynamic>>{_category('r', 'R', children: {})},
          <SelectEntry<dynamic>>{_text('r', 'c2', 'C2')},
        ],
        0,
        {
          'r': <SelectEntry<dynamic>>{_text('header', 'h2', 'H2')},
        },
        {
          'r': <SelectEntry<dynamic>>{_text('footer', 'f1', 'F1')},
        },
      );

      final rootAfter = entries.single as SelectCategoryEntry<dynamic>;
      expect(rootAfter.children!.map((e) => e.id).toSet(), {'c2'});
      expect(rootAfter.header!.children!.map((e) => e.id).toSet(), {'h2'});
      expect(rootAfter.footer!.children!.map((e) => e.id).toSet(), {'f1'});
    });

    test('cloneTree clones only selected branches', () {
      final g1 = _text('c1', 'g1', 'G1');
      final g2 = _text('c1', 'g2', 'G2');
      final c1 = _text('r', 'c1', 'C1', children: {g1, g2});
      final c2 = _text('r', 'c2', 'C2');
      final root = _category('r', 'R', children: {c1, c2});

      final cloned = SelectUtils.cloneTree(
        {root},
        [
          <SelectEntry<dynamic>>{_category('r', 'R', children: {})},
          <SelectEntry<dynamic>>{_text('r', 'c1', 'C1')},
          <SelectEntry<dynamic>>{_text('c1', 'g2', 'G2')},
        ],
      );

      final clonedRoot = cloned.single as SelectCategoryEntry<dynamic>;
      expect(clonedRoot.children!.map((e) => e.id).toSet(), {'c1'});
      final clonedC1 = clonedRoot.children!.single as SelectTextEntry<dynamic>;
      expect(clonedC1.children!.map((e) => e.id).toSet(), {'g2'});
      expect(identical(clonedRoot, root), isFalse);
    });

    test(
        'cloneTree can avoid cloning deep subtree when deepCloneSelectedSubtree=false',
        () {
      final g1 = _text('c1', 'g1', 'G1');
      final c1 = _text('r', 'c1', 'C1', children: {g1});
      final root = _category('r', 'R', children: {c1});

      final cloned = SelectUtils.cloneTree(
        {root},
        [
          <SelectEntry<dynamic>>{_category('r', 'R', children: {})},
          <SelectEntry<dynamic>>{_text('r', 'c1', 'C1')},
        ],
        deepCloneSelectedSubtree: false,
      );

      final clonedRoot = cloned.single as SelectCategoryEntry<dynamic>;
      final clonedC1 = clonedRoot.children!.single as SelectTextEntry<dynamic>;
      expect(clonedC1.children, isNull);
    });
  });

  group('SelectUtils.getResultLabel', () {
    test('returns leaf name for a single path', () {
      final leaf = _text('c', 'l', 'Leaf');
      final child = _text('r', 'c', 'Child', children: {leaf});
      final root = _category('r', 'Root', children: {child});

      expect(SelectUtils.getResultLabel({root}, 'Leaf'), 'Leaf');
    });

    test('returns parent name for "any" leaf (except when parent is category)',
        () {
      final any = SelectChildEntry<dynamic>.any(parentId: 'c', name: 'Any');
      final child = _text('r', 'c', 'Child', children: {any});
      final root = _category('r', 'Root', children: {child});

      expect(SelectUtils.getResultLabel({root}, 'Child'), 'Child');
    });

    test('returns Multiple when multiple valid labels exist', () {
      final p1 = _text('r', 'p1', 'P1', children: {_text('p1', 'l1', 'L1')});
      final p2 = _text('r', 'p2', 'P2', children: {_text('p2', 'l2', 'L2')});
      final root = _category('r', 'Root', children: {p1, p2});

      expect(SelectUtils.getResultLabel({root}, 'Multiple'), 'Multiple');
    });
  });

  group('SelectUtils.restorePreviousSelected', () {
    test('matches by id and restores custom range values', () {
      final customInItems = _customRange('r', name: 'Custom', min: 0, max: 0);
      final items = <SelectEntry<dynamic>>{customInItems}.toList();

      final previousCustom =
          _customRange('r', name: 'Custom', min: 10, max: 20);
      final restored =
          SelectUtils.restorePreviousSelected(items, {previousCustom});

      expect(restored.length, 1);
      final selected = restored[0].single as SelectRangeEntry<int, dynamic>;
      expect(selected.isCustom, isTrue);
      expect(selected.min, 10);
      expect(selected.max, 20);
    });
  });
}
