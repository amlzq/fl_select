import 'constants.dart';
import 'select_layout.dart';
import 'select_utils.dart';

/// A set of selected [SelectEntry] values.
typedef SelectEntries<E> = Set<SelectEntry<E>>;

extension SelectEntriesExtension on SelectEntries {
  /// Inserts [entry] at the given [index] while preserving set iteration order.
  void insert(int index, SelectEntry entry) {
    final temp = toList();
    temp.insert(index, entry);
    clear();
    addAll(temp);
  }

  /// Flattens a selection tree into a list of selections per depth level.
  List<SelectEntries>? flatten() {
    if (isEmpty) return null;

    List<SelectEntries> result = [];
    void traverse(SelectEntries entries, int level) {
      if (result.length <= level) {
        result.add({});
      }
      for (var entry in entries) {
        result[level].add(entry);
        if (entry is SelectCategoryEntry) {
          final header = entry.header;
          final headerChildren = header?.children;
          if (header != null &&
              headerChildren != null &&
              headerChildren.isNotEmpty) {
            traverse({header}, level + 1);
          }

          final footer = entry.footer;
          final footerChildren = footer?.children;
          if (footer != null &&
              footerChildren != null &&
              footerChildren.isNotEmpty) {
            traverse({footer}, level + 1);
          }
        }
        if (entry.children != null && entry.children!.isNotEmpty) {
          traverse(entry.children!, level + 1);
        }
      }
    }

    traverse(this, 0);
    return result;
  }

  /// Finds the first selected top-level entry (category) whose [id] matches
  /// [categoryId], or `null` if no such category is selected.
  ///
  /// This is the entry point for most of the convenience query helpers below.
  /// Because it lives on this extension it is available on a bare
  /// [SelectEntries] — e.g. the return value of `showSelect` /
  /// `showModalBottomSelect`.
  SelectEntry? findCategory(String categoryId) =>
      where((e) => e.id == categoryId).firstOrNull;

  /// Returns the ids of all direct children of the category with [categoryId].
  ///
  /// Returns an empty list when the category is not selected or has no
  /// children. Equivalent to iterating `category.children` and collecting
  /// each `e.id`.
  List<String> childIdsOf(String categoryId) {
    final category = findCategory(categoryId);
    if (category?.children == null) return const [];
    return category!.children!.map((e) => e.id).toList(growable: false);
  }

  /// Returns all direct children of the category with [categoryId] that are
  /// [SelectRangeEntry] values (e.g. price/area ranges carrying `min`/`max`).
  ///
  /// Returns an empty list when the category is not selected or has no range
  /// children. The returned entries expose `min`/`max` as `dynamic`, so
  /// callers can cast them to the expected numeric type as needed.
  List<SelectRangeEntry> childRangesOf(String categoryId) {
    final category = findCategory(categoryId);
    if (category?.children == null) return const [];
    return category!.children!
        .whereType<SelectRangeEntry>()
        .toList(growable: false);
  }

  /// Returns parent → child-id pairs for a cascading category
  /// (e.g. region/metro with districts and sub-districts).
  ///
  /// Each record carries the parent's [id] and a [childIds] list of the ids of
  /// its direct children. Returns an empty list when the category is not
  /// selected or has no children.
  List<({String id, List<String> childIds})> cascadingPairsOf(
    String categoryId,
  ) {
    final category = findCategory(categoryId);
    if (category?.children == null) return const [];
    return category!.children!.map((parent) {
      final childIds = (parent.children ?? const <SelectEntry>[])
          .map((c) => c.id)
          .toList(growable: false);
      return (id: parent.id, childIds: childIds);
    }).toList(growable: false);
  }

  /// Returns the child entries of [entry] located at the given tree [level].
  ///
  /// A level of `0` returns [entry] itself; level `1` returns its direct
  /// children; deeper levels walk further down the tree.
  Set<SelectEntry> findChildrenAtLevel(SelectEntry entry, int level) =>
      SelectUtils.findChildrenAtLevel(entry, level);

  /// Returns the ids of the children of [entry] located at the given tree [level].
  ///
  /// See [findChildrenAtLevel] for the level semantics.
  Set<String> findIdsAtLevel(SelectEntry entry, int level) =>
      SelectUtils.findIdsAtLevel(entry, level);

  /// Returns the extra ids of the children of [entry] located at the given tree
  /// [level].
  ///
  /// See [findChildrenAtLevel] for the level semantics.
  List<String> findExtrasAtLevel(SelectEntry entry, int level) =>
      SelectUtils.findExtrasAtLevel(entry, level);

  /// Returns the id of the first selected entry, or `null` when nothing is
  /// selected. Convenience accessor for single-selection tabs such as sort
  /// order.
  String? get firstSelectedId => firstOrNull?.id;
}

