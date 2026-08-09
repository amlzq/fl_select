import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import 'constants.dart';
import 'select_entry.dart';
import 'state/selection_rules.dart';
import 'state/state_snapshot.dart';
import 'state/state_tree.dart';

/// Controller for a single [SelectDelegate] instance.
///
/// This controller manages select state and forwards user actions
/// (change/apply/reset) to listeners registered via [addChangeListener],
/// [addApplyListener], and [addResetListener].
///
/// The selection behavior ([selectionMode]) and the initial/reset selection
/// state ([previousSelected]/[resetSelected]) are injected as plain data at
/// construction time. The controller does not depend on the [SelectDelegate]
/// configuration class.
class SelectController extends ChangeNotifier {
  /// The selection behavior applied at the top level of the select.
  ///
  /// Determines how many entries can be selected at once. Per-category
  /// [SelectCategoryEntry.selectionMode] may override this for nested levels.
  final SelectionMode selectionMode;

  /// The initial selection state to restore when the controller is created.
  ///
  /// Typically the selection persisted from a previous session. If null, the
  /// controller starts with no selection.
  final SelectEntries? previousSelected;

  /// The selection state used when the user triggers a reset.
  ///
  /// If null, reset falls back to [previousSelected] (or no selection).
  final SelectEntries? resetSelected;

  /// The underlying state tree holding the bound entries and their selection
  /// state.
  final StateTree tree = StateTree();
  final SelectionRules _rules = const SelectionRules();
  bool _isDisposed = false;

  final List<SelectCallback> _changeListeners = [];
  final List<SelectCallback> _applyListeners = [];
  final List<VoidCallback> _resetListeners = [];

  SelectController({
    required this.selectionMode,
    this.previousSelected,
    this.resetSelected,
  });

  /// Registers a listener to be called when the selection changes.
  ///
  /// Returns a [VoidCallback] that unregisters the listener when called.
  VoidCallback addChangeListener(SelectCallback listener) {
    _changeListeners.add(listener);
    return () => removeChangeListener(listener);
  }

  /// Unregisters a previously registered change listener.
  void removeChangeListener(SelectCallback listener) {
    _changeListeners.remove(listener);
  }

  /// Registers a listener to be called when the selection is applied.
  ///
  /// Returns a [VoidCallback] that unregisters the listener when called.
  VoidCallback addApplyListener(SelectCallback listener) {
    _applyListeners.add(listener);
    return () => removeApplyListener(listener);
  }

  /// Unregisters a previously registered apply listener.
  void removeApplyListener(SelectCallback listener) {
    _applyListeners.remove(listener);
  }

  /// Registers a listener to be called when reset is triggered.
  ///
  /// Returns a [VoidCallback] that unregisters the listener when called.
  VoidCallback addResetListener(VoidCallback listener) {
    _resetListeners.add(listener);
    return () => removeResetListener(listener);
  }

  /// Unregisters a previously registered reset listener.
  void removeResetListener(VoidCallback listener) {
    _resetListeners.remove(listener);
  }

  /// Whether this controller has been disposed.
  ///
  /// Once disposed, the controller no longer notifies listeners.
  bool get isDisposed => _isDisposed;

  /// A snapshot of the current selection state.
  StateSnapshot get snapshot => tree.snapshot;

  void _notifyListenersIfAlive() {
    if (_isDisposed) return;
    notifyListeners();
  }

  void bindState(
    List<SelectEntry> entries, {
    required bool initializeAnyIfEmpty,
    SelectEntries? previousSelectedOverride,
    SelectEntries? resetSelectedOverride,
  }) {
    _validateParentIds(entries);
    final changed = tree.bind(
      entries,
      previousSelected: previousSelectedOverride ?? previousSelected,
      resetSelected: resetSelectedOverride ?? resetSelected,
      initializeAnyIfEmpty: initializeAnyIfEmpty,
    );
    if (changed) {
      _notifyListenersIfAlive();
    }
  }

