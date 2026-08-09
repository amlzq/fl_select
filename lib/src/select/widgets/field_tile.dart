import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../select_entry.dart';
import '../select_theme.dart';
import '../select_theme_data.dart';
import 'field_tile_theme.dart';

/// A range input tile for a [SelectRangeEntry].
///
/// This widget renders two numeric text fields for min/max input.
class SelectFieldTile extends StatelessWidget {
  const SelectFieldTile(
    this.entry, {
    super.key,
    this.padding,
    this.minController,
    this.maxController,
    this.minFocusNode,
    this.maxFocusNode,
    this.selectedColor,
    this.tileColor,
    this.selectedTileColor,
    this.variant,
    this.separator = '-',
    this.allowDecimal = false,
    this.onMinChanged,
    this.onMaxChanged,
    this.onMinSubmitted,
    this.onMaxSubmitted,
  });

  /// The range entry that defines this tile's input configuration.
  ///
  /// Provides the min/max hint text and an optional input label rendered before
  /// the two fields.
  final SelectRangeEntry entry;

  /// The padding around the whole tile.
  ///
  /// If null, [EdgeInsets.zero] is used.
  final EdgeInsetsGeometry? padding;

  /// The controller for the minimum value text field.
  ///
  /// If null, an internal controller is created for this field.
  final TextEditingController? minController;

  /// The controller for the maximum value text field.
  ///
  /// If null, an internal controller is created for this field.
  final TextEditingController? maxController;

  /// The focus node for the minimum value text field.
  ///
  /// If null, an internal focus node is created for this field.
  final FocusNode? minFocusNode;

  /// The focus node for the maximum value text field.
  ///
  /// If null, an internal focus node is created for this field.
  final FocusNode? maxFocusNode;

  /// The color used to highlight the tile when a field is focused or has input.
  ///
  /// If null, [SelectFieldTileTheme.selectedColor] is used. If that is also
  /// null, the value is [SelectThemeData.selectedColor].
  final Color? selectedColor;

  /// Defines the background color of `SelectFieldTile` when not focused.
  final Color? tileColor;

  /// Defines the background color of `SelectFieldTile` when focused.
  final Color? selectedTileColor;

  /// The visual variant of this tile.
  ///
  /// When null, [SelectFieldTileTheme.variant] is used. Defaults to
  /// [SelectFieldTileVariant.filled], matching [SelectGridTile].
  final SelectFieldTileVariant? variant;

  /// The text rendered between the two fields (e.g. "-", "to", "and").
  ///
  /// Defaults to `"-"`.
  final String separator;

  /// Whether the fields accept decimal input.
  ///
  /// When `false` (the default), the keyboard is `TextInputType.number` and a
  /// digits-only formatter is applied — matching the historical behavior for
  /// integer ranges. When `true`, the keyboard allows decimals and no
  /// digits-only filter is applied, so fractional values can be typed (the
  /// caller is responsible for any rounding on commit).
  final bool allowDecimal;

  /// Called whenever the min field's text changes (per keystroke).
  final ValueChanged<String>? onMinChanged;

  /// Called whenever the max field's text changes (per keystroke).
  final ValueChanged<String>? onMaxChanged;

  /// Called when the min field is submitted (e.g. "done").
  final ValueChanged<String>? onMinSubmitted;

  /// Called when the max field is submitted (e.g. "done").
  final ValueChanged<String>? onMaxSubmitted;