/// Special entry id representing the "Any" entry.
const kAnyEntryId = 'any';

/// Special entry id representing a user-provided/custom value.
const kCustomEntryId = 'custom';

/// Convenience alias for an integer range entry.
typedef SelectIntEntry<E> = SelectRangeEntry<int, E>;

// typedef SelectDoubleOption<E> = SelectRangeEntry<double, E>;

// typedef SelectDateTimeOption<E> = SelectRangeEntry<DateTime, E>;

/// A range-based entry (e.g. min/max).
///
/// This is commonly used for numeric ranges such as price or area.
class SelectRangeEntry<N, E> extends SelectChildEntry<E> {
  /// Creates a range entry.
  ///
  /// [parentId] must be correct and non-empty: it has to equal the id of the
  /// entry's owning parent (a category or a header/footer node). Passing an
  /// empty string breaks the parent-child relationship and makes the entry
  /// unselectable in a 2D-or-deeper structure.
  SelectRangeEntry({
    this.min,
    this.max,
    this.divisions,
    this.inputLabel,
    this.minHintText,
    this.maxHintText,
    required super.parentId,
    required super.id,
    required super.name,
    super.children,
    super.enabled,
    super.immediate,
    super.extra,
  });

  /// The minimum value of the range.
  N? min;

  /// The maximum value of the range.
  N? max;

  /// Optional step count for range-slider UIs.
  ///
  /// When set, [SelectRangeSlider] snaps the released handle positions
  /// to the nearest multiple of `(max - min) / divisions`. The track is
  /// **not** decorated with tick marks regardless of this value.
  ///
  /// `null` (the default) keeps the slider continuous and is fully
  /// backward-compatible with existing code.
  int? divisions;

  /// An optional label for the input field(s) representing this range.
  final String? inputLabel;

  /// Hint text shown for the minimum value input field.
  final String? minHintText;

  /// Hint text shown for the maximum value input field.
  final String? maxHintText;

  /// Custom range entry
  /// This entry is usually rendered as an input field or a slider/progress bar in the UI.
  ///
  /// [parentId] must be correct and non-empty: it has to equal the id of the
  /// entry's owning parent (a category or a header/footer node). An empty
  /// string breaks the parent-child relationship and leaves the entry
  /// unselectable in a 2D-or-deeper structure.
  SelectRangeEntry.custom({
    this.min,
    this.max,
    this.divisions,
    this.inputLabel,
    this.minHintText,
    this.maxHintText,
    required super.parentId,
    super.name,
    super.enabled,
    super.immediate,
  }) : super(
          id: kCustomEntryId,
        );

  /// "Any" entry
  ///
  /// [parentId] must be correct and non-empty: it has to equal the id of the
  /// entry's owning parent (a category or a header/footer node). An empty
  /// string breaks the parent-child relationship and leaves the entry
  /// unselectable in a 2D-or-deeper structure.
  SelectRangeEntry.any({
    this.min,
    this.max,
    this.divisions,
    this.inputLabel,
    this.minHintText,
    this.maxHintText,
    required super.parentId,
    required super.name,
    super.enabled,
    super.immediate,
  }) : super.any();

  @override
  SelectRangeEntry<N, E> copyWith({
    String? parentId,
    String? id,
    String? name,
    Set<SelectEntry<E>>? children,
    bool? enabled,
    bool? immediate,
    E? extra,
    N? min,
    N? max,
    int? divisions,
    String? inputLabel,
    String? minHintText,
    String? maxHintText,
  }) {
    return SelectRangeEntry<N, E>(
      parentId: parentId ?? this.parentId,
      id: id ?? this.id,
      name: name ?? this.name,
      children: children ?? this.children,
      enabled: enabled ?? this.enabled,
      immediate: immediate ?? this.immediate,
      extra: extra ?? this.extra,
      min: min ?? this.min,
      max: max ?? this.max,
      divisions: divisions ?? this.divisions,
      inputLabel: inputLabel ?? this.inputLabel,
      minHintText: minHintText ?? this.minHintText,
      maxHintText: maxHintText ?? this.maxHintText,
    );
  }

  @override
  String toString() =>
      'SelectRangeEntry(id: $id, parentId: $parentId, name: $name, min: $min, max: $max, divisions: $divisions)';
}

extension SelectRangeEntryExt on SelectRangeEntry {
  /// Whether this entry represents a custom value input.
  bool get isCustom => id == kCustomEntryId;

  /// Whether the entry has any user-provided value.
  bool get hasCustomValue =>
      (min != null && min.toString().isNotEmpty) ||
      (max != null && max.toString().isNotEmpty);

  String get name => this.name ?? '$min-$max';
}