  /// Validates that every child entry's [SelectChildEntry.parentId] points to
  /// its direct parent in a 2D-or-deeper tree.
  ///
  /// In a flat 1D structure (no top-level [SelectCategoryEntry]), `parentId`
  /// may legitimately be empty (e.g. entries built with
  /// [SelectTextEntry.name]), so validation is skipped entirely.
  ///
  /// Once at least one [SelectCategoryEntry] is present, every
  /// [SelectChildEntry] — including header/footer nodes and their children —
  /// must have a `parentId` equal to the id of its direct parent, otherwise
  /// tapping cannot resolve the owning category and the selection is silently
  /// dropped. This check throws an [ArgumentError] during development instead
  /// of failing silently in release builds.
  static void _validateParentIds(List<SelectEntry> entries) {
    final hasCategory = entries.any((e) => e is SelectCategoryEntry);
    if (!hasCategory) return;

    void validateParent(SelectEntry parent, SelectEntry child) {
      if (child is SelectChildEntry && child.parentId != parent.id) {
        throw ArgumentError(
          'SelectChildEntry(parentId: "${child.parentId}", id: "${child.id}") '
          'has a parentId that does not match its parent node (id: "${parent.id}"). '
          'In a 2D-or-deeper structure, a child entry\'s parentId must equal its '
          'direct parent\'s id, otherwise it cannot be selected. If this is a '
          'flat 1D list, make sure there is no SelectCategoryEntry at the top '
          'level.',
        );
      }
    }

    void walk(SelectEntry parent, Set<SelectEntry> children) {
      for (final child in children) {
        validateParent(parent, child);
        if (child.children != null && child.children!.isNotEmpty) {
          walk(child, child.children!);
        }
      }
    }

    for (final entry in entries) {
      if (entry is SelectCategoryEntry) {
        final header = entry.header;
        if (header != null) {
          validateParent(entry, header);
          if (header.children != null && header.children!.isNotEmpty) {
            walk(header, header.children!);
          }
        }
        final footer = entry.footer;
        if (footer != null) {
          validateParent(entry, footer);
          if (footer.children != null && footer.children!.isNotEmpty) {
            walk(footer, footer.children!);
          }
        }
      }
      if (entry.children != null && entry.children!.isNotEmpty) {
        walk(entry, entry.children!);
      }
    }
  }

  SelectEntries selectedEntriesAtLevel(int level) =>
      tree.selectedEntriesAtLevel(level);

  SelectEntries selectedEntriesForParent(String parentId,
          {required int level}) =>
      tree.selectedEntriesForParent(parentId, level: level);

  SelectEntries selectedHeaderEntriesFor(String categoryId) =>
      tree.selectedHeaderEntriesFor(categoryId);

  SelectEntries selectedFooterEntriesFor(String categoryId) =>
      tree.selectedFooterEntriesFor(categoryId);

  void focusCategoryEntry(
    SelectCategoryEntry category, {
    required SelectionMode selectionMode,
  }) {
    _rules.focusCategory(
      tree,
      category,
      selectionMode: selectionMode,
    );
    _notifyListenersIfAlive();
  }

  void toggleFlatEntry(
    SelectChildEntry entry, {
    required SelectionMode selectionMode,
    required bool isCategoryTree,
    SelectCategoryEntry? category,
  }) {
    _rules.toggleFlatLeaf(
      tree,
      entry,
      selectionMode: selectionMode,
      isCategoryTree: isCategoryTree,
      category: category,
    );
    _notifyListenersIfAlive();
  }

  void toggleCascadingEntry(
    SelectChildEntry entry, {
    required SelectionMode selectionMode,
    required SelectionMode childrenSelectionMode,
    required List<SelectEntry> focusedPath,
    required SelectCategoryEntry category,
  }) {
    _rules.toggleCascadingLeaf(
      tree,
      entry,
      selectionMode: selectionMode,
      childrenSelectionMode: childrenSelectionMode,
      focusedPath: focusedPath,
      category: category,
    );
    _notifyListenersIfAlive();
  }

  void toggleHeaderOrFooterEntry({
    required String categoryId,
    required SelectChildEntry entry,
    required SelectionMode selectionMode,
    required bool isHeader,
  }) {
    _rules.toggleHeaderOrFooter(
      tree,
      categoryId: categoryId,
      entry: entry,
      selectionMode: selectionMode,
      isHeader: isHeader,
    );
    _notifyListenersIfAlive();
  }

  void emitChangeFromState() {
    change(tree.buildChangedEntries());
  }

  void applyFromState() {
    apply(tree.buildAppliedEntries());
  }

  void resetState({required bool initializeAnyIfEmpty}) {
    tree.reset(initializeAnyIfEmpty: initializeAnyIfEmpty);
    _notifyListenersIfAlive();
  }

  /// Resets the selection of a single [category], leaving all other
  /// categories' selections untouched.
  ///
  /// This is the per-tab counterpart of [resetState] and is used by tabbed
  /// selects (e.g. [GridSelect]) where "Reset" should clear only the
  /// currently focused category.
  void resetCategoryState(
    SelectCategoryEntry category, {
    required bool initializeAnyIfEmpty,
  }) {
    tree.resetCategory(category, initializeAnyIfEmpty: initializeAnyIfEmpty);
    _notifyListenersIfAlive();
  }

  void trimSelectionLevels(int count) {
    tree.trimLevels(count);
    tree.trimTrailingEmptyLevels();
    _notifyListenersIfAlive();
  }

  SelectEntry? findEntry(String id, {String? parentId}) {
    return tree.findEntry(id, parentId: parentId);
  }

  List<SelectEntry>? findPath(String id, {String? parentId}) {
    return tree.findPath(id, parentId: parentId);
  }

