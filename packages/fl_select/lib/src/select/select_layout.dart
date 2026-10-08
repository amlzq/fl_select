import 'package:flutter/foundation.dart';

/// Sealed layout descriptor for the children of a [SelectCategoryEntry].
///
/// Select the layout of a category's children via a single `layout` property.
/// Each layout subclass maps to a specific widget and entry type:
///
/// * [SelectListLayout] → the list view (handles all [SelectEntry] subtypes)
/// * [SelectGridLayout] → the grid view (handles all [SelectEntry] subtypes)
/// * [SelectWrapLayout] → the chip bar (handles all [SelectEntry] subtypes)
/// * [SelectCounterLayout] → the counter (handles [SelectTextEntry])
/// * [SelectRangeLayout] → the range view (handles [SelectRangeEntry])
/// * [SelectCascadingLayout] → the cascading view (handles [SelectChildEntry]
///   trees, drilling down one column per level)
///
/// Depth: every layout renders the category's direct children, and only
/// [SelectListLayout], [SelectGridLayout], [SelectWrapLayout],
/// [SelectCounterLayout] and [SelectRangeLayout] stop there: they are fixed to
/// one level and never expand a child's own `children`. [SelectCascadingLayout]
/// is the only unlimited one — it appends a column per level whenever a branch
/// entry is tapped.
///
/// Because the class is `sealed`, the compiler can exhaustively check `switch`
/// statements over [SelectLayout], so adding a new layout later is a
/// compile-time-safe change.
@immutable
sealed class SelectLayout {
  const SelectLayout();
}

/// Vertical list layout for the children of a [SelectCategoryEntry].
///
/// Rendered by the list view, which handles all [SelectEntry] subtypes:
/// [SelectTextEntry] and non-custom [SelectRangeEntry] as selectable tiles,
/// plus a custom [SelectRangeEntry] as an input field.
///
/// Fixed to one level: only the category's direct children are laid out, and a
/// child's own `children` are not expanded.
class SelectListLayout extends SelectLayout {
  const SelectListLayout({this.toText = '-'});

  /// Text rendered between the two text fields (default: `'-'`).
  final String toText;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SelectListLayout && toText == other.toText;

  @override
  int get hashCode => toText.hashCode;
}

/// Grid layout for the children of a [SelectCategoryEntry].
///
/// Rendered by the grid view, which handles all [SelectEntry] subtypes:
/// [SelectTextEntry] and non-custom [SelectRangeEntry] as selectable tiles,
/// plus a custom [SelectRangeEntry] as an input field.
///
/// Fixed to one level: only the category's direct children are laid out, and a
/// child's own `children` are not expanded.
class SelectGridLayout extends SelectLayout {
  const SelectGridLayout({
    required this.crossAxisCount,
    this.mainAxisSpacing = 0.0,
    this.crossAxisSpacing = 0.0,
    this.childAspectRatio = 1.0,
    this.toText = '-',
  });

  /// The number of children in the cross axis.
  final int crossAxisCount;

  /// The spacing between children in the main axis.
  final double mainAxisSpacing;

  /// The spacing between children in the cross axis.
  final double crossAxisSpacing;

  /// The ratio of the cross-axis to the main-axis extent of each child.
  final double childAspectRatio;

  /// Text rendered between the two text fields (default: `'-'`).
  final String toText;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SelectGridLayout &&
          crossAxisCount == other.crossAxisCount &&
          mainAxisSpacing == other.mainAxisSpacing &&
          crossAxisSpacing == other.crossAxisSpacing &&
          childAspectRatio == other.childAspectRatio &&
          toText == other.toText;

  @override
  int get hashCode => Object.hash(
    crossAxisCount,
    mainAxisSpacing,
    crossAxisSpacing,
    childAspectRatio,
    toText,
  );
}

/// Wrap of chips layout for the children of a [SelectCategoryEntry].
///
/// Rendered by the wrap view, which handles all [SelectEntry] subtypes
/// using their [SelectEntry.name] as the chip label.
///
/// Fixed to one level: only the category's direct children are laid out, and a
/// child's own `children` are not expanded.
class SelectWrapLayout extends SelectLayout {
  const SelectWrapLayout({this.spacing = 0.0, this.runSpacing = 0.0});

  /// Horizontal spacing between chips in the wrap.
  final double spacing;

  /// Vertical spacing between wrapped chip rows.
  final double runSpacing;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SelectWrapLayout &&
          spacing == other.spacing &&
          runSpacing == other.runSpacing;

  @override
  int get hashCode => Object.hash(spacing, runSpacing);
}

/// Counter (spin-box) layout for the children of a [SelectCategoryEntry].
///
/// Rendered by the counter, which filters entries for [SelectTextEntry]
/// and steps through them: a `-` button on the left, the current value in the
/// middle and a `+` button on the right. The user steps through the text
/// entries (e.g. "Any", "1", "1+", "2", "2+", ...). At the two extremes the
/// corresponding button is disabled.
///
/// Fixed to one level: only the category's direct children are stepped through,
/// and a child's own `children` are not expanded.
class SelectCounterLayout extends SelectLayout {
  const SelectCounterLayout();

  @override
  bool operator ==(Object other) => other is SelectCounterLayout;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// Cascading (multi-column) layout for the children of a
/// [SelectCategoryEntry].
///
/// Unlimited depth: the only layout that expands nested `children`, one column
/// per level.
///
/// Rendered by the cascading view, which starts with the category's children as
/// the first column and appends a column to the right every time a branch entry
/// is tapped, so the user can drill down (child → grandchild → …). The columns
/// read and write the selection through
/// [SelectController.selectedEntriesAtLevel] /
/// [SelectController.toggleCascadingEntry], which means the same cascade
/// semantics as [CascadingSelect] apply — including the `Any` level-skip and the
/// per-column selected-count badges.
///
/// Unlike the other layouts this one owns its own navigation state, so the
/// category's content view passes the entries and reads the result back.
class SelectCascadingLayout extends SelectLayout {
  const SelectCascadingLayout({this.isScrollable = false});

  /// Whether the cascade scrolls horizontally when the columns overflow the
  /// available width.
  ///
  /// When true every column keeps its natural (measured) width, the row is
  /// wrapped in a horizontal scroll view and revealing a new column sweeps to
  /// its end — the same behaviour as `CascadingSelectDelegate.isScrollable`.
  /// When false (the default) the columns divide the available width equally.
  final bool isScrollable;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SelectCascadingLayout && isScrollable == other.isScrollable;

  @override
  int get hashCode => isScrollable.hashCode;
}

/// Range-slider layout for the children of a [SelectCategoryEntry].
///
/// Rendered by the range view, which reads min/max from a single
/// [SelectRangeEntry] and renders it as a "price-range" style control: a
/// range slider on top of two synced text fields.
///
/// The category is expected to expose exactly one custom range entry
/// ([SelectCategoryEntryExtension.firstCustomOrNull]); if none is found, the
/// view falls back to a degenerate 0..1 range.
///
/// Fixed to one level: the range is read from the category's direct children,
/// and a child's own `children` are not expanded.
class SelectRangeLayout extends SelectLayout {
  const SelectRangeLayout({this.toText = '-'});

  /// Text rendered between the two text fields (default: `'to'`).
  final String toText;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SelectRangeLayout && toText == other.toText;

  @override
  int get hashCode => toText.hashCode;
}