/// A plain text entry.
class SelectTextEntry<E> extends SelectChildEntry<E> {
  /// Creates a text entry.
  ///
  /// [parentId] must be correct and non-empty: it has to equal the id of the
  /// entry's owning parent (a category or a header/footer node). An empty
  /// string breaks the parent-child relationship and leaves the entry
  /// unselectable in a 2D-or-deeper structure.
  SelectTextEntry({
    required super.parentId,
    required super.id,
    required super.name,
    super.children,
    super.enabled,
    super.immediate,
  });

  /// Creates a text entry from only an [id], leaving [SelectChildEntry.parentId]
  /// empty and the name blank.
  ///
  /// This is a placeholder-style constructor intended for building an entry
  /// where the parent relationship is not (yet) known or required — for
  /// example a flat 1D structure. Because `parentId` is hard-coded to an empty
  /// string, it must not be used under a [SelectCategoryEntry]: in a 2D-or-
  /// deeper structure the `parentId` must point to the owning category id,
  /// otherwise the entry cannot be selected. Prefer the full constructor and
  /// set `parentId` explicitly when nesting under a category.
  SelectTextEntry.id({required super.id}) : super(parentId: '', name: '');

  /// Creates a leaf entry without a parent id.
  ///
  /// This convenience constructor hard-codes [SelectChildEntry.parentId] to an
  /// empty string, so it is only suitable for a flat 1D structure where the
  /// top level contains no [SelectCategoryEntry] (e.g. sort order).
  ///
  /// In a 2D-or-deeper structure (such as [GridSelect], [ListSelect],
  /// [FlattenSelect], or [CascadingSelect]) the child entry's `parentId` must
  /// point to its owning category id, otherwise it cannot be selected. Use the
  /// full constructor and set `parentId` explicitly instead.
  SelectTextEntry.name({
    required super.id,
    required super.name,
    super.enabled,
    super.immediate,
  }) : super(parentId: '');

  /// "Any" entry
  ///
  /// [parentId] must be correct and non-empty: it has to equal the id of the
  /// entry's owning parent (a category or a header/footer node). An empty
  /// string breaks the parent-child relationship and leaves the entry
  /// unselectable in a 2D-or-deeper structure.
  SelectTextEntry.any({
    required super.parentId,
    required super.name,
    super.enabled,
    super.immediate,
  }) : super.any();

  @override
  String toString() =>
      'SelectTextEntry(id: $id, parentId: $parentId, name: $name)';
}

/// A child entry (i.e. a non-root node).
class SelectChildEntry<E> extends SelectEntry<E> {
  SelectChildEntry({
    required this.parentId,
    required super.id,
    super.name,
    super.children,
    super.enabled,
    super.immediate,
    super.extra,
  });

  /// The id of this entry's parent category.
  final String parentId;

  /// "Any" entry
  SelectChildEntry.any({
    required this.parentId,
    required super.name,
    super.enabled,
    super.immediate,
    super.extra,
  }) : super(
          id: kAnyEntryId,
        );

  SelectChildEntry.empty({this.parentId = ''})
      : super(
          id: '',
          name: null,
          children: null,
          enabled: true,
          immediate: false,
          extra: null,
        );

  SelectChildEntry<E> copyWith({
    String? parentId,
    String? id,
    String? name,
    Set<SelectEntry<E>>? children,
    bool? enabled,
    bool? immediate,
    E? extra,
  }) {
    return SelectChildEntry<E>(
      parentId: parentId ?? this.parentId,
      id: id ?? this.id,
      name: name ?? this.name,
      children: children ?? this.children,
      enabled: enabled ?? this.enabled,
      immediate: immediate ?? this.immediate,
      extra: extra ?? this.extra,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SelectChildEntry<E> &&
            runtimeType == other.runtimeType &&
            other.id == id &&
            other.parentId == parentId &&
            other.name == name;
  }

  @override
  int get hashCode => Object.hash(id, parentId, name);

  @override
  String toString() =>
      'SelectChildEntry(id: $id, parentId: $parentId, name: $name)';
}

extension SelectChildEntryExt on SelectChildEntry {
  /// Whether this entry is the special "Any" entry.
  bool get isAny => id == kAnyEntryId;

  /// Whether this entry is a placeholder with an empty id.
  bool get isEmpty => id.isEmpty;

  /// Whether this entry has a non-empty id.
  bool get isNotEmpty => id.isNotEmpty;
}

/// A category entry (i.e. a root node).
class SelectCategoryEntry<E> extends SelectEntry<E> {
  SelectCategoryEntry({
    this.selectionMode = SelectionMode.single,
    this.header,
    this.headerSelectionMode = SelectionMode.single,
    this.footer,
    this.footerSelectionMode = SelectionMode.single,
    this.layout,
    required super.id,
    required super.name,
    required super.children,
    super.enabled,
    super.immediate,
  });

  /// The selection mode applied to this category's children.
  ///
  /// Defaults to [SelectionMode.single].
  final SelectionMode selectionMode;

