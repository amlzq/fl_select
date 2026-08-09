import 'package:fl_select/fl_select.dart';
import 'package:fl_select/src/select/state/state_tree.dart';
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
  group('StateTree – bind', () {
    test('bind returns true for new entries', () {
      final tree = StateTree();
      final a = _text('c', 'a', 'A');
      final c = _category('c', 'C', children: {a});
      expect(tree.bind([c], initializeAnyIfEmpty: false), isTrue);
    });

    test('bind returns false for identical entries', () {
      final tree = StateTree();
      final a = _text('c', 'a', 'A');
      final c = _category('c', 'C', children: {a});
      tree.bind([c], initializeAnyIfEmpty: false);
      expect(tree.bind([c], initializeAnyIfEmpty: false), isFalse);
    });

    test('bind returns true when previousSelected changes', () {
      final tree = StateTree();
      final a = _text('c', 'a', 'A');
      final c = _category('c', 'C', children: {a});
      tree.bind([c], initializeAnyIfEmpty: false);
      expect(
        tree.bind([c], initializeAnyIfEmpty: false, previousSelected: {a}),
        isTrue,
      );
    });

    test('bind returns true when resetSelected changes', () {
      final tree = StateTree();
      final a = _text('c', 'a', 'A');
      final c = _category('c', 'C', children: {a});
      tree.bind([c], initializeAnyIfEmpty: false);
      expect(
        tree.bind([c], initializeAnyIfEmpty: false, resetSelected: {a}),
        isTrue,
      );
    });
  });

  group('StateTree – ensureLevels / trimLevels', () {
    test('ensureLevels expands selected entries per level', () {
      final tree = StateTree();
      tree.ensureLevels(3);
      expect(tree.levelCount, 3);
      expect(tree.selectedEntriesAtLevel(0), isEmpty);
      expect(tree.selectedEntriesAtLevel(2), isEmpty);
    });

    test('trimLevels reduces selected entries per level', () {
      final tree = StateTree();
      tree.ensureLevels(3);
      tree.trimLevels(1);
      expect(tree.levelCount, 1);
    });

    test('trimLevels with count 0 clears all', () {
      final tree = StateTree();
      tree.ensureLevels(3);
      tree.trimLevels(0);
      expect(tree.levelCount, 0);
    });
  });

  group('StateTree – trimTrailingEmptyLevels', () {
    test('removes trailing empty levels', () {
      final tree = StateTree();
      tree.ensureLevels(3);
      tree.mutableSelectedEntriesAtLevel(0).add(
            _category('c', 'C', children: {_text('c', 'a', 'A')}),
          );
      tree.trimTrailingEmptyLevels();
      expect(tree.levelCount, 1);
    });

    test('does not remove non-empty trailing levels', () {
      final tree = StateTree();
      tree.ensureLevels(2);
      tree.mutableSelectedEntriesAtLevel(0).add(
            _category('c', 'C', children: {_text('c', 'a', 'A')}),
          );
      tree.mutableSelectedEntriesAtLevel(1).add(_text('c', 'a', 'A'));
      tree.trimTrailingEmptyLevels();
      expect(tree.levelCount, 2);
    });

    test('does nothing when all levels are non-empty', () {
      final tree = StateTree();
      final any = SelectTextEntry<dynamic>.any(parentId: 'c', name: 'Any');
      final a = _text('c', 'a', 'A');
      final c = _category('c', 'C', children: {any, a});
      tree.bind([c], initializeAnyIfEmpty: true);
      tree.trimTrailingEmptyLevels();
      // initializeAnyIfEmpty on a category tree with Any creates at least 2 levels
      expect(tree.levelCount, greaterThanOrEqualTo(1));
    });
  });

  group('StateTree – clearSelections', () {
    test('clears all selected entries and header/footer selections', () {
      final tree = StateTree();
      final a = _text('c', 'a', 'A');
      final c = _category('c', 'C', children: {a});
      tree.bind([c], initializeAnyIfEmpty: false);
      tree.ensureLevels(2);
      tree.mutableSelectedEntriesAtLevel(0).add(c);
      tree.mutableSelectedEntriesAtLevel(1).add(a);
      tree.mutableHeaderEntriesFor('c').add(a);
      tree.mutableFooterEntriesFor('c').add(a);

      tree.clearSelections();
      expect(tree.levelCount, 0);
      expect(tree.selectedHeaderEntriesFor('c'), isEmpty);
      expect(tree.selectedFooterEntriesFor('c'), isEmpty);
    });
  });

  group('StateTree – snapshot', () {
    test('snapshot returns an independent copy', () {
      final tree = StateTree();
      final a = _text('c', 'a', 'A');
      final c = _category('c', 'C', children: {a});
      tree.bind([c], initializeAnyIfEmpty: false);
      tree.ensureLevels(1);
      tree.mutableSelectedEntriesAtLevel(0).add(c);

      final snapshot = tree.snapshot;
      expect(snapshot.selectedEntriesPerLevel[0].contains(c), isTrue);

      // Mutating snapshot should not affect tree
      snapshot.selectedEntriesPerLevel[0].clear();
      expect(tree.selectedEntriesAtLevel(0).contains(c), isTrue);
    });

    test('snapshot copies header and footer selections', () {
      final tree = StateTree();
      final a = _text('c', 'a', 'A');
      final c = _category('c', 'C', children: {a});
      tree.bind([c], initializeAnyIfEmpty: false);
      tree.mutableHeaderEntriesFor('c').add(a);
      tree.mutableFooterEntriesFor('c').add(a);

      final snapshot = tree.snapshot;
      expect(snapshot.selectedHeaderEntries['c']?.contains(a), isTrue);
      expect(snapshot.selectedFooterEntries['c']?.contains(a), isTrue);
    });
  });

  group('StateTree – findEntry', () {
    test('finds entry by id', () {
      final tree = StateTree();
      final a = _text('c', 'a', 'A');
      final c = _category('c', 'C', children: {a});
      tree.bind([c], initializeAnyIfEmpty: false);

      expect(tree.findEntry('c'), equals(c));
      expect(tree.findEntry('a'), equals(a));
    });

    test('finds entry by id and parentId', () {
      final tree = StateTree();
      final a = _text('c', 'a', 'A');
      final c = _category('c', 'C', children: {a});
      tree.bind([c], initializeAnyIfEmpty: false);

      expect(tree.findEntry('a', parentId: 'c'), equals(a));
      expect(tree.findEntry('a', parentId: 'nonexistent'), isNull);
    });

    test('returns null for non-existent id', () {
      final tree = StateTree();
      tree.bind([], initializeAnyIfEmpty: false);
      expect(tree.findEntry('missing'), isNull);
    });

    test('finds entry in nested tree', () {
      final tree = StateTree();
      final leaf = _text('p', 'l', 'L');
      final parent = _text('c', 'p', 'P', children: {leaf});
      final c = _category('c', 'C', children: {parent});
      tree.bind([c], initializeAnyIfEmpty: false);

      expect(tree.findEntry('l'), equals(leaf));
    });
  });

  group('StateTree – findCategory', () {
    test('finds category by id', () {
      final tree = StateTree();
      final c = _category('c', 'C', children: {_text('c', 'a', 'A')});
      tree.bind([c], initializeAnyIfEmpty: false);

      expect(tree.findCategory('c'), equals(c));
      expect(tree.findCategory('a'), isNull);
    });

    test('returns null for non-category entry', () {
      final tree = StateTree();
      final a = _text('c', 'a', 'A');
      final c = _category('c', 'C', children: {a});
      tree.bind([c], initializeAnyIfEmpty: false);

      expect(tree.findCategory('a'), isNull);
    });
  });

  group('StateTree – findPath', () {
    test('returns path for a flat entry', () {
      final tree = StateTree();
      final a = _text('c', 'a', 'A');
      final c = _category('c', 'C', children: {a});
      tree.bind([c], initializeAnyIfEmpty: false);

      final path = tree.findPath('a');
      expect(path, isNotNull);
      expect(path!.map((e) => e.id).toList(), ['c', 'a']);
    });

    test('returns path for nested cascading entry', () {
      final tree = StateTree();
      final leaf = _text('p', 'l', 'L');
      final parent = _text('c', 'p', 'P', children: {leaf});
      final c = _category('c', 'C', children: {parent});
      tree.bind([c], initializeAnyIfEmpty: false);

      final path = tree.findPath('l');
      expect(path, isNotNull);
      expect(path!.map((e) => e.id).toList(), ['c', 'p', 'l']);
    });

    test('returns null for non-existent id', () {
      final tree = StateTree();
      final c = _category('c', 'C', children: {_text('c', 'a', 'A')});
      tree.bind([c], initializeAnyIfEmpty: false);

      expect(tree.findPath('missing'), isNull);
    });

    test('returns null when entries are empty', () {
      final tree = StateTree();
      expect(tree.findPath('any'), isNull);
    });

    test('finds path with parentId disambiguation', () {
      final tree = StateTree();
      final a1 = _text('c1', 'a', 'A1');
      final a2 = _text('c2', 'a', 'A2');
      final c1 = _category('c1', 'C1', children: {a1});
      final c2 = _category('c2', 'C2', children: {a2});
      tree.bind([c1, c2], initializeAnyIfEmpty: false);

      final path1 = tree.findPath('a', parentId: 'c1');
      expect(path1, isNotNull);
      expect(path1!.map((e) => e.id).toList(), ['c1', 'a']);

      final path2 = tree.findPath('a', parentId: 'c2');
      expect(path2, isNotNull);
      expect(path2!.map((e) => e.id).toList(), ['c2', 'a']);
    });

    test('finds path through header', () {
      final tree = StateTree();
      final hChild = _text('header', 'hc', 'HC');
      final header = _text('c', 'header', 'Header', children: {hChild});
      final c = _category(
        'c',
        'C',
        children: {_text('c', 'a', 'A')},
        header: header,
      );
      tree.bind([c], initializeAnyIfEmpty: false);

      final path = tree.findPath('hc');
      expect(path, isNotNull);
      expect(path!.map((e) => e.id).toList(), ['c', 'header', 'hc']);
    });
  });

  group('StateTree – selectedEntries queries', () {
    test('selectedEntriesAtLevel returns entries at specific level', () {
      final tree = StateTree();
      final a = _text('c', 'a', 'A');
      final c = _category('c', 'C', children: {a});
      tree.bind([c], initializeAnyIfEmpty: false);
      tree.ensureLevels(2);
      tree.mutableSelectedEntriesAtLevel(0).add(c);
      tree.mutableSelectedEntriesAtLevel(1).add(a);

      expect(tree.selectedEntriesAtLevel(0).contains(c), isTrue);
      expect(tree.selectedEntriesAtLevel(1).contains(a), isTrue);
      expect(tree.selectedEntriesAtLevel(99), isEmpty);
    });

    test('selectedEntriesForParent filters by parentId', () {
      final tree = StateTree();
      final a1 = _text('c1', 'a1', 'A1');
      final a2 = _text('c2', 'a2', 'A2');
      final c1 = _category('c1', 'C1', children: {a1});
      final c2 = _category('c2', 'C2', children: {a2});
      tree.bind([c1, c2], initializeAnyIfEmpty: false);
      tree.ensureLevels(2);
      tree.mutableSelectedEntriesAtLevel(1).add(a1);
      tree.mutableSelectedEntriesAtLevel(1).add(a2);

      expect(
        tree.selectedEntriesForParent('c1', level: 1).contains(a1),
        isTrue,
      );
      expect(
        tree.selectedEntriesForParent('c2', level: 1).contains(a2),
        isTrue,
      );
      expect(
        tree.selectedEntriesForParent('c1', level: 1).contains(a2),
        isFalse,
      );
    });

    test('selectedHeaderEntriesFor returns header selections', () {
      final tree = StateTree();
      tree.mutableHeaderEntriesFor('c').add(_text('c', 'h', 'H'));
      expect(tree.selectedHeaderEntriesFor('c').length, 1);
      expect(tree.selectedHeaderEntriesFor('missing'), isEmpty);
    });

    test('selectedFooterEntriesFor returns footer selections', () {
      final tree = StateTree();
      tree.mutableFooterEntriesFor('c').add(_text('c', 'f', 'F'));
      expect(tree.selectedFooterEntriesFor('c').length, 1);
      expect(tree.selectedFooterEntriesFor('missing'), isEmpty);
    });
  });

  group('StateTree – _initializeAnySelection', () {
    test(
        'initializes Any entries for category tree when initializeAnyIfEmpty is true',
        () {
      final tree = StateTree();
      final any = SelectTextEntry<dynamic>.any(parentId: 'c', name: 'Any');
      final a = _text('c', 'a', 'A');
      final c = _category('c', 'C', children: {any, a});
      tree.bind([c], initializeAnyIfEmpty: true);

      expect(tree.selectedEntriesAtLevel(0).contains(c), isTrue);
      expect(tree.selectedEntriesAtLevel(1).contains(any), isTrue);
    });

    test('does not initialize Any when initializeAnyIfEmpty is false', () {
      final tree = StateTree();
      final a = _text('c', 'a', 'A');
      final c = _category('c', 'C', children: {a});
      tree.bind([c], initializeAnyIfEmpty: false);

      expect(tree.selectedEntriesAtLevel(0), isEmpty);
    });

    test('initializes Any for flat tree when no category entries', () {
      final tree = StateTree();
      final any = SelectTextEntry<dynamic>.any(parentId: '', name: 'Any');
      final a = _text('', 'a', 'A');
      tree.bind([any, a], initializeAnyIfEmpty: true);

      expect(tree.selectedEntriesAtLevel(0).contains(any), isTrue);
    });

    test('does nothing for empty entries', () {
      final tree = StateTree();
      tree.bind([], initializeAnyIfEmpty: true);
      expect(tree.selectedEntriesAtLevel(0), isEmpty);
    });
  });

  group('StateTree – _restoreSelections with previousSelected', () {
    test('restores previously selected entries', () {
      final tree = StateTree();
      final a = _text('c', 'a', 'A');
      final c = _category('c', 'C', children: {a});

      // previousSelected must contain a category entry with its selected
      // children so restorePreviousSelected can rebuild the tree.
      final selectedCategory = SelectCategoryEntry<dynamic>(
        id: 'c',
        name: 'C',
        children: {a},
      );
      tree.bind([c],
          initializeAnyIfEmpty: false, previousSelected: {selectedCategory});

      expect(tree.selectedEntriesAtLevel(0).contains(c), isTrue);
      expect(tree.selectedEntriesAtLevel(1).contains(a), isTrue);
    });

    test('restores cascading selections', () {
      final tree = StateTree();
      final leaf = _text('p', 'l', 'L');
      final parent = _text('c', 'p', 'P', children: {leaf});
      final c = _category('c', 'C', children: {parent});

      // previousSelected must contain a category entry with nested children
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
      tree.bind([c],
          initializeAnyIfEmpty: false, previousSelected: {selectedCategory});

      expect(tree.selectedEntriesAtLevel(0).contains(c), isTrue);
      expect(tree.selectedEntriesAtLevel(1).contains(parent), isTrue);
      expect(tree.selectedEntriesAtLevel(2).contains(leaf), isTrue);
    });

    test(
        'falls back to Any when previousSelected is empty and initializeAnyIfEmpty is true',
        () {
      final tree = StateTree();
      final any = SelectTextEntry<dynamic>.any(parentId: 'c', name: 'Any');
      final a = _text('c', 'a', 'A');
      final c = _category('c', 'C', children: {any, a});
      tree.bind([c], initializeAnyIfEmpty: true, previousSelected: {});

      expect(tree.selectedEntriesAtLevel(0).contains(c), isTrue);
      expect(tree.selectedEntriesAtLevel(1).contains(any), isTrue);
    });
  });

  group('StateTree – reset', () {
    test('reset restores resetSelected entries', () {
      final tree = StateTree();
      final a = _text('c', 'a', 'A');
      final b = _text('c', 'b', 'B');
      final c = _category('c', 'C', children: {a, b});

      // First bind with a selected via a category entry
      final selectedWithA = SelectCategoryEntry<dynamic>(
        id: 'c',
        name: 'C',
        children: {a},
      );
      tree.bind([c],
          initializeAnyIfEmpty: false, previousSelected: {selectedWithA});
      expect(tree.selectedEntriesAtLevel(1).contains(a), isTrue);

      // Reset with b via a category entry
      final selectedWithB = SelectCategoryEntry<dynamic>(
        id: 'c',
        name: 'C',
        children: {b},
      );
      tree.bind([c],
          initializeAnyIfEmpty: false,
          previousSelected: {selectedWithA},
          resetSelected: {selectedWithB});
      tree.reset(initializeAnyIfEmpty: false);

      expect(tree.selectedEntriesAtLevel(0).contains(c), isTrue);
      expect(tree.selectedEntriesAtLevel(1).contains(b), isTrue);
      expect(tree.selectedEntriesAtLevel(1).contains(a), isFalse);
    });

    test('resetCategory resets only the target category, keeping others', () {
      final tree = StateTree();
      final a1 = _text('c1', 'a1', 'A1');
      final b1 = _text('c1', 'b1', 'B1');
      final a2 = _text('c2', 'a2', 'A2');
      final c1 = _category('c1', 'C1', children: {a1, b1});
      final c2 = _category('c2', 'C2', children: {a2});
      tree.bind([c1, c2], initializeAnyIfEmpty: false);

      // Simulate: C1 has {a1, b1} selected, C2 has {a2} selected.
      tree.mutableSelectedEntriesAtLevel(0).addAll({c1, c2});
      tree.mutableSelectedEntriesAtLevel(1).addAll({a1, b1, a2});

      // Reset only C1.
      tree.resetCategory(c1, initializeAnyIfEmpty: false);

      // C1's children are cleared and C1 is removed from root selection.
      expect(tree.selectedEntriesAtLevel(1).contains(a1), isFalse);
      expect(tree.selectedEntriesAtLevel(1).contains(b1), isFalse);
      expect(tree.selectedEntriesAtLevel(0).contains(c1), isFalse);

      // C2's selection is preserved.
      expect(tree.selectedEntriesAtLevel(1).contains(a2), isTrue);
      expect(tree.selectedEntriesAtLevel(0).contains(c2), isTrue);
    });

    test(
        'resetCategory restores the Any child when initializeAnyIfEmpty is true',
        () {
      final tree = StateTree();
      final any = SelectTextEntry<dynamic>.any(parentId: 'c', name: 'Any');
      final a = _text('c', 'a', 'A');
      final c = _category('c', 'C', children: {any, a});
      tree.bind([c], initializeAnyIfEmpty: false);

      // Select the concrete child.
      tree.mutableSelectedEntriesAtLevel(0).add(c);
      tree.mutableSelectedEntriesAtLevel(1).add(a);

      tree.resetCategory(c, initializeAnyIfEmpty: true);

      // The concrete child is replaced by the Any entry as the default.
      expect(tree.selectedEntriesAtLevel(1).contains(a), isFalse);
      expect(tree.selectedEntriesAtLevel(1).contains(any), isTrue);
      expect(tree.selectedEntriesAtLevel(0).contains(c), isTrue);
    });
  });

  group('StateTree – _restoreHeaderFooterSelected', () {
    test('restores header selections from previousSelected', () {
      final tree = StateTree();
      final h1 = _text('header', 'h1', 'H1');
      final header = _text('c', 'header', 'Header', children: {h1});
      final c = _category(
        'c',
        'C',
        children: {_text('c', 'a', 'A')},
        header: header,
      );

      // Create a category entry with header children that are selected
      final selectedHeader = _text('header', 'h1', 'H1');
      final selectedCategory = SelectCategoryEntry<dynamic>(
        id: 'c',
        name: 'C',
        children: {},
        header: SelectTextEntry<dynamic>(
          parentId: 'c',
          id: 'header',
          name: 'Header',
          children: {selectedHeader},
        ),
      );
      tree.bind([c],
          initializeAnyIfEmpty: false, previousSelected: {selectedCategory});
      expect(
          tree.selectedHeaderEntriesFor('c').map((e) => e.id).toSet(), {'h1'});
    });

    test('restores footer selections from previousSelected', () {
      final tree = StateTree();
      final f1 = _text('footer', 'f1', 'F1');
      final footer = _text('c', 'footer', 'Footer', children: {f1});
      final c = _category(
        'c',
        'C',
        children: {_text('c', 'a', 'A')},
        footer: footer,
      );

      final selectedFooter = _text('footer', 'f1', 'F1');
      final selectedCategory = SelectCategoryEntry<dynamic>(
        id: 'c',
        name: 'C',
        children: {},
        footer: SelectTextEntry<dynamic>(
          parentId: 'c',
          id: 'footer',
          name: 'Footer',
          children: {selectedFooter},
        ),
      );
      tree.bind([c],
          initializeAnyIfEmpty: false, previousSelected: {selectedCategory});
      expect(
          tree.selectedFooterEntriesFor('c').map((e) => e.id).toSet(), {'f1'});
    });
  });

  group('StateTree – buildChangedEntries / buildAppliedEntries', () {
    test(
        'buildChangedEntries returns selected tree with deepCloneSelectedSubtree=false',
        () {
      final tree = StateTree();
      final a = _text('c', 'a', 'A');
      final c = _category('c', 'C', children: {a});
      tree.bind([c], initializeAnyIfEmpty: false);
      tree.mutableSelectedEntriesAtLevel(0).add(c);
      tree.mutableSelectedEntriesAtLevel(1).add(a);

      final changed = tree.buildChangedEntries();
      expect(changed.length, 1);
      final resultC = changed.first;
      expect(resultC.id, 'c');
    });

    test('buildAppliedEntries returns selected tree with full deep clone', () {
      final tree = StateTree();
      final a = _text('c', 'a', 'A');
      final c = _category('c', 'C', children: {a});
      tree.bind([c], initializeAnyIfEmpty: false);
      tree.mutableSelectedEntriesAtLevel(0).add(c);
      tree.mutableSelectedEntriesAtLevel(1).add(a);

      final applied = tree.buildAppliedEntries();
      expect(applied.length, 1);
      final resultC = applied.first;
      expect(resultC.id, 'c');
    });

    test('returns empty set when nothing is selected', () {
      final tree = StateTree();
      final a = _text('c', 'a', 'A');
      final c = _category('c', 'C', children: {a});
      tree.bind([c], initializeAnyIfEmpty: false);

      expect(tree.buildChangedEntries(), isEmpty);
      expect(tree.buildAppliedEntries(), isEmpty);
    });
  });

  group('StateTree – previousSelected / resetSelected', () {
    test('previousSelected getter returns bound value', () {
      final tree = StateTree();
      final a = _text('c', 'a', 'A');
      final c = _category('c', 'C', children: {a});
      tree.bind([c], initializeAnyIfEmpty: false, previousSelected: {a});
      expect(tree.previousSelected, isNotNull);
      expect(tree.previousSelected!.contains(a), isTrue);
    });

    test('resetSelected getter returns bound value', () {
      final tree = StateTree();
      final a = _text('c', 'a', 'A');
      final c = _category('c', 'C', children: {a});
      tree.bind([c], initializeAnyIfEmpty: false, resetSelected: {a});
      expect(tree.resetSelected, isNotNull);
      expect(tree.resetSelected!.contains(a), isTrue);
    });

    test('previousSelected is null when not provided', () {
      final tree = StateTree();
      final c = _category('c', 'C', children: {_text('c', 'a', 'A')});
      tree.bind([c], initializeAnyIfEmpty: false);
      expect(tree.previousSelected, isNull);
    });
  });
}