  bool focusCategory(String categoryId) {
    final category = tree.findCategory(categoryId);
    if (category == null) return false;
    focusCategoryEntry(category, selectionMode: selectionMode);
    return true;
  }

  bool select(
    String id, {
    String? parentId,
    bool emitChange = true,
    bool applyIfImmediate = false,
  }) {
    final entry = tree.findEntry(id, parentId: parentId);
    if (entry == null) return false;

    if (entry is SelectCategoryEntry) {
      focusCategoryEntry(entry, selectionMode: selectionMode);
      if (emitChange) emitChangeFromState();
      return true;
    }

    if (entry is! SelectChildEntry) return false;

    final path = tree.findPath(id, parentId: parentId);
    final effectiveSelectionMode = _effectiveSelectionMode();

    if (path == null || path.isEmpty) {
      if (tree.entries.isEmpty || tree.entries.first is SelectCategoryEntry) {
        return false;
      }

      final alreadySelected = tree.selectedEntriesAtLevel(0).contains(entry);
      if (!alreadySelected) {
        toggleFlatEntry(
          entry,
          selectionMode: effectiveSelectionMode,
          isCategoryTree: false,
        );
      }
      if (applyIfImmediate &&
          (effectiveSelectionMode == SelectionMode.single || entry.immediate)) {
        applyFromState();
      } else if (emitChange) {
        emitChangeFromState();
      }
      return true;
    }

    final root = path.first;
    if (root is! SelectCategoryEntry) return false;

    if (path.length == 2) {
      final leaf = path.last;
      if (leaf is! SelectChildEntry) return false;

      final alreadySelected =
          tree.selectedEntriesForParent(root.id, level: 1).contains(leaf);
      if (!alreadySelected) {
        toggleFlatEntry(
          leaf,
          selectionMode: effectiveSelectionMode,
          isCategoryTree: true,
          category: root,
        );
      }

      if (applyIfImmediate &&
          (effectiveSelectionMode == SelectionMode.single || leaf.immediate)) {
        applyFromState();
      } else if (emitChange) {
        emitChangeFromState();
      }
      return true;
    }

    final leaf = path.last;
    if (leaf is! SelectChildEntry) return false;
    final focusedPath = path.sublist(0, path.length - 1);
    final level = focusedPath.length;
    final alreadySelected = tree.selectedEntriesAtLevel(level).contains(leaf);
    if (!alreadySelected) {
      toggleCascadingEntry(
        leaf,
        selectionMode: effectiveSelectionMode,
        childrenSelectionMode: root.selectionMode,
        focusedPath: focusedPath,
        category: root,
      );
    }

    if (applyIfImmediate &&
        (effectiveSelectionMode == SelectionMode.single || leaf.immediate)) {
      applyFromState();
    } else if (emitChange) {
      emitChangeFromState();
    }
    return true;
  }

  bool unselect(
    String id, {
    String? parentId,
    bool emitChange = true,
  }) {
    final entry = tree.findEntry(id, parentId: parentId);
    if (entry == null || entry is! SelectChildEntry) return false;

    final effectiveSelectionMode = _effectiveSelectionMode();
    final path = tree.findPath(id, parentId: parentId);

    if (path == null || path.isEmpty) {
      final selected0 = tree.mutableSelectedEntriesAtLevel(0);
      if (!selected0.contains(entry)) return true;
      if (effectiveSelectionMode == SelectionMode.single) {
        final any = tree.entries.singleWhereOrNull(testAnyElement);
        selected0
          ..clear()
          ..addAll(any == null ? {} : {any});
      } else {
        selected0.remove(entry);
      }
      _notifyListenersIfAlive();
      if (emitChange) emitChangeFromState();
      return true;
    }

    final root = path.first;
    if (root is! SelectCategoryEntry) return false;

    if (path.length == 2) {
      final leaf = path.last;
      if (leaf is! SelectChildEntry) return false;
      final selectedChildren = tree.mutableSelectedEntriesAtLevel(1);
      if (!selectedChildren.contains(leaf)) return true;

      if (root.selectionMode == SelectionMode.single) {
        final any = root.children?.singleWhereOrNull(testAnyElement);
        selectedChildren
            .removeWhere((e) => e is SelectChildEntry && e.parentId == root.id);
        if (any != null) {
          selectedChildren.add(any);
          tree.mutableSelectedEntriesAtLevel(0).add(root);
        } else {
          tree.mutableSelectedEntriesAtLevel(0).remove(root);
        }
      } else {
        toggleFlatEntry(
          leaf,
          selectionMode: effectiveSelectionMode,
          isCategoryTree: true,
          category: root,
        );
      }

      if (emitChange) emitChangeFromState();
      return true;
    }

    final leaf = path.last;
    if (leaf is! SelectChildEntry) return false;
    final focusedPath = path.sublist(0, path.length - 1);
    final level = focusedPath.length;
    final selectedAtLevel = tree.mutableSelectedEntriesAtLevel(level);
    if (!selectedAtLevel.contains(leaf)) return true;

    if (root.selectionMode == SelectionMode.single) {
      final parent = focusedPath.last;
      final any = parent.children
          ?.whereType<SelectChildEntry>()
          .singleWhereOrNull(testAnyElement);
      if (any != null && any != leaf) {
        select(any.id, parentId: any.parentId, emitChange: emitChange);
        return true;
      }
      return false;
    }

    toggleCascadingEntry(
      leaf,
      selectionMode: effectiveSelectionMode,
      childrenSelectionMode: root.selectionMode,
      focusedPath: focusedPath,
      category: root,
    );
    if (emitChange) emitChangeFromState();
    return true;
  }

