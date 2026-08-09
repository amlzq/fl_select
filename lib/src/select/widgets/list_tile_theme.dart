import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../select_theme.dart';
import 'constants.dart';

/// Theme configuration for [SelectListTile], including toggle builders.
@immutable
class SelectListTileTheme with Diagnosticable {
  const SelectListTileTheme({
    this.selectedColor,
    this.textColor,
    this.tileColor,
    this.selectedTileColor,
    this.labelStyle,
    this.sublabelStyle,
    this.radioBuilder,
    this.checkboxBuilder,
  });

  /// Overrides the default value of [SelectListTile.selectedColor].
  final Color? selectedColor;

  /// Overrides the default value of [SelectListTile.textColor].
  final Color? textColor;

  /// Overrides the default value of [SelectListTile.tileColor].
  final Color? tileColor;

  /// Overrides the default value of [SelectListTile.selectedTileColor].
  final Color? selectedTileColor;

  /// Overrides the default value of [SelectListTile.labelStyle].
  final TextStyle? labelStyle;

  /// Overrides the default value of [SelectListTile.sublabelStyle].
  final TextStyle? sublabelStyle;

  /// Overrides the default value of [SelectListTile.radioBuilder].
  final ToggleWidgetBuilder? radioBuilder;

  /// Overrides the default value of [SelectListTile.checkboxBuilder].
  final ToggleWidgetBuilder? checkboxBuilder;

  /// Returns a copy of this theme with the given fields replaced.
  SelectListTileTheme copyWith({
    Color? selectedColor,
    Color? textColor,
    Color? tileColor,
    Color? selectedTileColor,
    TextStyle? labelStyle,
    TextStyle? sublabelStyle,
    ToggleWidgetBuilder? radioBuilder,
    ToggleWidgetBuilder? checkboxBuilder,
  }) {
    return SelectListTileTheme(
      selectedColor: selectedColor ?? this.selectedColor,
      textColor: textColor ?? this.textColor,
      tileColor: tileColor ?? this.tileColor,
      selectedTileColor: selectedTileColor ?? this.selectedTileColor,
      labelStyle: labelStyle ?? this.labelStyle,
      sublabelStyle: sublabelStyle ?? this.sublabelStyle,
      radioBuilder: radioBuilder ?? this.radioBuilder,
      checkboxBuilder: checkboxBuilder ?? this.checkboxBuilder,
    );
  }

  static SelectListTileTheme of(BuildContext context) {
    return SelectTheme.of(context).listTileTheme;
  }

  /// Linearly interpolates between two list tile themes.
  static SelectListTileTheme lerp(
      SelectListTileTheme? a, SelectListTileTheme? b, double t) {
    if (identical(a, b) && a != null) {
      return a;
    }
    return SelectListTileTheme(
      selectedColor: Color.lerp(a?.selectedColor, b?.selectedColor, t),
      textColor: Color.lerp(a?.textColor, b?.textColor, t),
      tileColor: Color.lerp(a?.tileColor, b?.tileColor, t),
      selectedTileColor:
          Color.lerp(a?.selectedTileColor, b?.selectedTileColor, t),
      labelStyle: TextStyle.lerp(a?.labelStyle, b?.labelStyle, t),
      sublabelStyle: TextStyle.lerp(a?.sublabelStyle, b?.sublabelStyle, t),
      radioBuilder: t < 0.5 ? a?.radioBuilder : b?.radioBuilder,
      checkboxBuilder: t < 0.5 ? a?.checkboxBuilder : b?.checkboxBuilder,
    );
  }

  @override
  int get hashCode => Object.hash(
        selectedColor,
        textColor,
        tileColor,
        selectedTileColor,
        labelStyle,
        sublabelStyle,
        radioBuilder,
        checkboxBuilder,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is SelectListTileTheme &&
        other.selectedColor == selectedColor &&
        other.textColor == textColor &&
        other.tileColor == tileColor &&
        other.selectedTileColor == selectedTileColor &&
        other.labelStyle == labelStyle &&
        other.sublabelStyle == sublabelStyle &&
        other.radioBuilder == radioBuilder &&
        other.checkboxBuilder == checkboxBuilder;
  }
}
