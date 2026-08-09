import 'dart:collection';

import 'package:collection/collection.dart';

import 'select_entry.dart';

/// Utility methods for working with [SelectEntry] trees and selections.
class SelectUtils {
  /// Returns the entries at the given tree [level] starting from [entry].
  ///
  /// - If [level] is 0, returns a set containing [entry].
  /// - If [level] is greater than the depth under [entry], returns an empty set.
  static SelectEntries findChildrenAtLevel(SelectEntry entry, int level) {
    // If level == 0, the current entry is the target.
    if (level == 0) return {entry};

    // If there are no children, any level > 0 cannot be found.
    if (entry.children == null || entry.children!.isEmpty) return {};

    // Recurse into the next level
    SelectEntries result = {};
    for (var child in entry.children ?? {}) {
      result.addAll(findChildrenAtLevel(child, level - 1));
    }
    return result;
  }

  /// Returns the entry ids at the given tree [level] starting from [entry].
  static Set<String> findIdsAtLevel(SelectEntry entry, int level) {
    // If level == 0, the current entry is the target.
    if (level == 0) return {entry.id};

    // If there are no children, any level > 0 cannot be found.
    if (entry.children == null || entry.children!.isEmpty) return {};

    // Recurse into the next level
    Set<String> result = {};
    for (var child in entry.children ?? {}) {
      result.addAll(findIdsAtLevel(child, level - 1));
    }
    return result;
  }

  /// Returns the `extra` payload values at the given tree [level] starting from
  /// [entry].
  ///
  /// The result contains values in traversal order, and each value is cast to
  /// [E]. If a node's `extra` is not assignable to [E], a runtime error may be
  /// thrown.
  static List<E> findExtrasAtLevel<E>(SelectEntry entry, int level) {
    // If level == 0, the current node is the target.
    if (level == 0) return [entry.extra as E];

    // If there are no children, any level > 0 cannot be found.
    if (entry.children == null || entry.children!.isEmpty) return [];

    // Recurse into the next level
    List<E> result = [];
    for (var child in entry.children ?? {}) {
      result.addAll(findExtrasAtLevel(child, level - 1));
    }
    return result;
  }

  /// Flattens a tree into a list of entry sets grouped by depth level.
  static List<SelectEntries> flattenTree(SelectEntry? root) {
    if (root == null) return [];

    final List<SelectEntries> resultLevels = [];

    // Use a Queue to store nodes to be processed
    final Queue<SelectEntry> queue = Queue()..add(root);

    while (queue.isNotEmpty) {
      // Key step: record the current queue size at the start of processing this level
      final int levelSize = queue.length;

      // Create a Set for the current level to ensure uniqueness
      final SelectEntries currentLevelSet = {};

      // Loop levelSize times to process only nodes in this level
      for (int i = 0; i < levelSize; i++) {
        final SelectEntry entry = queue.removeFirst();
        currentLevelSet.add(entry);

        // Add all children to the queue; they will be processed as the next level
        if (!entry.hasChildren) continue;
        for (final child in entry.children!) {
          queue.add(child);
        }
      }

      // Add the completed Set (all unique nodes of a level) to the result list
      resultLevels.add(currentLevelSet);
    }
    return resultLevels;
  }

  /// Returns the maximum depth of a tree structure rooted at [root].
  int treeDepth(SelectEntry? root) {
    if (root?.children == null || root?.children?.isEmpty == true) return 1;
    return 1 + root!.children!.map(treeDepth).fold(0, (a, b) => a > b ? a : b);
  }

  static SelectEntries removeAnyEntries(Iterable<SelectEntry> entries) {
    final SelectEntries result =
        entries is Set<SelectEntry> ? entries : entries.toSet();

    void removeAnyInChildren(SelectEntry entry) {
      final children = entry.children;
      if (children == null || children.isEmpty) return;

      children.removeWhere((child) => child is SelectChildEntry && child.isAny);

      for (final child in children) {
        removeAnyInChildren(child);
      }
    }

    result.removeWhere((entry) => entry is SelectChildEntry && entry.isAny);
    for (final entry in result) {
      removeAnyInChildren(entry);
    }

    return result;
  }