  /// An optional header entry rendered above this category's children.
  SelectEntry<E>? header;

  /// The selection mode applied to [header].
  ///
  /// Defaults to [SelectionMode.single].
  final SelectionMode headerSelectionMode;

  /// An optional footer entry rendered below this category's children.
  SelectEntry<E>? footer;

  /// The selection mode applied to [footer].
  ///
  /// Defaults to [SelectionMode.single].
  final SelectionMode footerSelectionMode;

  /// The layout used to render this category's children.
  ///
  /// When `null`, a default [SelectListLayout] is used at render time.
  final SelectLayout? layout;

  SelectCategoryEntry<E> copyWith({
    String? id,
    String? name,
    Set<SelectEntry<E>>? children,
    bool? enabled,
    bool? immediate,
    SelectionMode? selectionMode,
    SelectEntry<E>? header,
    SelectionMode? headerSelectionMode,
    SelectEntry<E>? footer,
    SelectionMode? footerSelectionMode,
    SelectLayout? layout,
  }) {
    return SelectCategoryEntry<E>(
      id: id ?? this.id,
      name: name ?? this.name,
      children: children ?? this.children,
      enabled: enabled ?? this.enabled,
      immediate: immediate ?? this.immediate,
      selectionMode: selectionMode ?? this.selectionMode,
      header: header ?? this.header,
      headerSelectionMode: headerSelectionMode ?? this.headerSelectionMode,
      footer: footer ?? this.footer,
      footerSelectionMode: footerSelectionMode ?? this.footerSelectionMode,
      layout: layout ?? this.layout,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SelectCategoryEntry<E> &&
            runtimeType == other.runtimeType &&
            other.id == id &&
            other.name == name &&
            other.selectionMode == selectionMode &&
            other.layout == layout;
  }

  @override
  int get hashCode => Object.hash(id, name, selectionMode, layout);

  @override
  String toString() =>
      'SelectCategoryEntry(id: $id, name: $name, selectionMode: $selectionMode, header: $header, footer: $footer, layout: $layout, children: $children)';
}

extension SelectCategoryEntryExtension on SelectCategoryEntry {
  bool get hasCustomOrNull =>
      firstCustomOrNull != null || lastCustomOrNull != null;

  /// Returns the first child if it is a custom range entry.
  SelectRangeEntry? get firstCustomOrNull {
    final element = children?.firstOrNull;
    if (element != null && element is SelectRangeEntry && element.isCustom) {
      return element;
    }
    return null;
  }

  /// Returns the last child if it is a custom range entry.
  SelectRangeEntry? get lastCustomOrNull {
    final element = children?.lastOrNull;
    if (element != null && element is SelectRangeEntry && element.isCustom) {
      return element;
    }
    return null;
  }
}

/// Base class for all select entries.
///
/// Entries form a tree: [SelectCategoryEntry] is typically the root and
/// [SelectChildEntry] represents non-root nodes.
abstract class SelectEntry<E> {
  SelectEntry({
    required this.id,
    this.name,
    this.children,
    this.enabled = true,
    this.immediate = false,
    this.extra,
  });

  /// The unique identifier of this entry within its parent.
  final String id;

  /// The display name of this entry.
  String? name;

  /// The child entries of this entry, or null if it is a leaf.
  final Set<SelectEntry<E>>? children;

  /// Whether this entry can be selected or interacted with.
  ///
  /// Defaults to true. When false, the entry is rendered as disabled.
  final bool enabled;

  /// If true, selecting this node will immediately apply the entry without needing to click the "Apply" button.
  ///
  /// Defaults to false. If the node's id is [kAnyEntryId] and the node's data
  /// is empty, the effective value becomes true. In single-selection mode this
  /// value is ignored and the entry is applied immediately.
  final bool immediate;

  /// Optional arbitrary data attached to this entry.
  final E? extra;

  @override
  String toString() => 'SelectEntry(id: $id, name: $name, children: $children)';
}

extension SelectEntryExt on SelectEntry {
  /// Returns the first child entry if present.
  SelectEntry? get firstChild => children?.firstOrNull;

  /// Returns the last child entry if present.
  SelectEntry? get lastChild => children?.lastOrNull;

  /// Whether this entry has any children.
  bool get hasChildren => children?.isNotEmpty ?? false;

  // bool get selected => data?.any((e) => e.selected) ?? false;

  /// Depth of the tree structure.
  int get maxLevel {
    // If there are no children, this is a leaf node and the depth is 1.
    if (children == null || children!.isEmpty) {
      return 1;
    }

    // Child max depth + 1 is the current node depth.
    int childMaxLevel = 0;

    for (var c in children!) {
      childMaxLevel = childMaxLevel > c.maxLevel ? childMaxLevel : c.maxLevel;
    }
    return childMaxLevel + 1;
  }
}
