import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../select_theme.dart';

/// Theme configuration for [SelectActionBar].
@immutable
class SelectActionBarTheme with Diagnosticable {
  const SelectActionBarTheme({
    this.backgroundColor,
    this.padding,
    this.resetFlex,
    this.applyFlex,
    this.resetButtonStyle,
    this.applyButtonStyle,
  });

  /// Overrides the default value of [SelectActionBar.selectedColor].
  final Color? backgroundColor;

  /// Overrides the default value of [SelectActionBar.padding].
  final EdgeInsets? padding;

  /// Overrides the default value of [SelectActionBar.resetFlex].
  final int? resetFlex;

  /// Overrides the default value of [SelectActionBar.applyFlex].
  final int? applyFlex;

  /// Overrides the default value of [SelectActionBar.resetButtonStyle].
  final ButtonStyle? resetButtonStyle;

  /// Overrides the default value of [SelectActionBar.applyButtonStyle].
  final ButtonStyle? applyButtonStyle;

  /// Returns a copy of this theme with the given fields replaced.
  SelectActionBarTheme copyWith({
    Color? backgroundColor,
    EdgeInsets? padding,
    int? resetFlex,
    int? applyFlex,
    ButtonStyle? resetButtonStyle,
    ButtonStyle? applyButtonStyle,
  }) {
    return SelectActionBarTheme(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      padding: padding ?? this.padding,
      resetFlex: resetFlex ?? this.resetFlex,
      applyFlex: applyFlex ?? this.applyFlex,
      resetButtonStyle: resetButtonStyle ?? this.resetButtonStyle,
      applyButtonStyle: applyButtonStyle ?? this.applyButtonStyle,
    );
  }

  static SelectActionBarTheme of(BuildContext context) {
    return SelectTheme.of(context).actionBarTheme;
  }

  /// Linearly interpolates between two action bar themes.
  static SelectActionBarTheme lerp(
      SelectActionBarTheme? a, SelectActionBarTheme? b, double t) {
    if (identical(a, b) && a != null) {
      return a;
    }
    return SelectActionBarTheme(
      backgroundColor: Color.lerp(a?.backgroundColor, b?.backgroundColor, t),
      padding: EdgeInsets.lerp(a?.padding, b?.padding, t),
      resetFlex: a?.resetFlex ?? b?.resetFlex ?? 1.toInt(),
      applyFlex: a?.applyFlex ?? b?.applyFlex ?? 1.toInt(),
      resetButtonStyle:
          ButtonStyle.lerp(a?.resetButtonStyle, b?.resetButtonStyle, t),
      applyButtonStyle:
          ButtonStyle.lerp(a?.applyButtonStyle, b?.applyButtonStyle, t),
    );
  }

  @override
  int get hashCode => Object.hash(
        backgroundColor,
        padding,
        resetFlex,
        applyFlex,
        resetButtonStyle,
        applyButtonStyle,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is SelectActionBarTheme &&
        other.backgroundColor == backgroundColor &&
        other.padding == padding &&
        other.resetFlex == resetFlex &&
        other.applyFlex == applyFlex &&
        other.resetButtonStyle == resetButtonStyle &&
        other.applyButtonStyle == applyButtonStyle;
  }
}