  /// Creates a deep copy of select entries.
  ///
  /// The returned set and all nested nodes are new instances, so in-place
  /// operations (e.g. [clippingTree]) won't mutate the original tree.
  ///
  /// If [skipAny] is true, nodes marked as "Any" are excluded from the cloned
  /// result.
  static SelectEntries deepCloneEntries(
    Iterable<SelectEntry> entries, {
    bool skipAny = false,
  }) {
    return entries
        .where(
            (entry) => !skipAny || !(entry is SelectChildEntry && entry.isAny))
        .map((entry) => _cloneEntry(entry, skipAny: skipAny))
        .toSet();
  }

  static SelectEntry _cloneEntry(
    SelectEntry entry, {
    bool skipAny = false,
  }) {
    final clonedChildren = entry.children
        ?.where(
            (child) => !skipAny || !(child is SelectChildEntry && child.isAny))
        .map((child) => _cloneEntry(child, skipAny: skipAny))
        .toSet();

    if (entry is SelectTextEntry) {
      return SelectTextEntry(
        parentId: entry.parentId,
        id: entry.id,
        name: entry.name,
        children: clonedChildren,
        enabled: entry.enabled,
        immediate: entry.immediate,
      );
    }

    if (entry is SelectIntEntry) {
      return SelectRangeEntry<int, dynamic>(
        min: entry.min,
        max: entry.max,
        divisions: entry.divisions,
        inputLabel: entry.inputLabel,
        minHintText: entry.minHintText,
        maxHintText: entry.maxHintText,
        parentId: entry.parentId,
        id: entry.id,
        name: entry.name,
        children: clonedChildren,
        enabled: entry.enabled,
        immediate: entry.immediate,
        extra: entry.extra,
      );
    }

    if (entry is SelectRangeEntry) {
      return SelectRangeEntry(
        min: entry.min,
        max: entry.max,
        divisions: entry.divisions,
        inputLabel: entry.inputLabel,
        minHintText: entry.minHintText,
        maxHintText: entry.maxHintText,
        parentId: entry.parentId,
        id: entry.id,
        name: entry.name,
        children: clonedChildren,
        enabled: entry.enabled,
        immediate: entry.immediate,
        extra: entry.extra,
      );
    }

    if (entry is SelectChildEntry) {
      return SelectChildEntry(
        parentId: entry.parentId,
        id: entry.id,
        name: entry.name,
        children: clonedChildren,
        enabled: entry.enabled,
        immediate: entry.immediate,
        extra: entry.extra,
      );
    }

    if (entry is SelectCategoryEntry) {
      return SelectCategoryEntry(
        selectionMode: entry.selectionMode,
        header: entry.header == null
            ? null
            : _cloneEntry(entry.header!, skipAny: skipAny),
        headerSelectionMode: entry.headerSelectionMode,
        footer: entry.footer == null
            ? null
            : _cloneEntry(entry.footer!, skipAny: skipAny),
        footerSelectionMode: entry.footerSelectionMode,
        id: entry.id,
        name: entry.name ?? '',
        children: clonedChildren,
        layout: entry.layout,
        enabled: entry.enabled,
        immediate: entry.immediate,
      );
    }

    throw UnsupportedError(
      'Unsupported SelectEntry type: ${entry.runtimeType}',
    );
  }

