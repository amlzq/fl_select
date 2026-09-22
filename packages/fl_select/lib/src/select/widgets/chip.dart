import 'package:flutter/material.dart';

import '../select_delegate.dart';
import '../select_theme.dart';
import '../select_theme_data.dart';

/// Visual variant for chip.
enum SelectChipVariant { filled, outlined }

/// A single selectable chip as rendered inside the chip bar and
/// the wrap view.
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
    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      child: InkWell(
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
      ),
    );
  }
}

/// Default visuals of the chip item.
///
/// The chip item is the item of both chip views — the single-row chip bar
/// lays chips out in a row, the wrap form flows them — so its default look is
/// defined once here and reused by each view's defaults class. The views stay
/// independently themable through their own themes; this class only supplies
/// what applies when neither the widget nor the hosting view's theme sets a
/// value.
///
/// Each view's container defaults — its background color and padding — stay on
/// that view: they are independently themable and free to diverge.
///
/// Not part of the package's public API surface.
class SelectChipDefaults {
  SelectChipDefaults(this.context, [this.variant]);

  /// The context used to resolve the surrounding select theme and [ThemeData].
  final BuildContext context;

  /// The chip variant resolved by the hosting view.
  final SelectChipVariant? variant;

  late final SelectThemeData _theme = SelectTheme.of(context);

  late final TextTheme _textTheme = Theme.of(context).textTheme;

  /// Default chip color based on [variant].
  ///
  /// Mirrors the grid tile defaults: a light tint derived from
  /// [SelectThemeData.onBackgroundColorHighest] toward white in light theme;
  /// blends surface colors for harmony in dark theme.
  Color? get chipColor {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      final blendAmount = variant == SelectChipVariant.outlined ? 0.2 : 0.35;
      return Color.lerp(
        _theme.backgroundColor,
        _theme.backgroundColorHighest,
        blendAmount,
      );
    }
    if (variant == SelectChipVariant.outlined) {
      return Color.lerp(_theme.onBackgroundColorHighest, Colors.white, 0.55);
    }
    return Color.lerp(_theme.onBackgroundColorHighest, Colors.white, 0.8);
  }

  /// Default selected chip color.
  ///
  /// Blends with the background in dark theme for a harmonious look.
  Color? get selectedChipColor {
    final baseSelected = _theme.selectedColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return Color.lerp(_theme.backgroundColor, baseSelected, 0.35);
    }
    return baseSelected;
  }

  /// Default label style of an unselected chip.
  TextStyle? get labelStyle =>
      _textTheme.labelLarge?.copyWith(color: _theme.onBackgroundColorHighest);

  /// Default label style of a selected chip.
  TextStyle? get selectedLabelStyle =>
      _textTheme.labelLarge?.copyWith(color: _theme.onSelectedColor);

  /// The label color a selected chip needs to stay legible.
  ///
  /// A [SelectChipVariant.filled] chip paints [selectedChipColor] as its
  /// background, so its label flips between black and white depending on that
  /// color's brightness. An outlined chip paints it as the label instead.
  static Color selectedTextColor(
    SelectChipVariant variant,
    Color selectedChipColor,
  ) {
    if (variant != SelectChipVariant.filled) {
      return selectedChipColor;
    }
    return ThemeData.estimateBrightnessForColor(selectedChipColor) ==
            Brightness.dark
        ? Colors.white
        : Colors.black;
  }
}
