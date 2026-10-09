import 'package:collection/collection.dart';

import '../constants.dart';
import '../select_entry.dart';
import 'state_tree.dart';

class SelectionRules {
  const SelectionRules();

  void focusCategory(
    StateTree tree,
    SelectCategoryEntry category, {
    required SelectionMode selectionMode,
  }) {
    // Focusing a category is a navigation action: it never clears selections
    // made in other categories. Cross-category clearing for delegate-level
    // single selection is applied when a leaf is selected — see
    // [toggleCascadingLeaf].
    tree.ensureLevels(2);
    final selectedChildren = tree.mutableSelectedEntriesAtLevel(1);
    final hasChildOfCategory = selectedChildren.any(
      (e) => e is SelectChildEntry && e.parentId == category.id,
    );
    if (hasChildOfCategory) {
      return;
    }

    final anyItem = category.children?.singleWhereOrNull(testAnyElement);
    if (anyItem != null) {
      selectedChildren.removeWhere(
        (e) => e is SelectChildEntry && e.parentId == category.id,
      );
      selectedChildren.add(anyItem);
    }

    final rootSelected = tree.mutableSelectedEntriesAtLevel(0);
    final hasSelectionInCategory = selectedChildren.any(
      (e) => e is SelectChildEntry && e.parentId == category.id,
    );
    if (hasSelectionInCategory) {
      rootSelected.add(category);
    } else {
      rootSelected.remove(category);
    }
  }

  void toggleFlatLeaf(
    StateTree tree,
    SelectChildEntry item, {
    required SelectionMode selectionMode,
    required bool isCategoryTree,
    SelectCategoryEntry? category,
  }) {
    if (!isCategoryTree) {
      tree.ensureLevels(1);
      final selectedEntries = tree.mutableSelectedEntriesAtLevel(0);

      if (item.isAny) {
        selectedEntries
          ..clear()
          ..add(item);
        return;
      }

      selectedEntries.removeWhere((e) => e is SelectChildEntry && e.isAny);
      if (SelectionMode.single == selectionMode) {
        if (selectedEntries.contains(item)) return;
        selectedEntries
          ..clear()
          ..add(item);
      } else {
        if (selectedEntries.contains(item)) {
          selectedEntries.remove(item);
          // Unselecting the last item falls back to the "Any" placeholder,
          // mirroring the category-tree and cascading branches below.
          if (selectedEntries.isEmpty) {
            final anyItem = tree.entries.singleWhereOrNull(testAnyElement);
            if (anyItem != null) {
              selectedEntries.add(anyItem);
            }
          }
        } else {
          selectedEntries.add(item);
        }
      }
      return;
    }

    if (category == null) return;
    tree.ensureLevels(2);
    final selectedEntries = tree.mutableSelectedEntriesAtLevel(1);

    if (item.isAny) {
      selectedEntries.removeWhere(
        (e) => testSameParentElement(e, item.parentId),
      );
      selectedEntries.add(item);
    } else if (item is SelectRangeEntry && item.isCustom) {
      selectedEntries.removeWhere(
        (e) => testSameParentElement(e, item.parentId),
      );
      selectedEntries.add(item);
    } else {
      selectedEntries.removeWhere(
        (e) => e is SelectChildEntry && e.parentId == item.parentId && e.isAny,
      );

      // Counter and range layouts pin the effective mode to single; a
      // category without an explicit selectionMode otherwise inherits the
      // delegate-level mode.
      if (SelectionMode.single ==
          category.effectiveSelectionMode(selectionMode)) {
        if (selectedEntries.contains(item)) return;
        selectedEntries.removeWhere(
          (e) => testSameParentElement(e, item.parentId),
        );
        selectedEntries.add(item);
      } else {
        if (selectedEntries.contains(item)) {
          selectedEntries.remove(item);
        } else {
          selectedEntries.add(item);
        }
      }
    }

    final rootSelected = tree.mutableSelectedEntriesAtLevel(0);
    final hasSelectionInCategory = selectedEntries.any(
      (e) => testSameParentElement(e, category.id),
    );
    if (hasSelectionInCategory) {
      rootSelected.add(category);
      // Delegate-level single selection: selecting a leaf deselects every
      // other category's selections. The clear happens here on selection,
      // not when the category is focused. [selectionMode] is expected to
      // be the delegate-level mode (see toggleCascadingLeaf).
      if (SelectionMode.single == selectionMode &&
          selectedEntries.contains(item)) {
        for (final other in tree.entries.whereType<SelectCategoryEntry>()) {
          if (other.id == category.id) continue;
          _removeCategorySelections(tree, other);
          rootSelected.remove(other);
        }
      }
    } else {
      final anyItem = category.children?.singleWhereOrNull(testAnyElement);
      if (anyItem != null) {
        selectedEntries.add(anyItem);
        rootSelected.add(category);
      } else {
        rootSelected.remove(category);
      }
    }
  }

  /// Removes every child selection that belongs to [category]'s subtree
  /// across all levels.
  ///
  /// A single-selection category must keep at most one pick, but the state
  /// tree stores selections per depth level, mixing entries from unrelated
  /// categories. Clearing a whole level would therefore drop other
  /// categories' selections. [StateTree.clearCategorySelections] owns that
  /// subtree-scoped sweep, shared with [StateTree.resetCategory].
  void _removeCategorySelections(StateTree tree, SelectCategoryEntry category) {
    tree.clearCategorySelections(category);
  }

