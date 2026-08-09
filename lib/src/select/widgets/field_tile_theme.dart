import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../select_theme.dart';

/// Visual variant for [SelectFieldTile].
enum SelectFieldTileVariant {
  filled,

  outlined,
}

/// Theme configuration for [SelectFieldTile].
@immutable
class SelectFieldTileTheme with Diagnosticable {
  const SelectFieldTileTheme({
    this.selectedColor,
    this.textColor,
    this.labelStyle,
    this.sublabelStyle,
    this.variant,
    this.tileColor,
    this.selectedTileColor,
  });

  /// Overrides the default value of [SelectFieldTile.selectedColor].
  final Color? selectedColor;

  /// Overrides the default value of [SelectFieldTile.textColor].
  final Color? textColor;

  /// Overrides the default value of [SelectFieldTile.labelStyle].
  final TextStyle? labelStyle;

  /// Overrides the default value of [SelectFieldTile.sublabelStyle].
  final TextStyle? sublabelStyle;

  /// Overrides the default value of [SelectFieldTile.variant].
  final SelectFieldTileVariant? variant;

  /// Overrides the default value of [SelectFieldTile.tileColor].
  final Color? tileColor;

  /// Overrides the default value of [SelectFieldTile.selectedTileColor].
  final Color? selectedTileColor;

  /// Returns a copy of this theme with the given fields replaced.
  SelectFieldTileTheme copyWith({
    Color? textColor,
    TextStyle? labelStyle,
    TextStyle? sublabelStyle,
    Color? selectedColor,
    SelectFieldTileVariant? variant,
    Color? tileColor,
    Color? selectedTileColor,
  }) {
    return SelectFieldTileTheme(
      textColor: textColor ?? this.textColor,
      labelStyle: labelStyle ?? this.labelStyle,
      sublabelStyle: sublabelStyle ?? this.sublabelStyle,
      selectedColor: selectedColor ?? this.selectedColor,
      variant: variant ?? this.variant,
      tileColor: tileColor ?? this.tileColor,
      selectedTileColor: selectedTileColor ?? this.selectedTileColor,
    );
  }

  static SelectFieldTileTheme of(BuildContext context) {
    return SelectTheme.of(context).fieldTileTheme;
  }

  /// Linearly interpolates between two field tile themes.
  static SelectFieldTileTheme lerp(
      SelectFieldTileTheme? a, SelectFieldTileTheme? b, double t) {
    if (identical(a, b) && a != null) {
      return a;
    }
    return SelectFieldTileTheme(
      selectedColor: Color.lerp(
        a?.selectedColor,
        b?.selectedColor,
        t,
      ),
      textColor: Color.lerp(
        a?.textColor,
        b?.textColor,
        t,
      ),
      labelStyle: TextStyle.lerp(
        a?.labelStyle,
        b?.labelStyle,
        t,
      ),
      sublabelStyle: TextStyle.lerp(
        a?.sublabelStyle,
        b?.sublabelStyle,
        t,
      ),
      variant: t < 0.5 ? a?.variant : b?.variant,
      tileColor: Color.lerp(
        a?.tileColor,
        b?.tileColor,
        t,
      ),
      selectedTileColor: Color.lerp(
        a?.selectedTileColor,
        b?.selectedTileColor,
        t,
      ),
    );
  }

  @override
  int get hashCode => Object.hash(
        textColor,
        labelStyle,
        sublabelStyle,
        selectedColor,
        variant,
        tileColor,
        selectedTileColor,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is SelectFieldTileTheme &&
        other.textColor == textColor &&
        other.labelStyle == labelStyle &&
        other.sublabelStyle == sublabelStyle &&
        other.selectedColor == selectedColor &&
        other.variant == variant &&
        other.tileColor == tileColor &&
        other.selectedTileColor == selectedTileColor;
  }
}
