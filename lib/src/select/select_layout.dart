import 'package:flutter/foundation.dart';

/// Sealed layout descriptor for the children of a [SelectCategoryEntry].
///
/// Select the layout of a category's children via a single `layout` property.
/// Use a [SelectListLayout] for a vertical list, [SelectGridLayout] for a
/// grid, or [SelectChipLayout] for a wrap of chips.
///
/// Because the class is `sealed`, the compiler can exhaustively check `switch`
/// statements over [SelectLayout], so adding a new layout later is a
/// compile-time-safe change.
@immutable
sealed class SelectLayout {
  const SelectLayout();
}

/// Vertical list layout for the children of a [SelectCategoryEntry].
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
class SelectChipLayout extends SelectLayout {
  const SelectChipLayout();

  @override
  bool operator ==(Object other) => other is SelectChipLayout;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// Counter (spin-box) layout for the children of a [SelectCategoryEntry].
///
/// Use this layout to render a single-valued "stepper": a `-` button on the
/// left, the current value in the middle and a `+` button on the right. The
/// user steps through the category's child entries (e.g. "Any", "1", "1+",
/// "2", "2+", ...). At the two extremes the corresponding button is disabled.
class SelectCounterLayout extends SelectLayout {
  const SelectCounterLayout();

  @override
  bool operator ==(Object other) => other is SelectCounterLayout;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// Range-slider layout for the children of a [SelectCategoryEntry].
///
/// Use this layout when a category owns a single custom [SelectRangeEntry]
/// and you want to render it as a "price-range" style control: a
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