  static SelectEntry _cloneEntryWithChildren(
    SelectEntry entry,
    Set<SelectEntry>? children, {
    SelectEntry? header,
    SelectEntry? footer,
  }) {
    if (entry is SelectTextEntry) {
      return SelectTextEntry(
        parentId: entry.parentId,
        id: entry.id,
        name: entry.name,
        children: children,
        enabled: entry.enabled,
        immediate: entry.immediate,
      );
    }

    if (entry is SelectIntEntry) {
      return SelectRangeEntry<int, dynamic>(
        min: entry.min,
        max: entry.max,
        divisions: entry.divisions,
        inputLabel: entry.inputLabel,
        minHintText: entry.minHintText,
        maxHintText: entry.maxHintText,
        parentId: entry.parentId,
        id: entry.id,
        name: entry.name,
        children: children,
        enabled: entry.enabled,
        immediate: entry.immediate,
        extra: entry.extra,
      );
    }

    if (entry is SelectRangeEntry) {
      return SelectRangeEntry(
        min: entry.min,
        max: entry.max,
        divisions: entry.divisions,
        inputLabel: entry.inputLabel,
        minHintText: entry.minHintText,
        maxHintText: entry.maxHintText,
        parentId: entry.parentId,
        id: entry.id,
        name: entry.name,
        children: children,
        enabled: entry.enabled,
        immediate: entry.immediate,
        extra: entry.extra,
      );
    }

    if (entry is SelectChildEntry) {
      return SelectChildEntry(
        parentId: entry.parentId,
        id: entry.id,
        name: entry.name,
        children: children,
        enabled: entry.enabled,
        immediate: entry.immediate,
        extra: entry.extra,
      );
    }

    if (entry is SelectCategoryEntry) {
      return SelectCategoryEntry(
        selectionMode: entry.selectionMode,
        header: header,
        headerSelectionMode: entry.headerSelectionMode,
        footer: footer,
        footerSelectionMode: entry.footerSelectionMode,
        id: entry.id,
        name: entry.name ?? '',
        children: children,
        layout: entry.layout,
        enabled: entry.enabled,
        immediate: entry.immediate,
      );
    }

    throw UnsupportedError(
      'Unsupported SelectEntry type: ${entry.runtimeType}',
    );
  }

  static SelectEntry _cloneEntryWithoutChildren(SelectEntry entry) {
    return _cloneEntryWithChildren(entry, null);
  }

  static SelectEntry _cloneHeaderFooterEntry(
    SelectEntry entry,
    SelectEntries? selectedChildren, {
    required bool deepCloneSelectedSubtree,
  }) {
    final originalChildren = entry.children?.toList() ?? const <SelectEntry>[];
    final selectedIds =
        selectedChildren?.map((e) => e.id).toSet() ?? const <String>{};

    Set<SelectEntry>? clonedChildren;
    if (entry.children != null) {
      if (selectedIds.isEmpty) {
        clonedChildren = <SelectEntry>{};
      } else {
        final selectedOrdered =
            originalChildren.where((child) => selectedIds.contains(child.id));
        clonedChildren = deepCloneSelectedSubtree
            ? deepCloneEntries(selectedOrdered)
            : selectedOrdered.map(_cloneEntryWithoutChildren).toSet();
      }
    }

    return _cloneEntryWithChildren(entry, clonedChildren);
  }

  /// Removes unselected nodes from [entries] by clipping the tree in-place.
  ///
  /// [selectedItemsPerLevel] represents selected entries per depth level. Nodes
  /// not present at the current [level] are removed, and the process continues
  /// recursively for remaining nodes.
  ///
  /// When clipping the children of an entry, only the selected entries whose
  /// [parentId] matches the current entry's [id] are considered. This prevents
  /// selected children from sibling categories (which share the same level but
  /// belong to a different parent) from leaking into the wrong subtree, and
  /// avoids false matches by id alone (e.g. `custom`/`any` exist under every
  /// category).
  static void clippingTree(
    SelectEntries? entries,
    List<SelectEntries> selectedItemsPerLevel,
    int level, [
    Map<String, SelectEntries>? selectedHeaderEntries,
    Map<String, SelectEntries>? selectedFooterEntries,
  ]) {
    if (entries == null || entries.isEmpty || selectedItemsPerLevel.isEmpty) {
      return;
    }
    SelectEntries? selectedEntries =
        selectedItemsPerLevel.elementAtOrNull(level);
    if (selectedEntries == null || selectedEntries.isEmpty) {
      return;
    }
    entries.removeWhere((e) => !selectedEntries.contains(e));

    if (selectedHeaderEntries != null || selectedFooterEntries != null) {
      for (final entry in entries) {
        if (entry is! SelectCategoryEntry) continue;
        final category = entry;

        if (selectedHeaderEntries != null) {
          final headerSelected = selectedHeaderEntries[category.id] ?? {};
          final headerChildren = category.header?.children;
          if (headerChildren != null) {
            if (headerSelected.isEmpty) {
              headerChildren.clear();
            } else {
              headerChildren
                  .removeWhere((e) => !headerSelected.any((s) => s.id == e.id));
            }
          }
        }

        if (selectedFooterEntries != null) {
          final footerSelected = selectedFooterEntries[category.id] ?? {};
          final footerChildren = category.footer?.children;
          if (footerChildren != null) {
            if (footerSelected.isEmpty) {
              footerChildren.clear();
            } else {
              footerChildren
                  .removeWhere((e) => !footerSelected.any((s) => s.id == e.id));
            }
          }
        }
      }
    }

    if (level + 1 >= selectedItemsPerLevel.length) return;
    for (var item in entries) {
      // Filter the next-level selection to entries that actually belong to
      // `item`'s subtree before recursing, so clipping only removes nodes that
      // are not selected under this specific parent.
      final filteredPerLevel = List<SelectEntries>.from(selectedItemsPerLevel);
      final nextLevel = level + 1;
      if (nextLevel < filteredPerLevel.length) {
        filteredPerLevel[nextLevel] = filteredPerLevel[nextLevel]
            .where((e) =>
                e is SelectCategoryEntry ||
                (e is SelectChildEntry && e.parentId == item.id))
            .toSet();
      }
      clippingTree(
        item.children,
        filteredPerLevel,
        nextLevel,
        selectedHeaderEntries,
        selectedFooterEntries,
      );
    }
  }