  @override
  Widget build(BuildContext context) {
    // final theme = SelectFieldTileTheme.of(context);
    return TextFieldTapRegion(
      child: Padding(
        padding: padding ?? EdgeInsets.zero,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (entry.inputLabel?.isNotEmpty ?? false)
              Padding(
                padding: const EdgeInsets.only(right: 10.0),
                child: Text(
                  entry.inputLabel ?? '',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            Expanded(
              child: _TextField(
                controller: minController,
                focusNode: minFocusNode,
                hintText: entry.minHintText,
                tileColor: tileColor,
                selectedTileColor: selectedTileColor,
                variant: variant,
                allowDecimal: allowDecimal,
                onChanged: onMinChanged,
                onSubmitted: onMinSubmitted,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child:
                  Text(separator, style: const TextStyle(color: Colors.grey)),
            ),
            Expanded(
              child: _TextField(
                controller: maxController,
                focusNode: maxFocusNode,
                hintText: entry.maxHintText,
                tileColor: tileColor,
                selectedTileColor: selectedTileColor,
                variant: variant,
                allowDecimal: allowDecimal,
                onChanged: onMaxChanged,
                onSubmitted: onMaxSubmitted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hintText;

  final Color? tileColor;
  final Color? selectedTileColor;
  final SelectFieldTileVariant? variant;
  final bool allowDecimal;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const _TextField({
    this.controller,
    this.focusNode,
    this.hintText,
    this.tileColor,
    this.selectedTileColor,
    this.variant,
    this.allowDecimal = false,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = SelectFieldTileTheme.of(context);

    final effectiveVariant =
        variant ?? theme.variant ?? SelectFieldTileVariant.filled;

    final defaults = _SelectFieldTileDefaults(context, effectiveVariant);

    final effectiveTileColor =
        tileColor ?? theme.tileColor ?? defaults.tileColor!;

    final effectiveSelectedTileColor = selectedTileColor ??
        theme.selectedTileColor ??
        defaults.selectedTileColor!;

    final selected = (focusNode?.hasFocus ?? false) ||
        (controller?.text.isNotEmpty ?? false);

    final isFilled = effectiveVariant == SelectFieldTileVariant.filled;

    // Unified tile styling matching [SelectGridTile]:
    // - filled:   tileColor / selectedTileColor as background, no border
    // - outlined: transparent background, tileColor / selectedTileColor as border
    final tileBackgroundColor = isFilled
        ? (selected ? effectiveSelectedTileColor : effectiveTileColor)
        : null;

    final borderColor =
        selected ? effectiveSelectedTileColor : effectiveTileColor;

    final effectiveBorder =
        isFilled ? null : Border.all(color: borderColor, width: 1.2);

    // Text colour, mirroring [SelectGridTile]: when a filled tile is
    // selected its background becomes [selectedTileColor], so the text is
    // flipped to white when that background reads as dark — otherwise it
    // keeps the theme's selected colour. Outlined tiles draw text directly on
    // the page, so they always use the regular text colour.
    final effectiveTextColor = theme.textColor ?? defaults.textColor!;
    final effectiveSelectedColor =
        theme.selectedColor ?? defaults.selectedColor!;
    final selectedTextColor = isFilled
        // `tileBackgroundColor` is non-null exactly when `isFilled` is true.
        ? (ThemeData.estimateBrightnessForColor(tileBackgroundColor!) ==
                Brightness.dark
            ? Colors.white
            : effectiveSelectedColor)
        : effectiveSelectedColor;
    final effectiveColor = selected ? selectedTextColor : effectiveTextColor;

    return Container(
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tileBackgroundColor,
        border: effectiveBorder,
        borderRadius: BorderRadius.circular(4),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: allowDecimal
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.number,
        inputFormatters:
            allowDecimal ? null : [FilteringTextInputFormatter.digitsOnly],
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13, color: effectiveColor),
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        // [SelectFieldTile] wraps the whole row in a [TextFieldTapRegion], so
        // taps on the sibling field / separator are treated as inside and
        // do not trigger this. Only genuine outside taps (grid cells, scrim)
        // unfocus and dismiss the keyboard.
        onTapOutside: (event) {
          FocusScope.of(context).unfocus();
        },
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(fontSize: 13, color: effectiveColor),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        ),
      ),
    );

    // return Container(
    //   height: 32,
    //   decoration: BoxDecoration(
    //     border: Border.all(
    //       color: borderColor,
    //       width: 1.2,
    //     ),
    //     borderRadius: BorderRadius.circular(4),
    //   ),
    //   child: TextField(
    //     controller: controller,
    //     focusNode: focusNode,
    //     keyboardType: TextInputType.number,
    //     inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    //     textAlign: TextAlign.center,
    //     style: const TextStyle(fontSize: 14),
    //     // onChanged: ,
    //     // onSubmitted: ,
    //     // onEditingComplete: ,
    //     // onTap: ,
    //     decoration: InputDecoration(
    //       hintText: hintText,
    //       hintStyle: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 13),
    //       border: OutlineInputBorder(
    //         borderRadius: BorderRadius.circular(10.0),
    //         borderSide: BorderSide(color: Colors.blue),
    //       ),
    //       focusedBorder: OutlineInputBorder(
    //         borderRadius: BorderRadius.circular(10.0),
    //         borderSide: BorderSide(color: Colors.blueAccent, width: 2.0),
    //       ),
    //       contentPadding: const EdgeInsets.only(bottom: 10),
    //     ),
    //   ),
    // );
  }
}

class _SelectFieldTileDefaults extends SelectFieldTileTheme {
  _SelectFieldTileDefaults(
    this.context, [
    SelectFieldTileVariant? variant,
  ]) : super(variant: variant);

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

  /// Default [tileColor] based on [variant].
  ///
  /// Mirrors [_SelectGridTileDefaults.tileColor]: a light tint derived from
  /// [SelectThemeData.onBackgroundColorHighest] toward white in light theme;
  /// blends surface colors for harmony in dark theme.
  @override
  Color? get tileColor {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      final blendAmount =
          variant == SelectFieldTileVariant.outlined ? 0.2 : 0.35;
      return Color.lerp(
          _theme.backgroundColor, _theme.backgroundColorHighest, blendAmount);
    }
    if (variant == SelectFieldTileVariant.outlined) {
      return Color.lerp(_theme.onBackgroundColorHighest, Colors.white, 0.55);
    }
    return Color.lerp(_theme.onBackgroundColorHighest, Colors.white, 0.8);
  }

  /// Default [selectedTileColor].
  ///
  /// Mirrors [_SelectGridTileDefaults.selectedTileColor]: blends with
  /// background in dark theme for a harmonious look.
  @override
  Color? get selectedTileColor {
    final baseSelected = _theme.selectedColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return Color.lerp(_theme.backgroundColor, baseSelected, 0.35);
    }
    return baseSelected;
  }
}
