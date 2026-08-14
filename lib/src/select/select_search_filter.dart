import 'select_entry.dart';

/// A predicate that decides whether [entry] matches [query].
///
/// Returns `true` when the entry should be included in the search results.
/// The default implementation matches [SelectEntry.name] (case-insensitive
/// substring). Provide a custom predicate to match against [SelectEntry.extra],
/// [SelectEntry.id], or any other field.
typedef SelectSearchPredicate = bool Function(
  SelectEntry entry,
  String query,
);

/// The default search predicate: case-insensitive substring match on
/// [SelectEntry.name]. Returns `true` when the name contains [query].
bool defaultSelectSearchPredicate(SelectEntry entry, String query) {
  final name = entry.name;
  if (name == null) return false;
  return name.toLowerCase().contains(query.toLowerCase());
}

/// Filters [entries] for the given [query], preserving the original tree
/// structure.
///
/// - For a flat 1D structure (no [SelectCategoryEntry] at the top level), the
///   top-level entries are filtered directly.
/// - For a 2D+ structure, the category tree is filtered recursively: a category
///   is kept when any of its descendants match, and only the matching branches
///   are retained.
///
/// [predicate] defaults to [defaultSelectSearchPredicate].
///
/// Returns the original [entries] when [query] is empty.
List<SelectEntry> filterEntriesForSearch(
  List<SelectEntry> entries,
  String query, {
  SelectSearchPredicate? predicate,
}) {
  if (query.isEmpty) return entries;
  final pred = predicate ?? defaultSelectSearchPredicate;

  final isCategoryTree = entries.firstOrNull is SelectCategoryEntry;
  if (!isCategoryTree) {
    return entries.where((e) => pred(e, query)).toList();
  }

  final result = <SelectEntry>[];
  for (final entry in entries) {
    if (entry is SelectCategoryEntry) {
      final filtered = _filterCategory(entry, query, pred);
      if (filtered != null) result.add(filtered);
    } else if (pred(entry, query)) {
      result.add(entry);
    }
  }
  return result;
}

/// Recursively filters a category. Returns `null` when neither the category
/// itself nor any descendant matches.
SelectCategoryEntry? _filterCategory(
  SelectCategoryEntry category,
  String query,
  SelectSearchPredicate predicate,
) {
  final filteredChildren = <SelectEntry>[];
  for (final child in category.children ?? const <SelectEntry>[]) {
    final filtered = _filterNode(child, query, predicate);
    if (filtered != null) filteredChildren.add(filtered);
  }

  // Keep the category when it matches directly or has matching descendants.
  if (filteredChildren.isEmpty && !predicate(category, query)) {
    return null;
  }

  return category.copyWith(children: filteredChildren.toSet());
}

/// Recursively filters a non-category node. Returns `null` when the node and
/// all its descendants are filtered out.
SelectEntry? _filterNode(
  SelectEntry entry,
  String query,
  SelectSearchPredicate predicate,
) {
  if (entry is SelectChildEntry) {
    final filteredChildren = <SelectEntry>[];
    for (final child in entry.children ?? const <SelectEntry>[]) {
      final filtered = _filterNode(child, query, predicate);
      if (filtered != null) filteredChildren.add(filtered);
    }

    if (filteredChildren.isEmpty) {
      // Leaf: keep only if it matches.
      return predicate(entry, query) ? entry : null;
    }

    // Internal node: keep when it matches or has matching descendants.
    if (filteredChildren.isNotEmpty) {
      return entry.copyWith(children: filteredChildren.toSet());
    }
    return predicate(entry, query) ? entry : null;
  }

  // Generic SelectEntry fallback.
  return predicate(entry, query) ? entry : null;
}