  static SelectEntries cloneTree(
    Iterable<SelectEntry> entries,
    List<SelectEntries> selectedItemsPerLevel, {
    bool deepCloneSelectedSubtree = true,
    Map<String, SelectEntries>? selectedHeaderEntries,
    Map<String, SelectEntries>? selectedFooterEntries,
  }) {
    // Returns the selected entries at [level] that belong to [parent]'s
    // subtree. Root-level category entries are always kept (they have no
    // parentId), while child entries are matched by [parentId] == parent.id.
    // This is the key fix for multi-category scenarios: without it, the whole
    // level's selection set is used, so a selected child under one category
    // (e.g. `list_price`'s custom range) would leak into another category's
    // (e.g. `monthly_payment`'s) subtree during cloning, and id-only matches
    // (`custom`/`any` exist under every category) would produce wrong results.
    SelectEntries selectedForParent(SelectEntry parent, int level) {
      final all = selectedItemsPerLevel.elementAtOrNull(level);
      if (all == null || all.isEmpty) return {};
      return all
          .where((e) =>
              e is SelectCategoryEntry ||
              (e is SelectChildEntry && e.parentId == parent.id))
          .toSet();
    }

    SelectEntry cloneEntryAtLevel(SelectEntry entry, int level) {
      Set<SelectEntry>? clonedChildren;
      final children = entry.children;

      if (children != null && children.isNotEmpty) {
        final nextLevel = level + 1;
        final hasNextLevelSelection = nextLevel < selectedItemsPerLevel.length;

        if (!hasNextLevelSelection) {
          clonedChildren =
              deepCloneSelectedSubtree ? deepCloneEntries(children) : null;
        } else {
          final selectedNext = selectedForParent(entry, nextLevel);
          if (selectedNext.isEmpty) {
            clonedChildren =
                deepCloneSelectedSubtree ? deepCloneEntries(children) : null;
          } else {
            // Keep the entries already present in `children` (matched by
            // identity) so existing behaviour and ordering are preserved, and
            // additionally include any selected entries that are not part of
            // `children` (e.g. custom range entries that are only created in
            // the selection state, not in the static tree). Without including
            // the latter, the cloned children would end up empty/null even
            // though a range was actually selected.
            final childIds = children.map((c) => c.id).toSet();
            final selectedOrdered = <SelectEntry>[
              for (final child in children)
                if (selectedNext.contains(child)) child,
              for (final s in selectedNext)
                if (!childIds.contains(s.id)) s,
            ];
            final copied = selectedOrdered
                .map((child) => cloneEntryAtLevel(child, nextLevel))
                .toSet();
            clonedChildren = copied.isEmpty ? null : copied;
          }
        }
      }

      if (entry is SelectCategoryEntry) {
        final clonedHeader = entry.header == null
            ? null
            : selectedHeaderEntries == null
                ? deepCloneEntries({entry.header!}).firstOrNull
                : _cloneHeaderFooterEntry(
                    entry.header!,
                    selectedHeaderEntries[entry.id],
                    deepCloneSelectedSubtree: deepCloneSelectedSubtree,
                  );
        final clonedFooter = entry.footer == null
            ? null
            : selectedFooterEntries == null
                ? deepCloneEntries({entry.footer!}).firstOrNull
                : _cloneHeaderFooterEntry(
                    entry.footer!,
                    selectedFooterEntries[entry.id],
                    deepCloneSelectedSubtree: deepCloneSelectedSubtree,
                  );
        return _cloneEntryWithChildren(
          entry,
          clonedChildren,
          header: clonedHeader,
          footer: clonedFooter,
        );
      }

      return _cloneEntryWithChildren(entry, clonedChildren);
    }

    final selectedRoot = selectedItemsPerLevel.elementAtOrNull(0) ?? {};
    if (selectedRoot.isEmpty) return {};

    final result = <SelectEntry>{};
    for (final entry in entries) {
      if (!selectedRoot.contains(entry)) continue;
      result.add(cloneEntryAtLevel(entry, 0));
    }
    return result;
  }

