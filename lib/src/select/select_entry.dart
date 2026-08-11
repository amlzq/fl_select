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
  /// When used inside [SelectCategoryEntry.children], the `parentId` is
  /// automatically injected — prefer using [SelectCategoryEntry.children] for
  /// 2D+ trees so you never need to write `parentId` by hand.
  SelectRangeEntry({
    this.min,
    this.max,
    this.divisions,
    this.inputLabel,
    this.minHintText,
    this.maxHintText,
    super.parentId = '',
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
  /// When used inside [SelectCategoryEntry.children], the `parentId` is
  /// automatically injected.
  SelectRangeEntry.custom({
    this.min,
    this.max,
    this.divisions,
    this.inputLabel,
    this.minHintText,
    this.maxHintText,
    super.parentId = '',
    super.name,
    super.enabled,
    super.immediate,
  }) : super(
          id: kCustomEntryId,
        );

  /// "Any" entry
  ///
  /// When used inside [SelectCategoryEntry.children], the `parentId` is
  /// automatically injected.
  SelectRangeEntry.any({
    this.min,
    this.max,
    this.divisions,
    this.inputLabel,
    this.minHintText,
    this.maxHintText,
    super.parentId = '',
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
  /// When used inside [SelectCategoryEntry.children], the `parentId` is
  /// automatically injected — prefer using [SelectCategoryEntry.children] for
  /// 2D+ trees so you never need to write `parentId` by hand.
  SelectTextEntry({
    required super.parentId,
    required super.id,
    required super.name,
    super.children,
    super.enabled,
    super.immediate,
    super.extra,
  });

  /// Creates a text entry from only an [id], leaving [SelectChildEntry.parentId]
  /// empty and the name blank.
  ///
  /// This is a placeholder-style constructor for building an entry where the
  /// parent relationship is not (yet) known. When used inside
  /// [SelectCategoryEntry.children], the `parentId` is automatically injected
  /// by the category, making this constructor safe for both 1D and 2D+ trees:
  ///
  /// ```dart
  /// SelectCategoryEntry.children(
  ///   id: 'c1',
  ///   name: 'Category 1',
  ///   children: {
  ///     SelectTextEntry.id(id: 'a'),       // parentId auto-injected
  ///     SelectTextEntry.name(id: 'b', name: 'B'),
  ///   },
  /// )
  /// ```
  ///
  /// If you use the plain [SelectCategoryEntry] constructor (without
  /// auto-injection), the `parentId` must be set explicitly on every child.
  SelectTextEntry.id({required super.id}) : super(parentId: '', name: '');

  /// Creates a leaf entry without a parent id.
  ///
  /// This convenience constructor hard-codes [SelectChildEntry.parentId] to an
  /// empty string, so it is only suitable for a flat 1D structure where the
  /// top level contains no [SelectCategoryEntry] (e.g. sort order).
  ///
  /// When used inside [SelectCategoryEntry.children], the `parentId` is
  /// automatically injected by the category — you do **not** need to set it
  /// manually. This is the recommended approach for 2D+ trees:
  ///
  /// ```dart
  /// SelectCategoryEntry.children(
  ///   id: 'c3',
  ///   name: 'Category 3',
  ///   children: {
  ///     SelectTextEntry.name(id: 'a', name: 'A'), // parentId auto-injected
  ///     SelectTextEntry.name(id: 'b', name: 'B'),
  ///   },
  /// )
  /// ```
  ///
  /// If you use the plain [SelectCategoryEntry] constructor, you must set
  /// `parentId` explicitly via the full [SelectTextEntry] constructor.
  SelectTextEntry.name({
    required super.id,
    required super.name,
    super.enabled,
    super.immediate,
  }) : super(parentId: '');

  /// Creates a text entry and automatically injects [id] as the
  /// [SelectChildEntry.parentId] of every child in [children], recursively.
  ///
  /// This is a convenience counterpart of [SelectChildEntry.children] that
  /// preserves the concrete [SelectTextEntry] type. Use it for 3D-or-deeper
  /// structures where the node itself is a plain text entry that also carries
  /// children:
  ///
  /// ```dart
  /// SelectChildEntry.children(
  ///   id: 'p',
  ///   name: 'Parent',
  ///   children: {
  ///     SelectTextEntry.children(
  ///       id: 'a',
  ///       name: 'A',
  ///       children: {
  ///         SelectTextEntry.name(id: 'a1', name: 'A1'),
  ///       },
  ///     ),
  ///   },
  /// )
  /// ```
  ///
  /// This entry's own [SelectChildEntry.parentId] is left empty (`''`) here —
  /// it is meant to be injected by the parent it is later placed into, so it
  /// is not requested from you.
  ///
  /// If you use this constructor, children should **not** set their own
  /// `parentId` — the injected value always wins.
  ///
  /// For fine-grained control (e.g. when children are pre-built and already
  /// carry the correct `parentId`), use the default [SelectTextEntry]
  /// constructor directly.
  factory SelectTextEntry.children({
    required String id,
    required String name,
    required Set<SelectEntry<E>> children,
    bool enabled = true,
    bool immediate = false,
    E? extra,
  }) {
    final injectedChildren =
        children.map((e) => _injectParentId(e, id)).toSet();
    return SelectTextEntry<E>(
      parentId: '',
      id: id,
      name: name,
      children: injectedChildren,
      enabled: enabled,
      immediate: immediate,
      extra: extra,
    );
  }

  /// "Any" entry
  ///
  /// When used inside [SelectCategoryEntry.children], the `parentId` is
  /// automatically injected.
  SelectTextEntry.any({
    required super.parentId,
    required super.name,
    super.enabled,
    super.immediate,
  }) : super.any();

  /// Returns a copy of this entry with the given fields replaced, preserving
  /// the concrete [SelectTextEntry] type.
  ///
  /// Overriding [SelectChildEntry.copyWith] here is important: when
  /// [SelectCategoryEntry.children] auto-injects the [SelectChildEntry.parentId],
  /// it calls `copyWith` on each child. The base implementation returns a
  /// plain [SelectChildEntry], which would lose the `SelectTextEntry` type and
  /// break callers that filter by concrete type (e.g. [SelectCounter] using
  /// `whereType<SelectTextEntry>()`).
  @override
  SelectTextEntry<E> copyWith({
    String? parentId,
    String? id,
    String? name,
    Set<SelectEntry<E>>? children,
    bool? enabled,
    bool? immediate,
    E? extra,
  }) {
    return SelectTextEntry<E>(
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
  ///
  /// When the entry is created inside [SelectCategoryEntry.children], this
  /// value is automatically injected by the category — there is no need to
  /// set it manually.
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

  /// Creates a child entry and automatically injects [id] as the
  /// [SelectChildEntry.parentId] of every child in [children], recursively.
  ///
  /// This is the recommended constructor for 3D-or-deeper structures. Because
  /// `parentId` is filled in by the entry itself, you never need to manually
  /// set it on the children — eliminating copy-paste mistakes and
  /// forgetting-to-set errors:
  ///
  /// ```dart
  /// SelectChildEntry.children(
  ///   id: 'p',
  ///   name: 'Parent',
  ///   children: {
  ///     SelectTextEntry.name(id: 'a', name: 'A'),
  ///     SelectTextEntry.name(id: 'b', name: 'B'),
  ///   },
  /// )
  /// ```
  ///
  /// This entry's own [SelectChildEntry.parentId] is left empty (`''`) here —
  /// it is meant to be injected by the parent it is later placed into (via
  /// `SelectCategoryEntry.children` / `SelectChildEntry.children` / a
  /// `SelectTextEntry.children`), so it is not requested from you.
  ///
  /// If you use this constructor, children should **not** set their own
  /// `parentId` — the injected value always wins.
  ///
  /// For fine-grained control (e.g. when children are pre-built and already
  /// carry the correct `parentId`), use the default [SelectChildEntry]
  /// constructor directly.
  factory SelectChildEntry.children({
    required String id,
    String? name,
    required Set<SelectEntry<E>> children,
    bool enabled = true,
    bool immediate = false,
    E? extra,
  }) {
    final injectedChildren =
        children.map((e) => _injectParentId(e, id)).toSet();
    return SelectChildEntry<E>(
      parentId: '',
      id: id,
      name: name,
      children: injectedChildren,
      enabled: enabled,
      immediate: immediate,
      extra: extra,
    );
  }

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

/// Recursively injects [parentId] into [entry] and all of its descendants,
/// setting each `SelectChildEntry.parentId` to the id of its **direct**
/// parent node (and rewriting generic [SelectEntry] instances into child
/// entries so they can carry a parent).
///
/// Shared by the [SelectChildEntry.children], [SelectTextEntry.children] and
/// [SelectCategoryEntry.children] factory constructors, which all use their
/// own `id` as the [parentId] of their children so callers never have to write
/// `parentId` by hand. Because injection recurses with each node's own id, the
/// resulting `parentId` always matches the node's direct parent — which
/// `SelectController.validateEntries` requires for 2D-or-deeper trees.
SelectEntry<E> _injectParentId<E>(SelectEntry<E> entry, String parentId) {
  if (entry is SelectChildEntry<E>) {
    final injected = entry.copyWith(parentId: parentId);
    // The direct parent of injected's children is injected itself, so their
    // parentId is injected's own id — not the parentId passed in above.
    final injectedChildren =
        injected.children?.map((e) => _injectParentId(e, injected.id)).toSet();
    return injected.copyWith(children: injectedChildren);
  }
  // For a non-child entry (a SelectCategoryEntry or a generic SelectEntry),
  // its children's direct parent is the entry itself, so recurse with entry.id.
  final injectedChildren =
      entry.children?.map((e) => _injectParentId(e, entry.id)).toSet();
  if (entry is SelectCategoryEntry<E>) {
    final injectedHeader =
        entry.header != null ? _injectParentId(entry.header!, entry.id) : null;
    final injectedFooter =
        entry.footer != null ? _injectParentId(entry.footer!, entry.id) : null;
    return entry.copyWith(
      children: injectedChildren,
      header: injectedHeader,
      footer: injectedFooter,
    );
  }
  // For generic SelectEntry subclasses, children is the only child
  // relationship we can inject.
  return SelectChildEntry<E>(
    parentId: parentId,
    id: entry.id,
    name: entry.name,
    children: injectedChildren,
    enabled: entry.enabled,
    immediate: entry.immediate,
    extra: entry.extra,
  );
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

  /// Creates a category entry and automatically injects [id] as the
  /// [SelectChildEntry.parentId] of every child in [children], as well as
  /// any [header]/[footer] and their recursive children.
  ///
  /// This is the recommended constructor for 2D-or-deeper structures. Because
  /// `parentId` is filled in by the category itself, you never need to
  /// manually set it on the children — eliminating copy-paste mistakes and
  /// forgetting-to-set errors:
  ///
  /// ```dart
  /// SelectCategoryEntry.children(
  ///   id: 'c3',
  ///   name: 'Category 3',
  ///   children: {
  ///     SelectTextEntry.name(id: 'a', name: 'A'),
  ///     SelectTextEntry.name(id: 'b', name: 'B'),
  ///   },
  ///   layout: const SelectListLayout(),
  /// )
  /// ```
  ///
  /// If you use this constructor, children, header, and footer entries should
  /// **not** set their own `parentId` — the injected value always wins.
  ///
  /// For fine-grained control (e.g. when children are pre-built and already
  /// carry the correct `parentId`), use the default [SelectCategoryEntry]
  /// constructor directly.
  factory SelectCategoryEntry.children({
    SelectionMode selectionMode = SelectionMode.single,
    SelectEntry<E>? header,
    SelectionMode headerSelectionMode = SelectionMode.single,
    SelectEntry<E>? footer,
    SelectionMode footerSelectionMode = SelectionMode.single,
    SelectLayout? layout,
    required String id,
    required String name,
    required Set<SelectEntry<E>> children,
    bool enabled = true,
    bool immediate = false,
  }) {
    final injectedChildren =
        children.map((e) => _injectParentId(e, id)).toSet();
    final injectedHeader = header != null ? _injectParentId(header, id) : null;
    final injectedFooter = footer != null ? _injectParentId(footer, id) : null;

    return SelectCategoryEntry<E>(
      selectionMode: selectionMode,
      headerSelectionMode: headerSelectionMode,
      footerSelectionMode: footerSelectionMode,
      layout: layout,
      id: id,
      name: name,
      children: injectedChildren,
      header: injectedHeader,
      footer: injectedFooter,
      enabled: enabled,
      immediate: immediate,
    );
  }

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
  /// When `null`, a default layout is used at render time:
  /// - [ListSelectDelegate] falls back to [SelectListLayout].
  /// - [GridSelectDelegate] falls back to a [SelectGridLayout] driven by the delegate.
  /// - [FlattenSelectDelegate] falls back to [SelectChipLayout].
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
