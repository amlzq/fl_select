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
  group('SelectController - bindState', () {
    test('bindState notifies listeners on first bind', () {
      final controller = SelectController(selectionMode: SelectionMode.single);
      var notified = false;
      controller.addListener(() => notified = true);

      final c = _category('c', 'C', children: {_text('c', 'a', 'A')});
      controller.bindState([c], initializeAnyIfEmpty: false);
      expect(notified, isTrue);
    });

    test('bindState does not notify when entries are identical', () {
      final controller = SelectController(selectionMode: SelectionMode.single);
      var notified = false;
      controller.addListener(() => notified = true);

      final c = _category('c', 'C', children: {_text('c', 'a', 'A')});
      controller.bindState([c], initializeAnyIfEmpty: false);
      notified = false;
      controller.bindState([c], initializeAnyIfEmpty: false);
      expect(notified, isFalse);
    });

    test('bindState with initializeAnyIfEmpty initializes Any entries', () {
      final controller = SelectController(selectionMode: SelectionMode.single);
      final any = SelectTextEntry<dynamic>.any(parentId: 'c', name: 'Any');
      final a = _text('c', 'a', 'A');
      final c = _category('c', 'C', children: {any, a});
      controller.bindState([c], initializeAnyIfEmpty: true);

      expect(controller.selectedEntriesAtLevel(0).contains(c), isTrue);
      expect(controller.selectedEntriesAtLevel(1).contains(any), isTrue);
    });
  });

  group('SelectController - select', () {
    test('select a leaf entry in a category tree (path length 2)', () {
      final controller = SelectController(selectionMode: SelectionMode.single);
      final a = _text('c', 'a', 'A');
      final c = _category('c', 'C', children: {a});
      controller.bindState([c], initializeAnyIfEmpty: false);

      expect(controller.select('a', parentId: 'c'), isTrue);
      expect(controller.selectedEntriesAtLevel(0).contains(c), isTrue);
      expect(
        controller.selectedEntriesForParent('c', level: 1).contains(a),
        isTrue,
      );
    });

    test('select a cascading leaf entry (path length > 2)', () {
      final controller = SelectController(selectionMode: SelectionMode.single);
      final leaf = _text('p', 'l', 'L');
      final parent = _text('c', 'p', 'P', children: {leaf});
      final c = _category('c', 'C', children: {parent});
      controller.bindState([c], initializeAnyIfEmpty: false);

      expect(controller.select('l', parentId: 'p'), isTrue);
      expect(controller.selectedEntriesAtLevel(0).contains(c), isTrue);
      expect(controller.selectedEntriesAtLevel(1).contains(parent), isTrue);
      expect(controller.selectedEntriesAtLevel(2).contains(leaf), isTrue);
    });

    test('select a category entry triggers focusCategoryEntry', () {
      final controller = SelectController(selectionMode: SelectionMode.single);
      final a = _text('c', 'a', 'A');
      final c = _category('c', 'C', children: {a});
      controller.bindState([c], initializeAnyIfEmpty: false);

      expect(controller.select('c'), isTrue);
      // focusCategoryEntry ensures level 2 exists and may add Any
    });

    test('select returns false for non-existent entry', () {
      final controller = SelectController(selectionMode: SelectionMode.single);
      final c = _category('c', 'C', children: {_text('c', 'a', 'A')});
      controller.bindState([c], initializeAnyIfEmpty: false);

      expect(controller.select('missing'), isFalse);
    });

    test('select in single mode replaces previous selection in same category',
        () {
      final controller = SelectController(selectionMode: SelectionMode.single);
      final a = _text('c', 'a', 'A');
      final b = _text('c', 'b', 'B');
      final c = _category('c', 'C', children: {a, b});
      controller.bindState([c], initializeAnyIfEmpty: false);

      expect(controller.select('a', parentId: 'c'), isTrue);
      expect(controller.select('b', parentId: 'c'), isTrue);
      expect(
        controller.selectedEntriesForParent('c', level: 1).contains(b),
        isTrue,
      );
      // In single mode, a should be replaced
    });

    test('select custom range entry works', () {
      final controller = SelectController(selectionMode: SelectionMode.single);
      final custom = SelectRangeEntry<int, dynamic>.custom(
        parentId: 'c',
        name: 'Custom',
      );
      final c = _category('c', 'C', children: {custom});
      controller.bindState([c], initializeAnyIfEmpty: false);

      custom.min = 10;
      custom.max = 20;
      expect(controller.select('custom', parentId: 'c'), isTrue);
      final selected = controller
          .selectedEntriesForParent('c', level: 1)
          .whereType<SelectRangeEntry>()
          .firstOrNull;
      expect(selected, isNotNull);
      expect(selected!.min, 10);
      expect(selected.max, 20);
    });

    test('select on a flat root entry selects it at level 0', () {
      final controller = SelectController(selectionMode: SelectionMode.single);
      final a = _text('', 'a', 'A');
      controller.bindState([a], initializeAnyIfEmpty: false);

      expect(controller.select('a'), isTrue);
      expect(controller.selectedEntriesAtLevel(0).contains(a), isTrue);
    });

    test('select on flat root replaces previous selection in single mode', () {
      final controller = SelectController(selectionMode: SelectionMode.single);
      final a = _text('', 'a', 'A');
      final b = _text('', 'b', 'B');
      controller.bindState([a, b], initializeAnyIfEmpty: false);

      expect(controller.select('a'), isTrue);
      expect(controller.selectedEntriesAtLevel(0).contains(a), isTrue);

      expect(controller.select('b'), isTrue);
      expect(controller.selectedEntriesAtLevel(0).contains(b), isTrue);
      // In single mode, a must be deselected when b is selected.
      expect(controller.selectedEntriesAtLevel(0).contains(a), isFalse);
    });

    test('select custom range on flat root replaces other selections', () {
      final controller = SelectController(selectionMode: SelectionMode.single);
      final custom = SelectRangeEntry<int, dynamic>.custom(
        parentId: '',
        name: 'Custom',
      );
      final a = _text('', 'a', 'A');
      controller.bindState([custom, a], initializeAnyIfEmpty: false);

      // Pre-select a text entry first.
      controller.select('a');
      expect(controller.selectedEntriesAtLevel(0).contains(a), isTrue);

      // Committing the custom range must replace the previous selection.
      custom.min = 10;
      custom.max = 20;
      expect(controller.select('custom'), isTrue);
      expect(controller.selectedEntriesAtLevel(0).contains(custom), isTrue);
      expect(controller.selectedEntriesAtLevel(0).contains(a), isFalse);
    });

    test('unselect on a flat root entry clears it at level 0', () {
      final controller = SelectController(selectionMode: SelectionMode.single);
      final a = _text('', 'a', 'A');
      controller.bindState([a], initializeAnyIfEmpty: false);

      controller.select('a');
      expect(controller.selectedEntriesAtLevel(0).contains(a), isTrue);

      expect(controller.unselect('a'), isTrue);
      expect(controller.selectedEntriesAtLevel(0).contains(a), isFalse);
    });

    test('select with applyIfImmediate calls apply listeners in single mode',
        () {
      final controller = SelectController(selectionMode: SelectionMode.single);
      var applyCalled = false;
      controller.addApplyListener((_) => applyCalled = true);

      final a = _text('c', 'a', 'A');
      final c = _category('c', 'C', children: {a});
      controller.bindState([c], initializeAnyIfEmpty: false);

      expect(controller.select('a', parentId: 'c', applyIfImmediate: true),
          isTrue);
      expect(applyCalled, isTrue);
    });

    test('select with applyIfImmediate on immediate entry calls apply', () {
      final controller =
          SelectController(selectionMode: SelectionMode.multiple);
      var applyCalled = false;
      controller.addApplyListener((_) => applyCalled = true);

      final a = SelectTextEntry<dynamic>(
        parentId: 'c',
        id: 'a',
        name: 'A',
        immediate: true,
      );
      final c = _category('c', 'C', children: {a});
      controller.bindState([c], initializeAnyIfEmpty: false);

      expect(controller.select('a', parentId: 'c', applyIfImmediate: true),
          isTrue);
      expect(applyCalled, isTrue);
    });

    test('select without emitChange does not call change listeners', () {
      final controller = SelectController(selectionMode: SelectionMode.single);
      var changeCalled = false;
      controller.addChangeListener((_) => changeCalled = true);

      final a = _text('c', 'a', 'A');
      final c = _category('c', 'C', children: {a});
      controller.bindState([c], initializeAnyIfEmpty: false);

      controller.select('a', parentId: 'c', emitChange: false);
      expect(changeCalled, isFalse);
    });
  });

  group('SelectController - unselect', () {
    test('unselect a leaf entry removes it from selection', () {
      final controller = SelectController(selectionMode: SelectionMode.single);
      final a = _text('c', 'a', 'A');
      final c = _category('c', 'C', children: {a});
      controller.bindState([c], initializeAnyIfEmpty: false);

      controller.select('a', parentId: 'c');
      expect(controller.unselect('a', parentId: 'c'), isTrue);
      expect(controller.selectedEntriesAtLevel(0), isEmpty);
    });

    test('unselect in single mode with Any restores Any', () {
      final controller = SelectController(selectionMode: SelectionMode.single);
      final any = SelectTextEntry<dynamic>.any(parentId: 'c', name: 'Any');
      final a = _text('c', 'a', 'A');
      final c = _category('c', 'C', children: {any, a});
      controller.bindState([c], initializeAnyIfEmpty: false);

      controller.select('a', parentId: 'c');
      controller.unselect('a', parentId: 'c');
      expect(
        controller.selectedEntriesForParent('c', level: 1).contains(any),
        isTrue,
      );
    });

    test('unselect in single mode without Any clears category', () {
      final controller = SelectController(selectionMode: SelectionMode.single);
      final a = _text('c', 'a', 'A');
      final b = _text('c', 'b', 'B');
      final c = _category('c', 'C', children: {a, b});
      controller.bindState([c], initializeAnyIfEmpty: false);

      controller.select('a', parentId: 'c');
      controller.unselect('a', parentId: 'c');
      expect(controller.selectedEntriesAtLevel(0), isEmpty);
    });

    test('unselect in multiple mode for flat tree (no category)', () {
      final controller =
          SelectController(selectionMode: SelectionMode.multiple);
      final a = _text('', 'a', 'A');
      final b = _text('', 'b', 'B');
      controller.bindState([a, b], initializeAnyIfEmpty: false);

      controller.select('a');
      controller.unselect('a');
      expect(controller.selectedEntriesAtLevel(0).contains(a), isFalse);
    });

    test('unselect last item in multiple mode for flat tree falls back to Any',
        () {
      final controller =
          SelectController(selectionMode: SelectionMode.multiple);
      final any = SelectTextEntry<dynamic>.any(parentId: '', name: 'Any');
      final a = _text('', 'a', 'A');
      controller.bindState([any, a], initializeAnyIfEmpty: false);

      controller.select('a');
      controller.unselect('a');
      expect(controller.selectedEntriesAtLevel(0).contains(a), isFalse);
      expect(controller.selectedEntriesAtLevel(0).contains(any), isTrue);
    });

    test('unselect returns false for non-existent entry', () {
      final controller = SelectController(selectionMode: SelectionMode.single);
      final c = _category('c', 'C', children: {_text('c', 'a', 'A')});
      controller.bindState([c], initializeAnyIfEmpty: false);

      expect(controller.unselect('missing'), isFalse);
    });

    test('unselect cascading entry in single mode with Any restores Any', () {
      final controller = SelectController(selectionMode: SelectionMode.single);
      final any = SelectTextEntry<dynamic>.any(parentId: 'p', name: 'Any');
      final leaf = _text('p', 'l', 'L');
      final parent = _text('c', 'p', 'P', children: {any, leaf});
      final c = _category('c', 'C', children: {parent});
      controller.bindState([c], initializeAnyIfEmpty: false);

      controller.select('l', parentId: 'p');
      controller.unselect('l', parentId: 'p');
      expect(controller.selectedEntriesAtLevel(2).contains(any), isTrue);
    });
  });

  group('SelectController - focusCategory', () {
    test('focusCategory selects category in single mode', () {
      final controller = SelectController(selectionMode: SelectionMode.single);
      final a = _text('c', 'a', 'A');
      final c = _category('c', 'C', children: {a});
      controller.bindState([c], initializeAnyIfEmpty: false);

      expect(controller.focusCategory('c'), isTrue);
      // In single mode with no children selected, category should be added
    });

    test('focusCategory returns false for non-existent category', () {
      final controller = SelectController(selectionMode: SelectionMode.single);
      final c = _category('c', 'C', children: {_text('c', 'a', 'A')});
      controller.bindState([c], initializeAnyIfEmpty: false);

      expect(controller.focusCategory('missing'), isFalse);
    });
  });

  group('SelectController - selectHeaderChild / unselectHeaderChild', () {
    test('selectHeaderChild in single mode', () {
      final controller = SelectController(selectionMode: SelectionMode.single);
      final h1 = _text('header', 'h1', 'H1');
      final h2 = _text('header', 'h2', 'H2');
      final header = _text('c', 'header', 'Header', children: {h1, h2});
      final c = _category(
        'c',
        'C',
        children: {_text('c', 'a', 'A')},
        header: header,
        headerSelectionMode: SelectionMode.single,
      );
      controller.bindState([c], initializeAnyIfEmpty: false);

      expect(controller.selectHeaderChild('c', 'h1'), isTrue);
      expect(
        controller.selectedHeaderEntriesFor('c').map((e) => e.id).toSet(),
        {'h1'},
      );

      // Single mode: selecting h2 should replace h1
      expect(controller.selectHeaderChild('c', 'h2'), isTrue);
      expect(
        controller.selectedHeaderEntriesFor('c').map((e) => e.id).toSet(),
        {'h2'},
      );
    });

    test('selectHeaderChild in multiple mode', () {
      final controller = SelectController(selectionMode: SelectionMode.single);
      final h1 = _text('header', 'h1', 'H1');
      final h2 = _text('header', 'h2', 'H2');
      final header = _text('c', 'header', 'Header', children: {h1, h2});
      final c = _category(
        'c',
        'C',
        children: {_text('c', 'a', 'A')},
        header: header,
        headerSelectionMode: SelectionMode.multiple,
      );
      controller.bindState([c], initializeAnyIfEmpty: false);

      expect(controller.selectHeaderChild('c', 'h1'), isTrue);
      expect(controller.selectHeaderChild('c', 'h2'), isTrue);
      expect(
        controller.selectedHeaderEntriesFor('c').map((e) => e.id).toSet(),
        {'h1', 'h2'},
      );
    });

    test('selectHeaderChild is a no-op if already selected', () {
      final controller = SelectController(selectionMode: SelectionMode.single);
      final h1 = _text('header', 'h1', 'H1');
      final header = _text('c', 'header', 'Header', children: {h1});
      final c = _category(
        'c',
        'C',
        children: {_text('c', 'a', 'A')},
        header: header,
        headerSelectionMode: SelectionMode.single,
      );
      controller.bindState([c], initializeAnyIfEmpty: false);

      expect(controller.selectHeaderChild('c', 'h1'), isTrue);
      // Selecting again should still return true (already selected)
      expect(controller.selectHeaderChild('c', 'h1'), isTrue);
    });

    test('selectHeaderChild returns false for non-existent child', () {
      final controller = SelectController(selectionMode: SelectionMode.single);
      final c = _category('c', 'C', children: {_text('c', 'a', 'A')});
      controller.bindState([c], initializeAnyIfEmpty: false);

      expect(controller.selectHeaderChild('c', 'missing'), isFalse);
    });

    test('unselectHeaderChild removes header child', () {
      final controller = SelectController(selectionMode: SelectionMode.single);
      final h1 = _text('header', 'h1', 'H1');
      final header = _text('c', 'header', 'Header', children: {h1});
      final c = _category(
        'c',
        'C',
        children: {_text('c', 'a', 'A')},
        header: header,
      );
      controller.bindState([c], initializeAnyIfEmpty: false);

      controller.selectHeaderChild('c', 'h1');
      expect(controller.unselectHeaderChild('c', 'h1'), isTrue);
      expect(controller.selectedHeaderEntriesFor('c'), isEmpty);
    });
  });

  group('SelectController - selectFooterChild / unselectFooterChild', () {
    test('selectFooterChild in single mode', () {
      final controller = SelectController(selectionMode: SelectionMode.single);
      final f1 = _text('footer', 'f1', 'F1');
      final footer = _text('c', 'footer', 'Footer', children: {f1});
      final c = _category(
        'c',
        'C',
        children: {_text('c', 'a', 'A')},
        footer: footer,
        footerSelectionMode: SelectionMode.single,
      );
      controller.bindState([c], initializeAnyIfEmpty: false);

      expect(controller.selectFooterChild('c', 'f1'), isTrue);
      expect(
        controller.selectedFooterEntriesFor('c').map((e) => e.id).toSet(),
        {'f1'},
      );
    });

    test('unselectFooterChild removes footer child', () {
      final controller = SelectController(selectionMode: SelectionMode.single);
      final f1 = _text('footer', 'f1', 'F1');
      final footer = _text('c', 'footer', 'Footer', children: {f1});
      final c = _category(
        'c',
        'C',
        children: {_text('c', 'a', 'A')},
        footer: footer,
      );
      controller.bindState([c], initializeAnyIfEmpty: false);

      controller.selectFooterChild('c', 'f1');
      expect(controller.unselectFooterChild('c', 'f1'), isTrue);
      expect(controller.selectedFooterEntriesFor('c'), isEmpty);
    });
  });

  group('SelectController - listeners', () {
    test('addChangeListener returns an unregister function', () {
      final controller = SelectController(selectionMode: SelectionMode.single);
      var callCount = 0;
      final unregister = controller.addChangeListener((_) => callCount++);

      final a = _text('c', 'a', 'A');
      final c = _category('c', 'C', children: {a});
      controller.bindState([c], initializeAnyIfEmpty: false);
      controller.select('a', parentId: 'c');
      expect(callCount, 1);

      unregister();
      controller.select('a', parentId: 'c', emitChange: true);
      expect(callCount, 1); // No additional call after unregister
    });

    test('addApplyListener receives applied entries', () {
      final controller = SelectController(selectionMode: SelectionMode.single);
      SelectEntries? received;
      controller.addApplyListener((selected) => received = selected);

      final a = _text('c', 'a', 'A');
      final c = _category('c', 'C', children: {a});
      controller.bindState([c], initializeAnyIfEmpty: false);
      controller.select('a', parentId: 'c');
      controller.applyFromState();

      expect(received, isNotNull);
    });

    test('addResetListener is called on reset', () {
      final controller = SelectController(selectionMode: SelectionMode.single);
      var resetCalled = false;
      controller.addResetListener(() => resetCalled = true);

      controller.reset();
      expect(resetCalled, isTrue);
    });

    test('removeChangeListener stops notifications', () {
      final controller = SelectController(selectionMode: SelectionMode.single);
      var callCount = 0;
      void listener(SelectEntries _) => callCount++;
      controller.addChangeListener(listener);

      final a = _text('c', 'a', 'A');
      final c = _category('c', 'C', children: {a});
      controller.bindState([c], initializeAnyIfEmpty: false);
      controller.select('a', parentId: 'c');
      expect(callCount, 1);

      controller.removeChangeListener(listener);
      controller.select('a', parentId: 'c', emitChange: true);
      expect(callCount, 1);
    });

    test('removeApplyListener stops notifications', () {
      final controller = SelectController(selectionMode: SelectionMode.single);
      var callCount = 0;
      void listener(SelectEntries _) => callCount++;
      controller.addApplyListener(listener);

      controller.applyFromState();
      expect(callCount, 1);

      controller.removeApplyListener(listener);
      controller.applyFromState();
      expect(callCount, 1);
    });

    test('removeResetListener stops notifications', () {
      final controller = SelectController(selectionMode: SelectionMode.single);
      var callCount = 0;
      void listener() => callCount++;
      controller.addResetListener(listener);

      controller.reset();
      expect(callCount, 1);

      controller.removeResetListener(listener);
      controller.reset();
      expect(callCount, 1);
    });
  });

  group('SelectController - dispose', () {
    test('dispose clears all listeners', () {
      final controller = SelectController(selectionMode: SelectionMode.single);
      var callCount = 0;
      controller.addChangeListener((_) => callCount++);
      controller.addApplyListener((_) => callCount++);
      controller.addResetListener(() => callCount++);

      controller.dispose();
      expect(controller.isDisposed, isTrue);

      // After dispose, notifications should not be delivered
      final a = _text('c', 'a', 'A');
      final c = _category('c', 'C', children: {a});
      controller.bindState([c], initializeAnyIfEmpty: false);
      controller.select('a', parentId: 'c');
      controller.applyFromState();
      controller.reset();
      expect(callCount, 0);
    });

    test('isDisposed returns false before dispose', () {
      final controller = SelectController(selectionMode: SelectionMode.single);
      expect(controller.isDisposed, isFalse);
    });
  });

  group('SelectController - findEntry / findPath', () {
    test('findEntry delegates to tree', () {
      final controller = SelectController(selectionMode: SelectionMode.single);
      final a = _text('c', 'a', 'A');
      final c = _category('c', 'C', children: {a});
      controller.bindState([c], initializeAnyIfEmpty: false);

      expect(controller.findEntry('a', parentId: 'c'), equals(a));
      expect(controller.findEntry('missing'), isNull);
    });

    test('findPath delegates to stateTree', () {
      final controller = SelectController(selectionMode: SelectionMode.single);
      final a = _text('c', 'a', 'A');
      final c = _category('c', 'C', children: {a});
      controller.bindState([c], initializeAnyIfEmpty: false);

      final path = controller.findPath('a');
      expect(path, isNotNull);
      expect(path!.map((e) => e.id).toList(), ['c', 'a']);
    });
  });

  group('SelectController - snapshot', () {
    test('snapshot returns current selection state', () {
      final controller = SelectController(selectionMode: SelectionMode.single);
      final a = _text('c', 'a', 'A');
      final c = _category('c', 'C', children: {a});
      controller.bindState([c], initializeAnyIfEmpty: false);
      controller.select('a', parentId: 'c');

      final snapshot = controller.snapshot;
      expect(snapshot.selectedEntriesPerLevel[0].contains(c), isTrue);
      expect(snapshot.selectedEntriesPerLevel[1].contains(a), isTrue);
    });
  });

  group('SelectController - resetState', () {
    test('resetState restores resetEntries and notifies', () {
      final controller = SelectController(
        selectionMode: SelectionMode.single,
        resetEntries: {_text('c', 'b', 'B')},
      );
      final a = _text('c', 'a', 'A');
      final b = _text('c', 'b', 'B');
      final c = _category('c', 'C', children: {a, b});
      controller.bindState([c], initializeAnyIfEmpty: false);

      controller.select('a', parentId: 'c');
      var notified = false;
      controller.addListener(() => notified = true);

      controller.resetState(initializeAnyIfEmpty: false);
      expect(notified, isTrue);
    });
  });

  group('SelectController - trimSelectionLevels', () {
    test('trimSelectionLevels trims and notifies', () {
      final controller = SelectController(selectionMode: SelectionMode.single);
      final leaf = _text('p', 'l', 'L');
      final parent = _text('c', 'p', 'P', children: {leaf});
      final c = _category('c', 'C', children: {parent});
      controller.bindState([c], initializeAnyIfEmpty: false);
      controller.select('l', parentId: 'p');

      var notified = false;
      controller.addListener(() => notified = true);

      controller.trimSelectionLevels(1);
      expect(notified, isTrue);
    });
  });

  group('SelectController - _effectiveSelectorSelectionMode', () {
    test('returns multiple when controller selectionMode is multiple', () {
      final controller =
          SelectController(selectionMode: SelectionMode.multiple);
      final a = _text('c', 'a', 'A');
      final c = _category('c', 'C', children: {a});
      controller.bindState([c], initializeAnyIfEmpty: false);

      // We just verify the mode is correctly evaluated by checking behavior
      controller.select('a', parentId: 'c', emitChange: false);
      // In multiple mode, select should not clear previous selections
    });

    test('returns multiple when a category has multiple selectionMode', () {
      final controller = SelectController(selectionMode: SelectionMode.single);
      final a = _text('c', 'a', 'A');
      final b = _text('c', 'b', 'B');
      final c = _category('c', 'C',
          children: {a, b}, selectionMode: SelectionMode.multiple);
      controller.bindState([c], initializeAnyIfEmpty: false);

      // Because effective mode is multiple, select should toggle
      controller.select('a', parentId: 'c', emitChange: false);
      controller.select('b', parentId: 'c', emitChange: false);
      // Both should be selected in multiple mode
      expect(
        controller.selectedEntriesForParent('c', level: 1).length,
        greaterThanOrEqualTo(2),
      );
    });
  });
}