  // Computes an effective label from the current selection and returns it.
  static String? getResultLabel(
    SelectEntries? resultEntries,
    String multipleText,
  ) {
    if (resultEntries == null) return null;

    // Keep traversing after the first valid label is found; once a second one is
    // found, return "multiple".
    // Rules for a valid label:
    // - A path from the root node to a leaf node counts as one selection path.
    // - The leaf node name is used as a candidate label.
    // - If the leaf node has isAny=true, use its parent's name instead. If the
    //   parent is the root (category) node, ignore it.
    String? firstLabel;

    bool collectCandidateLabels(
      SelectEntry entry, {
      SelectEntry? parent,
    }) {
      final children = entry.children;
      final isLeaf = children == null || children.isEmpty;
      if (isLeaf) {
        String? label;
        if (entry is SelectChildEntry && entry.isAny) {
          if (parent == null || parent is SelectCategoryEntry) return false;
          label = parent.name;
        } else {
          label = entry.name;
        }

        if (label == null || label.isEmpty) return false;
        if (firstLabel == null) {
          firstLabel = label;
          return false;
        }
        return true;
      }

      for (final child in children) {
        if (collectCandidateLabels(child, parent: entry)) return true;
      }
      return false;
    }

    for (final entry in resultEntries) {
      if (collectCandidateLabels(entry)) return multipleText;
    }
    return firstLabel;
  }

  /// Restores a previous selection by matching ids within [items].
  ///
  /// Returns selected entries per level. For custom range entries, previously
  /// entered values are restored into the matched entries.
  static List<SelectEntries> restorePreviousSelected(
      List<SelectEntry>? items, Set<SelectEntry>? selectedEntries) {
    final result = <SelectEntries>[];
    _initializeSelectedEntriesPerLevel(items, selectedEntries, 0, result);
    // Drop any stale min/max on custom range entries that were not part of the
    // restored selection, so previously entered values don't linger after a
    // reset (which would otherwise re-populate the input fields).
    final restored = result.expand((e) => e).toSet();
    items?.whereType<SelectRangeEntry>().forEach((entry) {
      if (entry.isCustom && !restored.contains(entry)) {
        entry.min = null;
        entry.max = null;
      }
    });
    return result;
  }

  static void _initializeSelectedEntriesPerLevel(
      List<SelectEntry>? items,
      Set<SelectEntry>? selectedEntries,
      int level,
      List<SelectEntries> result) {
    if (items == null ||
        items.isEmpty ||
        selectedEntries == null ||
        selectedEntries.isEmpty) {
      return;
    }
    result.add({});
    for (var selectedItem in selectedEntries) {
      final item = items.singleWhereOrNull((e) => e.id == selectedItem.id);
      if (item != null) {
        result[level].add(item);
        if (item is SelectRangeEntry && item.isCustom) {
          // If it's a custom entry, restore the previous input values.
          selectedItem as SelectRangeEntry;
          item.min = selectedItem.min;
          item.max = selectedItem.max;
        }
      }
      if (selectedItem.children?.isNotEmpty == true) {
        _initializeSelectedEntriesPerLevel(
            item?.children?.toList(), selectedItem.children, level + 1, result);
      }
    }
  }
}
