import 'package:flutter/material.dart';

import 'select_entry.dart';

/// Callback invoked with the currently selected entries.
typedef SelectCallback = void Function(SelectEntries selected);

/// Badge rendering style.
enum BadgeStyle {
  number,

  dot,
}

/// Selection mode for a category or select.
enum SelectionMode {
  /// At most one entry may be selected; picking a new entry replaces the
  /// previous one.
  single,

  /// Any number of entries may be selected; selections accumulate until
  /// applied (see [SelectChildEntry.immediate] for the per-entry override).
  multiple,
}

/// Builds a skeleton widget while select data is loading.
typedef SkeletonBuilder = Widget Function(BuildContext context);

/// Returns true if the entry is a category explicitly configured with
/// [SelectionMode.multiple].
///
/// Categories that leave [SelectCategoryEntry.selectionMode] null inherit
/// the delegate-level mode instead and are not matched by this predicate.
bool testMultipleElement(SelectEntry e) =>
    e is SelectCategoryEntry && e.selectionMode == SelectionMode.multiple;

/// Returns true if the entry is an "Any" child entry.
bool testAnyElement(SelectEntry e) => e is SelectChildEntry && e.isAny;

/// Returns true if the entry is a custom range entry.
bool testCustomElement(SelectEntry e) => e is SelectRangeEntry && e.isCustom;

/// Returns true if the entry is not a custom range entry.
bool testNotCustomItem(SelectEntry e) =>
    e is! SelectRangeEntry || (!e.isCustom);

/// Returns true if the entry has the same parent as the given [parentId].
bool testSameParentElement(SelectEntry e, String parentId) =>
    (e as SelectChildEntry).parentId == parentId;

/// Returns true if the entry has the same parent as the given [parentId] and is an "Any" or a custom range entry.
bool testSameParentAnyOrCustomElement(SelectEntry e, String parentId) =>
    (e as SelectChildEntry).parentId == parentId &&
    (e.isAny || (e is SelectRangeEntry && e.isCustom));

extension IterableExtension on Iterable<SelectEntry> {
  /// Whether this iterable contains an "Any" child entry.
  bool get hasAnyItem => any(testAnyElement);

  /// Whether this iterable contains a custom range entry.
  bool get hasCustomItem => any(testCustomElement);

  /// Returns the first element if it is a custom range entry.
  SelectRangeEntry? get firstCustomOrNull {
    final element = firstOrNull;
    if (element != null && element is SelectRangeEntry && element.isCustom) {
      return element;
    }
    return null;
  }

  /// Returns the last element if it is a custom range entry.
  SelectRangeEntry? get lastCustomOrNull {
    final element = lastOrNull;
    if (element != null && element is SelectRangeEntry && element.isCustom) {
      return element;
    }
    return null;
  }
}
