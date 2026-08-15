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
      selectedEntries
          .removeWhere((e) => testSameParentElement(e, item.parentId));
      selectedEntries.add(item);
    } else if (item is SelectRangeEntry && item.isCustom) {
      selectedEntries
          .removeWhere((e) => testSameParentElement(e, item.parentId));
      selectedEntries.add(item);
    } else {
      selectedEntries.removeWhere(
        (e) => e is SelectChildEntry && e.parentId == item.parentId && e.isAny,
      );

      if (SelectionMode.single == category.selectionMode) {
        if (selectedEntries.contains(item)) return;
        selectedEntries
            .removeWhere((e) => testSameParentElement(e, item.parentId));
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
    final hasSelectionInCategory =
        selectedEntries.any((e) => testSameParentElement(e, category.id));
    if (hasSelectionInCategory) {
      rootSelected.add(category);
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
  /// categories' selections. Instead, only entries whose parent chain roots
  /// at [category] are removed: a child entry's [SelectChildEntry.parentId]
  /// always points at a node inside the category subtree (the category
  /// itself or one of its non-leaf descendants).
  void _removeCategorySelections(
    StateTree tree,
    SelectCategoryEntry category,
  ) {
    // Ids of nodes that can act as a parent: the category itself plus its
    // non-leaf descendants. Leaf ids are skipped because no child entry can
    // reference them as parentId, which also reduces cross-category id
    // collisions for leaves sharing the same id.
    final subtreeParentIds = <String>{};
    void collect(SelectEntry node) {
      final children = node.children;
      if (children == null || children.isEmpty) return;
      subtreeParentIds.add(node.id);
      for (final child in children) {
        collect(child);
      }
    }

    collect(category);
    // Header/footer are standalone fields, not members of [category.children];
    // collect them separately so their nested selections are also matched.
    final header = category.header;
    if (header != null) collect(header);
    final footer = category.footer;
    if (footer != null) collect(footer);

    for (var i = 1; i < tree.levelCount; i++) {
      tree.mutableSelectedEntriesAtLevel(i).removeWhere(
            (e) =>
                e is SelectChildEntry &&
                subtreeParentIds.contains(e.parentId),
          );
    }

    // Header/footer selections live in their own maps indexed by category id;
    // they are not part of the per-level sets above.
    tree.mutableHeaderEntriesFor(category.id).clear();
    tree.mutableFooterEntriesFor(category.id).clear();
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
              (e) => (e as SelectChildEntry).parentId == entry.parentId);
          selectedEntries.add(entry);
        }
      }

      // When selecting a child-level "Any", also remove "Any" entries from
      // all ancestor levels above the current one (i.e. exclude the current
      // level's parent because the entry itself IS that "Any").
      if (selectedEntries.contains(entry)) {
        for (var i = level - 2; i >= 0; i--) {
          final ancestor = focusedPath[i];
          tree.mutableSelectedEntriesAtLevel(i + 1).removeWhere((e) =>
              e is SelectChildEntry && e.parentId == ancestor.id && e.isAny);
        }
      }
    } else {
      // Remove "Any" entries from the current level (same parent).
      selectedEntries.removeWhere((e) =>
          e is SelectChildEntry && e.parentId == entry.parentId && e.isAny);

      // Remove "Any" entries from all ancestor levels.
      // focusedPath[i] is the node at level i.
      // The "Any" entry under focusedPath[i] lives at level i+1 with
      // parentId == focusedPath[i].id.
      // We iterate from the deepest ancestor (level-1) up to level 0,
      // clearing each one's "Any" placeholder.
      for (var i = level - 1; i >= 0; i--) {
        final ancestor = focusedPath[i];
        tree.mutableSelectedEntriesAtLevel(i + 1).removeWhere((e) =>
            e is SelectChildEntry && e.parentId == ancestor.id && e.isAny);
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

    for (var i = level - 1; i >= 0; i--) {
      final parent = focusedPath[i];
      final sameParentSelected = tree
          .mutableSelectedEntriesAtLevel(i + 1)
          .where((e) => e is SelectChildEntry && e.parentId == parent.id);
      if (sameParentSelected.isEmpty) {
        tree.mutableSelectedEntriesAtLevel(i).remove(parent);
      }
    }

    if (tree.selectedEntriesAtLevel(1).isEmpty) {
      tree.mutableSelectedEntriesAtLevel(0).add(category);
      final anyItem = category.children?.singleWhereOrNull(testAnyElement);
      if (anyItem != null) {
        tree.mutableSelectedEntriesAtLevel(1).add(anyItem);
      }
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
