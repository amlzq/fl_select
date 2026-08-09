import 'package:collection/collection.dart';

import '../constants.dart';
import '../select_entry.dart';
import '../select_utils.dart';
import 'state_snapshot.dart';

class StateTree {
  final ListEquality<SelectEntry> _entryListEquality = const ListEquality();
  final SetEquality<SelectEntry> _entrySetEquality = const SetEquality();

  List<SelectEntry> _entries = const [];
  final Map<String, List<SelectEntry>> _idIndex = {};
  SelectEntries? _previousSelected;
  SelectEntries? _resetSelected;

  final List<SelectEntries> _selectedEntriesPerLevel = [];
  final Map<String, SelectEntries> _selectedHeaderEntries = {};
  final Map<String, SelectEntries> _selectedFooterEntries = {};

  List<SelectEntry> get entries => _entries;

  SelectEntries? get previousSelected => _previousSelected;

  SelectEntries? get resetSelected => _resetSelected;

  int get levelCount => _selectedEntriesPerLevel.length;

  StateSnapshot get snapshot => StateSnapshot(
        selectedEntriesPerLevel:
            _selectedEntriesPerLevel.map((e) => {...e}).toList(),
        selectedHeaderEntries:
            _selectedHeaderEntries.map((k, v) => MapEntry(k, {...v})),
        selectedFooterEntries:
            _selectedFooterEntries.map((k, v) => MapEntry(k, {...v})),
      );

  bool bind(
    List<SelectEntry> entries, {
    SelectEntries? previousSelected,
    SelectEntries? resetSelected,
    required bool initializeAnyIfEmpty,
  }) {
    final isSameEntries = _entryListEquality.equals(_entries, entries);
    final isSamePrevious = _entrySetEquality.equals(
        _previousSelected ?? {}, previousSelected ?? {});
    final isSameReset =
        _entrySetEquality.equals(_resetSelected ?? {}, resetSelected ?? {});
    if (isSameEntries && isSamePrevious && isSameReset) {
      return false;
    }

    _entries = entries;
    _rebuildIdIndex();
    _previousSelected = previousSelected;
    _resetSelected = resetSelected;
    _restoreSelections(previousSelected,
        initializeAnyIfEmpty: initializeAnyIfEmpty);
    return true;
  }

  void reset({required bool initializeAnyIfEmpty}) {
    _restoreSelections(_resetSelected,
        initializeAnyIfEmpty: initializeAnyIfEmpty);
  }

  /// Resets the selection of a single [category] without touching the other
  /// categories in the tree.
  ///
  /// Used by tabbed selects (e.g. [GridSelect]) where tapping "Reset" should
  /// clear only the currently focused category's selection while leaving the
  /// remaining tabs untouched.
  ///
  /// The category's selected children are removed, its header/footer
  /// selections are dropped, and it is removed from the root selection. When
  /// [initializeAnyIfEmpty] is true and the category owns an "Any" child, that
  /// child is restored as the default selection (matching the behaviour of
  /// [reset] for the whole tree).
  void resetCategory(
    SelectCategoryEntry category, {
    required bool initializeAnyIfEmpty,
  }) {
    // Drop the category from the root selection (level 0).
    _selectedEntriesPerLevel.elementAtOrNull(0)?.remove(category);

    // Clear the category's selected children at level 1.
    final level1 = _selectedEntriesPerLevel.elementAtOrNull(1);
    if (level1 != null) {
      level1.removeWhere(
        (e) => e is SelectChildEntry && e.parentId == category.id,
      );
    }

    // Clear this category's header / footer selections.
    _selectedHeaderEntries.remove(category.id);
    _selectedFooterEntries.remove(category.id);

    if (!initializeAnyIfEmpty) return;

    // Restore the default "Any" selection for this category, mirroring
    // [_initializeAnySelection].
    final anyItem = category.children?.singleWhereOrNull(testAnyElement);
    if (anyItem == null) return;
    ensureLevels(2);
    final selectedChildren = _selectedEntriesPerLevel[1];
    selectedChildren.removeWhere(
      (e) => e is SelectChildEntry && e.parentId == category.id,
    );
    selectedChildren.add(anyItem);
    _selectedEntriesPerLevel[0].add(category);
  }

  SelectEntries selectedEntriesAtLevel(int level) {
    return _selectedEntriesPerLevel.elementAtOrNull(level) ?? {};
  }

  SelectEntries selectedEntriesForParent(String parentId,
      {required int level}) {
    return selectedEntriesAtLevel(level)
        .whereType<SelectChildEntry>()
        .where((entry) => entry.parentId == parentId)
        .toSet();
  }

  SelectEntries selectedHeaderEntriesFor(String categoryId) {
    return _selectedHeaderEntries[categoryId] ?? {};
  }

  SelectEntries selectedFooterEntriesFor(String categoryId) {
    return _selectedFooterEntries[categoryId] ?? {};
  }

  void ensureLevels(int count) {
    while (_selectedEntriesPerLevel.length < count) {
      _selectedEntriesPerLevel.add({});
    }
  }

  void trimLevels(int count) {
    while (_selectedEntriesPerLevel.length > count) {
      _selectedEntriesPerLevel.removeLast();
    }
  }

  void trimTrailingEmptyLevels() {
    while (_selectedEntriesPerLevel.isNotEmpty &&
        _selectedEntriesPerLevel.last.isEmpty) {
      _selectedEntriesPerLevel.removeLast();
    }
  }

  void clearSelections() {
    _selectedEntriesPerLevel.clear();
    _selectedHeaderEntries.clear();
    _selectedFooterEntries.clear();
  }