  void toggleCascadingLeaf(
    StateTree tree,
    SelectChildEntry entry, {
    required SelectionMode selectionMode,
    required SelectionMode childrenSelectionMode,
    required List<SelectEntry> focusedPath,
    required SelectCategoryEntry category,
  }) {
    final level = focusedPath.length;
    while (level - tree.levelCount >= 0) {
      tree.ensureLevels(tree.levelCount + 1);
    }

    final selectedEntries = tree.mutableSelectedEntriesAtLevel(level);
    if (entry.isAny) {
      if (SelectionMode.single == childrenSelectionMode) {
        if (!selectedEntries.contains(entry)) {
          _removeCategorySelections(tree, category);
          selectedEntries.add(entry);
        }
      } else {
        if (selectedEntries.contains(entry)) {
          selectedEntries.remove(entry);
        } else {
          selectedEntries.removeWhere(
            (e) => (e as SelectChildEntry).parentId == entry.parentId,
          );
          selectedEntries.add(entry);
        }
      }

      // When selecting a child-level "Any", also remove "Any" entries from
      // all ancestor levels above the current one (i.e. exclude the current
      // level's parent because the entry itself IS that "Any").
      if (selectedEntries.contains(entry)) {
        for (var i = level - 2; i >= 0; i--) {
          final ancestor = focusedPath[i];
          tree
              .mutableSelectedEntriesAtLevel(i + 1)
              .removeWhere(
                (e) =>
                    e is SelectChildEntry &&
                    e.parentId == ancestor.id &&
                    e.isAny,
              );
        }
      }
    } else {
      // Remove "Any" entries from the current level (same parent).
      selectedEntries.removeWhere(
        (e) => e is SelectChildEntry && e.parentId == entry.parentId && e.isAny,
      );

      // Remove "Any" entries from all ancestor levels.
      // focusedPath[i] is the node at level i.
      // The "Any" entry under focusedPath[i] lives at level i+1 with
      // parentId == focusedPath[i].id.
      // We iterate from the deepest ancestor (level-1) up to level 0,
      // clearing each one's "Any" placeholder.
      for (var i = level - 1; i >= 0; i--) {
        final ancestor = focusedPath[i];
        tree
            .mutableSelectedEntriesAtLevel(i + 1)
            .removeWhere(
              (e) =>
                  e is SelectChildEntry && e.parentId == ancestor.id && e.isAny,
            );
      }

      if (SelectionMode.single == childrenSelectionMode) {
        if (!selectedEntries.contains(entry)) {
          _removeCategorySelections(tree, category);
          selectedEntries.add(entry);
        }
      } else {
        if (selectedEntries.contains(entry)) {
          selectedEntries.remove(entry);
        } else {
          selectedEntries.add(entry);
        }
      }
    }

    if (selectedEntries.contains(entry)) {
      for (var i = level - 1; i >= 0; i--) {
        tree.mutableSelectedEntriesAtLevel(i).add(focusedPath[i]);
      }
      // Delegate-level single selection: selecting a leaf deselects every
      // other category's selections. The clear happens here on selection,
      // not when the category is focused.
      if (SelectionMode.single == selectionMode) {
        for (final other in tree.entries.whereType<SelectCategoryEntry>()) {
          if (other.id == category.id) continue;
          _removeCategorySelections(tree, other);
          tree.mutableSelectedEntriesAtLevel(0).remove(other);
        }
      }
      return;
    }

    // The deselected entry left its parent without any selected child. Walk up
    // towards the category and, at the first ancestor that has no selected child
    // left, restore that ancestor's own "Any" — the sibling placeholder of the
    // deselected branch — instead of dropping the whole branch. This mirrors the
    // single-mode unselect, which re-selects the deselected leaf's parent's
    // "Any". Only when an ancestor owns no "Any" is it dropped, so the walk
    // continues one level higher.
    for (var i = level - 1; i >= 0; i--) {
      final parent = focusedPath[i];
      final childLevel = i + 1;
      final selectedChildren = tree.mutableSelectedEntriesAtLevel(childLevel);
      final hasSelectedChild = selectedChildren.any(
        (e) => e is SelectChildEntry && e.parentId == parent.id,
      );
      // A sibling (or a deeper pick under the same parent) still covers this
      // level, so there is nothing to restore.
      if (hasSelectedChild) break;

      final anyItem = parent.children?.singleWhereOrNull(testAnyElement);
      // Do not resurrect the "Any" the user just deselected: mirror the
      // single-mode unselect guard (`any != leaf`).
      if (anyItem != null && anyItem != entry) {
        // Keep [parent] selected on the focused path and restore its "Any" so
        // the branch reads as an explicit "no narrowing" pick.
        selectedChildren.add(anyItem);
        tree.mutableSelectedEntriesAtLevel(i).add(parent);
        break;
      }

      // No "Any" to fall back to at this level: drop [parent] and keep climbing.
      tree.mutableSelectedEntriesAtLevel(i).remove(parent);
    }

    tree.trimTrailingEmptyLevels();
  }

  void toggleHeaderOrFooter(
    StateTree tree, {
    required String categoryId,
    required SelectChildEntry entry,
    required SelectionMode selectionMode,
    required bool isHeader,
  }) {
    final selectedEntries = isHeader
        ? tree.mutableHeaderEntriesFor(categoryId)
        : tree.mutableFooterEntriesFor(categoryId);
    final contains = selectedEntries.any((e) => e.id == entry.id);
    if (SelectionMode.single == selectionMode) {
      if (contains) {
        selectedEntries.removeWhere((e) => e.id == entry.id);
      } else {
        selectedEntries
          ..clear()
          ..add(entry);
      }
      return;
    }

    if (contains) {
      selectedEntries.removeWhere((e) => e.id == entry.id);
    } else {
      selectedEntries.add(entry);
    }
  }
}