  SelectionMode _effectiveSelectionMode() {
    if (selectionMode == SelectionMode.multiple) return SelectionMode.multiple;
    for (final entry in tree.entries) {
      if (entry is SelectCategoryEntry &&
          entry.selectionMode == SelectionMode.multiple) {
        return SelectionMode.multiple;
      }
    }
    return SelectionMode.single;
  }

  bool selectHeaderChild(
    String categoryId,
    String childId, {
    bool emitChange = true,
  }) {
    final category = tree.findCategory(categoryId);
    final header = category?.header;
    final child = header?.children?.singleWhereOrNull((e) => e.id == childId);
    if (child is! SelectChildEntry) return false;
    if (tree.selectedHeaderEntriesFor(categoryId).any((e) => e.id == childId)) {
      return true;
    }
    toggleHeaderOrFooterEntry(
      categoryId: categoryId,
      entry: child,
      selectionMode: category?.headerSelectionMode ?? SelectionMode.single,
      isHeader: true,
    );
    if (emitChange) emitChangeFromState();
    return true;
  }

  bool selectFooterChild(
    String categoryId,
    String childId, {
    bool emitChange = true,
  }) {
    final category = tree.findCategory(categoryId);
    final footer = category?.footer;
    final child = footer?.children?.singleWhereOrNull((e) => e.id == childId);
    if (child is! SelectChildEntry) return false;
    if (tree.selectedFooterEntriesFor(categoryId).any((e) => e.id == childId)) {
      return true;
    }
    toggleHeaderOrFooterEntry(
      categoryId: categoryId,
      entry: child,
      selectionMode: category?.footerSelectionMode ?? SelectionMode.single,
      isHeader: false,
    );
    if (emitChange) emitChangeFromState();
    return true;
  }

  bool unselectHeaderChild(
    String categoryId,
    String childId, {
    bool emitChange = true,
  }) {
    final selected = tree.mutableHeaderEntriesFor(categoryId);
    final hadSelected = selected.any((e) => e.id == childId);
    selected.removeWhere((e) => e.id == childId);
    if (hadSelected && emitChange) emitChangeFromState();
    return true;
  }

  bool unselectFooterChild(
    String categoryId,
    String childId, {
    bool emitChange = true,
  }) {
    final selected = tree.mutableFooterEntriesFor(categoryId);
    final hadSelected = selected.any((e) => e.id == childId);
    selected.removeWhere((e) => e.id == childId);
    if (hadSelected && emitChange) emitChangeFromState();
    return true;
  }

  /// Notifies all registered change listeners that the selection changed.
  void change(SelectEntries selected) {
    for (final listener in List.of(_changeListeners)) {
      listener(selected);
    }
  }

  /// Notifies all registered apply listeners that the selection was applied.
  void apply(SelectEntries selected) {
    for (final listener in List.of(_applyListeners)) {
      listener(selected);
    }
  }

  /// Notifies all registered reset listeners that reset was requested.
  void reset() {
    for (final listener in List.of(_resetListeners)) {
      listener();
    }
  }

  static SelectController? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_InheritedSelectControllerScope>()
        ?.controller;
  }

  @override
  void dispose() {
    _changeListeners.clear();
    _applyListeners.clear();
    _resetListeners.clear();
    _isDisposed = true;
    super.dispose();
  }
}

class _InheritedSelectControllerScope extends InheritedWidget {
  final SelectController controller;

  const _InheritedSelectControllerScope(
      {required super.child, required this.controller});

  @override
  bool updateShouldNotify(covariant _InheritedSelectControllerScope oldWidget) {
    return oldWidget.controller != controller;
  }
}

class SelectControllerProvider extends StatelessWidget {
  final SelectController controller;
  final Widget child;

  /// Provides a [SelectController] to descendants.
  const SelectControllerProvider({
    super.key,
    required this.controller,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return _InheritedSelectControllerScope(
      controller: controller,
      child: child,
    );
  }
}
