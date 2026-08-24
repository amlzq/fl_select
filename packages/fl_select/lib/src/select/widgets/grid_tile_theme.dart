import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../select_theme.dart';

/// Visual variant for [SelectGridTile].
enum SelectGridTileVariant {
  filled,

  outlined,
}

/// Theme configuration for [SelectGridTile].
@immutable
class SelectGridTileTheme with Diagnosticable {
  const SelectGridTileTheme({
    this.selectedColor,
    this.textColor,
    this.labelStyle,
    this.sublabelStyle,
    this.variant,
    this.tileColor,
    this.selectedTileColor,
  });

  /// Overrides the default value of [SelectGridTile.selectedColor].
  final Color? selectedColor;

  /// Overrides the default value of [SelectGridTile.textColor].
  final Color? textColor;

  /// Overrides the default value of [SelectGridTile.labelStyle].
  final TextStyle? labelStyle;

  /// Overrides the default value of [SelectGridTile.sublabelStyle].
  final TextStyle? sublabelStyle;

  /// Overrides the default value of [SelectGridTile.variant].
  final SelectGridTileVariant? variant;

  /// Overrides the default value of [SelectGridTile.tileColor].
  final Color? tileColor;

  /// Overrides the default value of [SelectGridTile.selectedTileColor].
  final Color? selectedTileColor;

  /// Returns a copy of this theme with the given fields replaced.
  SelectGridTileTheme copyWith({
    Color? selectedColor,
    Color? textColor,
    TextStyle? labelStyle,
    TextStyle? sublabelStyle,
    SelectGridTileVariant? variant,
    Color? tileColor,
    Color? selectedTileColor,
  }) {
    return SelectGridTileTheme(
      selectedColor: selectedColor ?? this.selectedColor,
      textColor: textColor ?? this.textColor,
      labelStyle: labelStyle ?? this.labelStyle,
      sublabelStyle: sublabelStyle ?? this.sublabelStyle,
      variant: variant ?? this.variant,
      tileColor: tileColor ?? this.tileColor,
      selectedTileColor: selectedTileColor ?? this.selectedTileColor,
    );
  }

  static SelectGridTileTheme of(BuildContext context) {
    return SelectTheme.of(context).gridTileTheme;
  }

  /// Linearly interpolates between two grid tile themes.
  static SelectGridTileTheme lerp(
      SelectGridTileTheme? a, SelectGridTileTheme? b, double t) {
    if (identical(a, b) && a != null) {
      return a;
    }
    return SelectGridTileTheme(
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
        selectedColor,
        textColor,
        labelStyle,
        sublabelStyle,
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
    return other is SelectGridTileTheme &&
        other.selectedColor == selectedColor &&
        other.textColor == textColor &&
        other.labelStyle == labelStyle &&
        other.sublabelStyle == sublabelStyle &&
        other.variant == variant &&
        other.tileColor == tileColor &&
        other.selectedTileColor == selectedTileColor;
  }
}
