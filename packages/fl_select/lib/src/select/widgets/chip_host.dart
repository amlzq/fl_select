import 'package:flutter/material.dart';

import '../constants.dart';
import '../select_delegate.dart';
import '../select_entry.dart';
import '../select_theme.dart';
import '../select_theme_data.dart';
import 'chip_bar_theme.dart';
import 'custom_range_host.dart';
import 'field_tile_theme.dart';

/// Default height of the single-row [SelectChipBar].
const kSelectChipBarHeight = 44.0;

/// A single selectable chip as rendered inside [SelectChipBar] and
/// [SelectWrapView].
///
/// Handles the filled/outlined [SelectChipVariant] treatments, the selected
/// and disabled color states and single-line label truncation. Exposed so
/// [SelectItemBuilder] implementations can reuse the exact default chip
/// visuals.
class SelectChip extends StatelessWidget {
  const SelectChip({
    super.key,
    required this.label,
    this.selected = false,
    required this.variant,
    required this.color,
    required this.selectedColor,
    required this.labelStyle,
    required this.selectedLabelStyle,
    this.enabled = true,
    required this.onTap,
  });

  final String label;

  final bool selected;

  final SelectChipVariant variant;

  final Color color;

  final Color selectedColor;

  final TextStyle labelStyle;

  final TextStyle selectedLabelStyle;

  final bool enabled;

  final GestureTapCallback onTap;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = enabled
        ? selected
            ? selectedColor
            : color
        : Colors.grey[500]!;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: variant == SelectChipVariant.filled ? effectiveColor : null,
          border: variant == SelectChipVariant.filled
              ? null
              : Border.all(color: effectiveColor, width: 1.2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: selected ? selectedLabelStyle : labelStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

/// Theme defaults shared by [SelectChipBar] and [SelectWrapView].
///
/// Not part of the package's public API surface; visible only because the
/// two chip views live in separate libraries.
class SelectChipBarDefaults extends SelectChipBarTheme {
  SelectChipBarDefaults(
    this.context, [
    SelectChipVariant? variant,
  ]) : super(variant: variant);

  final BuildContext context;

  late final SelectThemeData _theme = SelectTheme.of(context);

  late final TextTheme _textTheme = Theme.of(context).textTheme;

  @override
  Color? get backgroundColor => Colors.transparent;

  @override
  EdgeInsetsGeometry? get padding => EdgeInsets.zero;

  /// Default chip color based on [variant].
  ///
  /// Mirrors the grid tile defaults: a light tint derived from
  /// [SelectThemeData.onBackgroundColorHighest] toward white in light theme;
  /// blends surface colors for harmony in dark theme.
  @override
  Color? get chipColor {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      final blendAmount = variant == SelectChipVariant.outlined ? 0.2 : 0.35;
      return Color.lerp(
          _theme.backgroundColor, _theme.backgroundColorHighest, blendAmount);
    }
    if (variant == SelectChipVariant.outlined) {
      return Color.lerp(_theme.onBackgroundColorHighest, Colors.white, 0.55);
    }
    return Color.lerp(_theme.onBackgroundColorHighest, Colors.white, 0.8);
  }

  /// Default selected chip color.
  ///
  /// Blends with the background in dark theme for a harmonious look.
  @override
  Color? get selectedChipColor {
    final baseSelected = _theme.selectedColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return Color.lerp(_theme.backgroundColor, baseSelected, 0.35);
    }
    return baseSelected;
  }

  @override
  TextStyle? get labelStyle => _textTheme.labelLarge?.copyWith(
        color: _theme.onBackgroundColorHighest,
      );

  @override
  TextStyle? get selectedLabelStyle => _textTheme.labelLarge?.copyWith(
        color: _theme.onSelectedColor,
      );
}

/// The fully-resolved visual configuration of a chip view, produced by
/// [resolveSelectChipBarStyle].
class SelectChipBarStyle {
  const SelectChipBarStyle({
    required this.variant,
    required this.backgroundColor,
    required this.padding,
    required this.chipColor,
    required this.selectedChipColor,
    required this.labelStyle,
    required this.selectedLabelStyle,
  });

  final SelectChipVariant variant;

  final Color backgroundColor;

  final EdgeInsetsGeometry padding;

  final Color chipColor;

  final Color selectedChipColor;

  final TextStyle labelStyle;

  final TextStyle selectedLabelStyle;
}

/// Resolves the chip visual configuration through the standard three-level
/// fallback chain: widget parameter -> surrounding [SelectChipBarTheme] ->
/// [SelectChipBarDefaults] (derived from the surrounding [SelectTheme]).
///
/// Shared by [SelectChipBar] and [SelectWrapView] so the two views always
/// render identical chips.
SelectChipBarStyle resolveSelectChipBarStyle(
  BuildContext context, {
  SelectChipVariant? variant,
  Color? backgroundColor,
  EdgeInsetsGeometry? padding,
  Color? chipColor,
  Color? selectedChipColor,
  TextStyle? labelStyle,
  TextStyle? selectedLabelStyle,
}) {
  final theme = SelectChipBarTheme.of(context);

  final effectiveVariant =
      variant ?? theme.variant ?? SelectChipVariant.filled;

  final defaults = SelectChipBarDefaults(context, effectiveVariant);

  final effectiveBackgroundColor =
      backgroundColor ?? theme.backgroundColor ?? defaults.backgroundColor!;

  final effectivePadding = padding ?? theme.padding ?? defaults.padding!;

  final effectiveChipColor =
      chipColor ?? theme.chipColor ?? defaults.chipColor!;

  final effectiveSelectedChipColor =
      selectedChipColor ?? theme.selectedChipColor ?? defaults.selectedChipColor!;

  final selectedTextColor =
      effectiveVariant == SelectChipVariant.filled
          ? (ThemeData.estimateBrightnessForColor(effectiveSelectedChipColor) ==
                  Brightness.dark
              ? Colors.white
              : Colors.black)
          : effectiveSelectedChipColor;

  final effectiveLabelStyle =
      (labelStyle ?? theme.labelStyle ?? defaults.labelStyle!)
          .copyWith(inherit: true);

  final effectiveSelectedLabelStyle =
      (selectedLabelStyle ?? theme.selectedLabelStyle ?? defaults.selectedLabelStyle!)
          .copyWith(inherit: true, color: selectedTextColor);

  return SelectChipBarStyle(
    variant: effectiveVariant,
    backgroundColor: effectiveBackgroundColor,
    padding: effectivePadding,
    chipColor: effectiveChipColor,
    selectedChipColor: effectiveSelectedChipColor,
    labelStyle: effectiveLabelStyle,
    selectedLabelStyle: effectiveSelectedLabelStyle,
  );
}