  SelectEntries mutableSelectedEntriesAtLevel(int level) {
    ensureLevels(level + 1);
    return _selectedEntriesPerLevel[level];
  }

  SelectEntries mutableHeaderEntriesFor(String categoryId) {
    return _selectedHeaderEntries.putIfAbsent(
        categoryId, () => <SelectEntry>{});
  }

  SelectEntries mutableFooterEntriesFor(String categoryId) {
    return _selectedFooterEntries.putIfAbsent(
        categoryId, () => <SelectEntry>{});
  }

  SelectEntries buildChangedEntries() {
    return SelectUtils.cloneTree(
      _entries,
      _selectedEntriesPerLevel,
      deepCloneSelectedSubtree: false,
      selectedHeaderEntries: _selectedHeaderEntries,
      selectedFooterEntries: _selectedFooterEntries,
    );
  }

  SelectEntries buildAppliedEntries() {
    return SelectUtils.cloneTree(
      _entries,
      _selectedEntriesPerLevel,
      selectedHeaderEntries: _selectedHeaderEntries,
      selectedFooterEntries: _selectedFooterEntries,
    );
  }

  SelectEntry? findEntry(String id, {String? parentId}) {
    final candidates = _idIndex[id];
    if (candidates == null || candidates.isEmpty) return null;
    if (parentId == null) return candidates.first;
    for (final entry in candidates) {
      if (entry is SelectChildEntry && entry.parentId == parentId) {
        return entry;
      }
    }
    return null;
  }

  SelectCategoryEntry? findCategory(String categoryId) {
    final entry = findEntry(categoryId);
    if (entry is SelectCategoryEntry) return entry;
    return null;
  }

  List<SelectEntry>? findPath(String id, {String? parentId}) {
    if (_entries.isEmpty) return null;

    List<SelectEntry>? result;

    bool visit(SelectEntry entry, List<SelectEntry> stack) {
      final nextStack = [...stack, entry];
      if (entry.id == id) {
        if (parentId == null) {
          result = nextStack;
          return true;
        }
        if (entry is SelectChildEntry && entry.parentId == parentId) {
          result = nextStack;
          return true;
        }
      }

      if (entry is SelectCategoryEntry) {
        final header = entry.header;
        if (header != null && visit(header, nextStack)) return true;
        final footer = entry.footer;
        if (footer != null && visit(footer, nextStack)) return true;
      }

      final children = entry.children;
      if (children != null) {
        for (final child in children) {
          if (visit(child, nextStack)) return true;
        }
      }
      return false;
    }

    for (final root in _entries) {
      if (visit(root, const [])) break;
    }
    return result;
  }

  void _restoreSelections(
    SelectEntries? selected, {
    required bool initializeAnyIfEmpty,
  }) {
    clearSelections();
    if (selected?.isNotEmpty == true) {
      _selectedEntriesPerLevel.addAll(
        SelectUtils.restorePreviousSelected(_entries, selected),
      );
      _restoreHeaderFooterSelected(_entries, selected!);
      return;
    }

    if (!initializeAnyIfEmpty) {
      return;
    }

    _initializeAnySelection();
  }

  void _rebuildIdIndex() {
    _idIndex.clear();
    void add(SelectEntry entry) {
      _idIndex.putIfAbsent(entry.id, () => []).add(entry);
      if (entry is SelectCategoryEntry) {
        final header = entry.header;
        if (header != null) add(header);
        final footer = entry.footer;
        if (footer != null) add(footer);
      }
      final children = entry.children;
      if (children != null) {
        for (final child in children) {
          add(child);
        }
      }
    }

    for (final entry in _entries) {
      add(entry);
    }
  }

  void _initializeAnySelection() {
    if (_entries.isEmpty) return;

    if (_entries.first is SelectCategoryEntry) {
      ensureLevels(2);
      for (final category in _entries.whereType<SelectCategoryEntry>()) {
        final anyItem = category.children?.singleWhereOrNull(testAnyElement);
        if (anyItem == null) continue;
        _selectedEntriesPerLevel[0].add(category);
        _selectedEntriesPerLevel[1].add(anyItem);
      }
      return;
    }

    ensureLevels(1);
    final anyItem = _entries.singleWhereOrNull(testAnyElement);
    if (anyItem != null) {
      _selectedEntriesPerLevel[0].add(anyItem);
    }
  }

  void _restoreHeaderFooterSelected(
    List<SelectEntry> entries,
    Set<SelectEntry> selected,
  ) {
    final categories = entries.whereType<SelectCategoryEntry>().toList();
    for (final selectedEntry in selected) {
      if (selectedEntry is! SelectCategoryEntry) continue;
      final category =
          categories.singleWhereOrNull((e) => e.id == selectedEntry.id);
      if (category == null) continue;

      final selectedHeaderChildren = selectedEntry.header?.children ?? {};
      if (selectedHeaderChildren.isNotEmpty) {
        final restoredHeader = mutableHeaderEntriesFor(category.id);
        restoredHeader.clear();
        for (final selectedChild in selectedHeaderChildren) {
          final match = category.header?.children
              ?.singleWhereOrNull((e) => e.id == selectedChild.id);
          if (match != null) restoredHeader.add(match);
        }
      }

      final selectedFooterChildren = selectedEntry.footer?.children ?? {};
      if (selectedFooterChildren.isNotEmpty) {
        final restoredFooter = mutableFooterEntriesFor(category.id);
        restoredFooter.clear();
        for (final selectedChild in selectedFooterChildren) {
          final match = category.footer?.children
              ?.singleWhereOrNull((e) => e.id == selectedChild.id);
          if (match != null) restoredFooter.add(match);
        }
      }
    }
  }
}
