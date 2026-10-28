import 'package:material_ui/material_ui.dart';

import '../select_theme.dart';
import 'grid_tile_theme.dart';

/// A grid tile used by select grid layouts.
///
/// The tile supports selected/disabled states and can be rendered as filled or
/// outlined depending on [variant].
class SelectGridTile extends StatelessWidget {
  const SelectGridTile({
    super.key,
    this.leading,
    required this.label,
    this.sublabel,
    this.trailing,
    this.selectedColor,
    this.textColor,
    this.labelStyle,
    this.sublabelStyle,
    this.tileColor,
    this.selectedTileColor,
    this.variant,
    this.selected = false,
    this.enabled = true,
    this.onTap,
  });

  /// An optional icon to display before the label.
  final Widget? leading;

  /// The primary content of the list label.
  final String label;

  /// Additional content displayed below the label.
  final String? sublabel;

  /// A widget to display after the label.
  final Widget? trailing;

  /// Defines the color used for icons and text when the list label is selected.
  final Color? selectedColor;

  /// Defines the text color for the [label], [sublabel], [leading], and [trailing].
  final Color? textColor;

  /// The text style for SelectGridTile's [label].
  final TextStyle? labelStyle;

  /// The text style for SelectGridTile's [sublabel].
  final TextStyle? sublabelStyle;

  /// Defines the background color of `SelectGridTile` when [selected] is false.
  final Color? tileColor;

  /// Defines the background color of `SelectGridTile` when [selected] is true.
  final Color? selectedTileColor;

  final SelectGridTileVariant? variant;

  /// If this tile is also [enabled] then icons and text are rendered with the same color.
  final bool selected;

  /// Whether this list tile is interactive.
  final bool enabled;

  /// Called when the user taps this list tile.
  ///
  /// Inoperative if [enabled] is false.
  final GestureTapCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = SelectGridTileTheme.of(context);

    final effectiveSelectedColor =
        selectedColor ??
        theme.selectedColor ??
        SelectTheme.selectedColorOf(context);

    final effectiveVariant =
        variant ?? theme.variant ?? SelectGridTileVariant.filled;

    final defaults = _SelectGridTileDefaults(
      context,
      enabled,
      selected,
      effectiveVariant,
    );

    final effectiveTileColor =
        tileColor ?? theme.tileColor ?? defaults.tileColor!;

    final effectiveSelectedTileColor =
        selectedTileColor ??
        theme.selectedTileColor ??
        defaults.selectedTileColor!;

    final tileBackgroundColor = effectiveVariant == SelectGridTileVariant.filled
        ? (selected ? effectiveSelectedTileColor : effectiveTileColor)
        : Colors.transparent;

    final selectedTextColor = effectiveVariant == SelectGridTileVariant.filled
        ? (SelectTheme.of(context).onSelectedColor ??
              (ThemeData.estimateBrightnessForColor(tileBackgroundColor) ==
                      Brightness.dark
                  ? Colors.white
                  : effectiveSelectedColor))
        : effectiveSelectedColor;

    final effectiveTextColor = enabled
        ? selected
              ? selectedTextColor
              : textColor ?? theme.textColor ?? defaults.textColor!
        : Colors.grey[500]!;

    // For the outlined variant the border reuses the tile colors: the normal
    // border uses [tileColor] and the selected border uses [selectedTileColor],
    // keeping the styling consistent with [SelectFieldTile].
    final effectiveBorder = effectiveVariant == SelectGridTileVariant.filled
        ? null
        : Border.all(
            color: selected ? effectiveSelectedTileColor : effectiveTileColor,
            width: 1.2,
          );

    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      child: InkWell(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: tileBackgroundColor,
            border: effectiveBorder,
            borderRadius: BorderRadius.circular(4),
          ),
          child: _content(context, theme, effectiveTextColor),
        ),
      ),
    );
  }

  Widget _content(
    BuildContext context,
    SelectGridTileTheme theme,
    Color color,
  ) {
    // The base keeps the tile's compact look; a labelStyle only refines it, and
    // the state-dependent color always comes from the color tokens.
    final base = TextStyle(
      fontSize: 13,
      fontWeight: selected ? FontWeight.w500 : FontWeight.normal,
    );
    final labelText = Text(
      label,
      style: base.merge(labelStyle ?? theme.labelStyle).copyWith(color: color),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    if (leading == null && sublabel == null && trailing == null) {
      return labelText;
    }
    final sublabelStyleMerged = TextStyle(fontSize: 11)
        .merge(sublabelStyle ?? theme.sublabelStyle)
        .copyWith(color: color);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leading != null) ...[
          IconTheme.merge(
            data: IconThemeData(color: color, size: 16),
            child: leading!,
          ),
          const SizedBox(width: 4),
        ],
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              labelText,
              if (sublabel != null)
                Text(
                  sublabel!,
                  style: sublabelStyleMerged,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 4),
          IconTheme.merge(
            data: IconThemeData(color: color, size: 16),
            child: trailing!,
          ),
        ],
      ],
    );
  }
}

class _SelectGridTileDefaults extends SelectGridTileTheme {
  _SelectGridTileDefaults(
    this.context,
    this.isEnabled,
    this.isSelected, [
    SelectGridTileVariant? variant,
  ]) : super(variant: variant);

  final BuildContext context;
  final bool isEnabled;
  final bool isSelected;

  late final ColorScheme _colorScheme = Theme.of(context).colorScheme;
  late final TextTheme _textTheme = Theme.of(context).textTheme;

  @override
  Color? get selectedColor => SelectTheme.selectedColorOf(context);

  @override
  Color? get textColor =>
      SelectTheme.of(context).onBackgroundColor ??
      _colorScheme.onSurfaceVariant;

  @override
  TextStyle? get labelStyle => _textTheme.bodyLarge;

  @override
  TextStyle? get sublabelStyle => _textTheme.bodyMedium;

  @override
  Color? get tileColor {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      // In dark theme, use a subtle surface elevation for better harmony
      final blendAmount = variant == SelectGridTileVariant.outlined
          ? 0.2
          : 0.35;
      return Color.lerp(
        SelectTheme.backgroundColorOf(context),
        _colorScheme.surfaceContainer,
        blendAmount,
      );
    }
    if (variant == SelectGridTileVariant.outlined) {
      return Color.lerp(_colorScheme.onSurfaceVariant, Colors.white, 0.55);
    }
    return Color.lerp(_colorScheme.onSurfaceVariant, Colors.white, 0.8);
  }

  @override
  Color? get selectedTileColor {
    final baseSelected = SelectTheme.selectedColorOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      // In dark theme, blend with background for a more harmonious look
      return Color.lerp(
        SelectTheme.backgroundColorOf(context),
        baseSelected,
        0.35,
      );
    }
    return baseSelected;
  }
}
