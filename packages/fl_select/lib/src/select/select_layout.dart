import 'package:flutter/foundation.dart';

/// Sealed layout descriptor for the children of a [SelectCategoryEntry].
///
/// Select the layout of a category's children via a single `layout` property.
/// Each layout subclass maps to a specific widget and entry type:
///
/// * [SelectListLayout] → [SelectListView] (handles all [SelectEntry] subtypes)
/// * [SelectGridLayout] → [SelectGridView] (handles all [SelectEntry] subtypes)
/// * [SelectWrapLayout] → [SelectChipBar] (handles all [SelectEntry] subtypes)
/// * [SelectCounterLayout] → [SelectCounter] (handles [SelectTextEntry])
/// * [SelectRangeLayout] → [SelectRangeView] (handles [SelectRangeEntry])
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
/// Rendered by [SelectListView], which handles all [SelectEntry] subtypes:
/// [SelectTextEntry] and non-custom [SelectRangeEntry] as selectable tiles,
/// plus a custom [SelectRangeEntry] as an input field.
class SelectListLayout extends SelectLayout {
  const SelectListLayout({
    this.toText = '-',
  });

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
/// Rendered by [SelectGridView], which handles all [SelectEntry] subtypes:
/// [SelectTextEntry] and non-custom [SelectRangeEntry] as selectable tiles,
/// plus a custom [SelectRangeEntry] as an input field.
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
  int get hashCode => Object.hash(crossAxisCount, mainAxisSpacing,
      crossAxisSpacing, childAspectRatio, toText);
}

/// Wrap of chips layout for the children of a [SelectCategoryEntry].
///
/// Rendered by [SelectChipBar], which handles all [SelectEntry] subtypes
/// using their [SelectEntry.name] as the chip label.
class SelectWrapLayout extends SelectLayout {
  const SelectWrapLayout({
    this.spacing = 12,
    this.runSpacing = 12,
  });

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

/// Deprecated alias of [SelectWrapLayout].
///
/// `SelectChipLayout` was renamed to [SelectWrapLayout] to align with the
/// wrap-style rendering (a wrapable [SelectChipBar]). The old name is kept
/// as a deprecated subclass of [SelectWrapLayout] for backward
/// compatibility and **will be removed in a future minor version**. The two
/// are fully interchangeable — equal values compare equal and render
/// identically — so migrating is a pure rename.
@Deprecated(
  'Use SelectWrapLayout instead. Will be removed in a future minor version.',
)
class SelectChipLayout extends SelectWrapLayout {
  /// Creates a deprecated chip wrap layout; use [SelectWrapLayout] instead.
  const SelectChipLayout({
    super.spacing,
    super.runSpacing,
  });
}

/// Counter (spin-box) layout for the children of a [SelectCategoryEntry].
///
/// Rendered by [SelectCounter], which filters entries for [SelectTextEntry]
/// and steps through them: a `-` button on the left, the current value in the
/// middle and a `+` button on the right. The user steps through the text
/// entries (e.g. "Any", "1", "1+", "2", "2+", ...). At the two extremes the
/// corresponding button is disabled.
class SelectCounterLayout extends SelectLayout {
  const SelectCounterLayout();

  @override
  bool operator ==(Object other) => other is SelectCounterLayout;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// Range-slider layout for the children of a [SelectCategoryEntry].
///
/// Rendered by [SelectRangeView], which reads min/max from a single
/// [SelectRangeEntry] and renders it as a "price-range" style control: a
/// [SelectRangeSlider] on top of two synced text fields.
///
/// The category is expected to expose exactly one
/// [SelectRangeEntry.firstCustomOrNull]; if none is found, the view falls
/// back to a degenerate 0..1 range.
class SelectRangeLayout extends SelectLayout {
  const SelectRangeLayout({
    this.toText = '-',
  });

  /// Text rendered between the two text fields (default: `'to'`).
  final String toText;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SelectRangeLayout && toText == other.toText;

  @override
  int get hashCode => toText.hashCode;
}
