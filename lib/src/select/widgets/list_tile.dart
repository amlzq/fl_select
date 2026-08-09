import 'package:flutter/material.dart';

import '../select_theme.dart';
import '../select_theme_data.dart';
import 'constants.dart';
import 'list_tile_theme.dart';

/// Default height for [SelectListTile].
const kSelectListTileHeight = 44.0;

/// Base list tile used by select views.
///
/// This tile supports a selected state, optional badge, and optional trailing
/// toggle widgets (radio/checkbox) used by [SelectRadioListTile] and
/// [SelectCheckboxListTile].
class SelectListTile extends StatelessWidget {
  const SelectListTile({
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
    this.badge,
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

  /// The text style for SelectListTile's [label].
  final TextStyle? labelStyle;

  /// The text style for SelectListTile's [sublabel].
  final TextStyle? sublabelStyle;

  /// Defines the background color of `SelectListTile` when [selected] is false.
  final Color? tileColor;

  /// Defines the background color of `SelectListTile` when [selected] is true.
  final Color? selectedTileColor;

  /// A widget to display top-trailing.
  final String? badge;

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
    final SelectListTileTheme defaults = _SelectListTileDefaults(context);
    final theme = SelectListTileTheme.of(context);

    final effectiveSelectedColor =
        selectedColor ?? theme.selectedColor ?? defaults.selectedColor;

    final effectiveTextColor = enabled
        ? selected
            ? effectiveSelectedColor
            : textColor ?? theme.textColor ?? defaults.textColor
        : Colors.grey[500];

    Widget content = Text(
      label,
      style: TextStyle(
        fontSize: 14,
        color: effectiveTextColor,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    final isSublabelVisible = sublabel?.isNotEmpty ?? false;
    if (isSublabelVisible) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          content,
          Text(
            sublabel ?? '',
            style: TextStyle(
              fontSize: 12,
              color: effectiveTextColor,
              fontWeight: selected ? FontWeight.w500 : FontWeight.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    }

    final isBadgeVisible = badge != null;
    if (isBadgeVisible) {
      content = Badge(
        smallSize: 10,
        backgroundColor: effectiveSelectedColor,
        label: (badge?.isNotEmpty ?? false) ? Text(badge!) : null,
        child: content,
      );
    }

    return InkWell(
      onTap: enabled ? onTap : null,
      child: Container(
        height: kSelectListTileHeight,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        color: selected ? selectedTileColor : tileColor,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) leading!,
            Expanded(child: content),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class _SelectListTileDefaults extends SelectListTileTheme {
  _SelectListTileDefaults(this.context) : super();

  final BuildContext context;
  late final SelectThemeData _theme = SelectTheme.of(context);
  late final TextTheme _textTheme = Theme.of(context).textTheme;

  @override
  Color? get textColor => _theme.onBackgroundColorHighest;

  @override
  TextStyle? get labelStyle => _textTheme.bodyLarge;

  @override
  TextStyle? get sublabelStyle => _textTheme.bodyMedium;

  @override
  Color? get selectedColor => _theme.selectedColor;

  @override
  ToggleWidgetBuilder? get radioBuilder => (context, selected) {
        const value = 1;
        var groupValue = 2;
        if (selected) groupValue = value;
        return IgnorePointer(
          child: RadioGroup<int>(
            groupValue: groupValue,
            onChanged: (int? value) {},
            child: const Radio<int>(value: value),
          ),
        );
      };

  @override
  ToggleWidgetBuilder? get checkboxBuilder => (context, checked) {
        return IgnorePointer(
          child: Checkbox(
            value: checked,
            onChanged: (bool? newValue) {},
          ),
        );
      };
}

/// A select list tile with a checkbox trailing widget.
class SelectCheckboxListTile extends StatelessWidget {
  final String label;
  final String? sublabel;

  final bool enabled;

  final bool checked;
  final Color? checkColor;

  final ToggleWidgetBuilder? checkboxBuilder;

  /// Called when the user taps this list tile.
  ///
  /// Inoperative if [enabled] is false.
  final GestureTapCallback? onTap;

  const SelectCheckboxListTile({
    super.key,
    required this.label,
    this.sublabel,
    this.enabled = true,
    required this.checked,
    this.checkColor,
    this.checkboxBuilder,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final SelectListTileTheme defaults = _SelectListTileDefaults(context);
    final theme = SelectListTileTheme.of(context);

    final effectiveCheckbox = checkboxBuilder?.call(context, checked) ??
        theme.checkboxBuilder?.call(context, checked) ??
        defaults.checkboxBuilder!(context, checked);

    return SelectListTile(
      label: label,
      sublabel: sublabel,
      enabled: enabled,
      onTap: onTap,
      trailing: effectiveCheckbox,
    );
  }
}

/// A select list tile with a radio trailing widget.
class SelectRadioListTile extends StatelessWidget {
  final String label;
  final String? sublabel;

  final bool enabled;

  final bool selected;
  final ToggleWidgetBuilder? radioBuilder;

  /// Called when the user taps this list tile.
  ///
  /// Inoperative if [enabled] is false.
  final GestureTapCallback? onTap;

  const SelectRadioListTile({
    super.key,
    required this.label,
    this.sublabel,
    this.enabled = true,
    required this.selected,
    this.radioBuilder,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final SelectListTileTheme defaults = _SelectListTileDefaults(context);
    final theme = SelectListTileTheme.of(context);

    final effectiveRadio = radioBuilder?.call(context, selected) ??
        theme.radioBuilder?.call(context, selected) ??
        defaults.radioBuilder!(context, selected);

    return SelectListTile(
      label: label,
      sublabel: sublabel,
      enabled: enabled,
      onTap: onTap,
      trailing: effectiveRadio,
    );
  }
}