/// Shared building blocks for the two chip views — the single-row
/// [SelectChipBar] and the wrapped [SelectWrapView].
///
/// On top of [CustomRangeHost] this mixin consolidates the logic that used
/// to be duplicated between the two views:
///
/// * tap handling that clears the custom range input (a regular chip's
///   selection replaces an in-progress custom range),
/// * building the chip children (custom range entries excluded, item
///   builder honored),
/// * laying the category title out horizontally or vertically around the
///   chip group, and
/// * scaffolding the custom range field above/below the content.
mixin SelectChipHost<T extends StatefulWidget> on CustomRangeHost<T> {
  /// Optional builder that fully replaces each chip's widget.
  ///
  /// When non-null, regular entries render as the returned widget instead of
  /// the default [SelectChip]; the builder renders its own selected-state
  /// visuals from `selected` and wires `onTap` (e.g. via [InkWell]) to its
  /// own gesture handler so taps keep flowing through this host's normal
  /// selection logic.
  SelectItemBuilder? get chipItemBuilder;

  /// Reports that the chip at [index] was tapped.
  ///
  /// Invoked after [clearCustomRangeInput] has already run, so the host only
  /// needs to forward to its `onChanged`.
  void onChipTap(int index, SelectEntry entry);

  /// Handles a chip tap: the chip's selection replaces any in-progress
  /// custom range input, then [onChipTap] forwards the tap.
  void handleChipTap(int index, SelectEntry item) {
    clearCustomRangeInput();
    onChipTap(index, item);
  }

  /// Builds one child per non-custom entry of [CustomRangeHost.
  /// customRangeEntries], preserving the entries' original indexes for the
  /// tap callback.
  List<Widget> buildChipChildren(SelectChipBarStyle style) {
    // Custom entries render as input fields, not chips; their original
    // indexes are preserved for the tap callback.
    return [
      for (final entry in customRangeEntries.asMap().entries)
        if (testNotCustomItem(entry.value))
          () {
            final index = entry.key;
            final item = entry.value;
            final selected = customRangeSelectedEntries.contains(item);
            final customBuilder = chipItemBuilder;
            if (customBuilder != null) {
              return customBuilder(
                context,
                item,
                selected: selected,
                onTap: () => handleChipTap(index, item),
              );
            }
            return SelectChip(
              label: item.name ?? '',
              selected: selected,
              variant: style.variant,
              color: style.chipColor,
              selectedColor: style.selectedChipColor,
              labelStyle: style.labelStyle,
              selectedLabelStyle: style.selectedLabelStyle,
              enabled: item.enabled,
              onTap: () => handleChipTap(index, item),
            );
          }(),
    ];
  }

  /// Lays the category title out around [chipGroup].
  ///
  /// [Axis.horizontal] (the default) puts the title to the left of the chip
  /// group in a single row; [Axis.vertical] stacks the title above it.
  Widget layoutTitleAround(
    Widget chipGroup, {
    required Axis direction,
    required bool showTitle,
    SelectEntry? category,
  }) {
    if (direction == Axis.vertical) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showTitle && category?.name != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: DefaultTextStyle.merge(
                style: Theme.of(context).textTheme.titleSmall ??
                    const TextStyle(fontSize: 16),
                child: Text(category?.name ?? ''),
              ),
            ),
          chipGroup,
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showTitle && category?.name != null)
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: DefaultTextStyle.merge(
              style: Theme.of(context).textTheme.titleSmall ??
                  const TextStyle(fontSize: 16),
              child: Text(category?.name ?? ''),
            ),
          ),
        Expanded(child: chipGroup),
        const SizedBox(width: 12),
      ],
    );
  }

  /// Scaffolds the custom range field (if any) around [content]: a header
  /// field above when [CustomRangeHost.firstCustomRange] is set, a footer
  /// field below when [CustomRangeHost.lastCustomRange] is set.
  Widget wrapCustomRangeFields(
    Widget content, {
    SelectFieldTileVariant? fieldVariant,
  }) {
    if (!hasCustomRange) return content;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (firstCustomRange != null)
          buildCustomRangeFieldTile(
            isHeader: true,
            padding: const EdgeInsets.only(bottom: 10.0),
            variant: fieldVariant,
          ),
        content,
        if (lastCustomRange != null)
          buildCustomRangeFieldTile(
            isHeader: false,
            padding: const EdgeInsets.only(top: 10.0),
            variant: fieldVariant,
          ),
      ],
    );
  }
}
