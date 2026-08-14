import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../select_theme.dart';

/// Theme configuration for [SelectSearchBar].
@immutable
class SelectSearchBarTheme with Diagnosticable {
  const SelectSearchBarTheme({
    this.padding,
    this.contentPadding,
    this.borderRadius,
    this.filled,
    this.fillColor,
    this.enabledBorderColor,
    this.focusedBorderColor,
    this.borderWidth,
    this.hintStyle,
    this.textStyle,
    this.iconColor,
    this.iconSize,
  });

  /// Overrides the default padding around the search bar.
  final EdgeInsetsGeometry? padding;

  /// Overrides the default padding inside the text field.
  final EdgeInsetsGeometry? contentPadding;

  /// Overrides the default corner radius of the text field border.
  final double? borderRadius;

  /// Whether the text field is filled with [fillColor].
  final bool? filled;

  /// The fill color of the text field when [filled] is `true`.
  final Color? fillColor;

  /// The border color of the unfocused text field.
  final Color? enabledBorderColor;

  /// The border color of the focused text field.
  final Color? focusedBorderColor;

  /// The width of the text field border.
  final double? borderWidth;

  /// The text style of the hint shown when the input is empty.
  final TextStyle? hintStyle;

  /// The text style of the input text.
  final TextStyle? textStyle;

  /// The color of the search and clear icons.
  final Color? iconColor;

  /// The size of the search and clear icons.
  final double? iconSize;

  /// Returns a copy of this theme with the given fields replaced.
  SelectSearchBarTheme copyWith({
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? contentPadding,
    double? borderRadius,
    bool? filled,
    Color? fillColor,
    Color? enabledBorderColor,
    Color? focusedBorderColor,
    double? borderWidth,
    TextStyle? hintStyle,
    TextStyle? textStyle,
    Color? iconColor,
    double? iconSize,
  }) {
    return SelectSearchBarTheme(
      padding: padding ?? this.padding,
      contentPadding: contentPadding ?? this.contentPadding,
      borderRadius: borderRadius ?? this.borderRadius,
      filled: filled ?? this.filled,
      fillColor: fillColor ?? this.fillColor,
      enabledBorderColor: enabledBorderColor ?? this.enabledBorderColor,
      focusedBorderColor: focusedBorderColor ?? this.focusedBorderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      hintStyle: hintStyle ?? this.hintStyle,
      textStyle: textStyle ?? this.textStyle,
      iconColor: iconColor ?? this.iconColor,
      iconSize: iconSize ?? this.iconSize,
    );
  }

  static SelectSearchBarTheme of(BuildContext context) {
    return SelectTheme.of(context).searchBarTheme;
  }

  /// Linearly interpolates between two search bar themes.
  static SelectSearchBarTheme lerp(
      SelectSearchBarTheme? a, SelectSearchBarTheme? b, double t) {
    if (identical(a, b) && a != null) {
      return a;
    }
    return SelectSearchBarTheme(
      padding: EdgeInsetsGeometry.lerp(a?.padding, b?.padding, t),
      contentPadding:
          EdgeInsetsGeometry.lerp(a?.contentPadding, b?.contentPadding, t),
      borderRadius: lerpDouble(a?.borderRadius, b?.borderRadius, t),
      filled: t < 0.5 ? a?.filled : b?.filled,
      fillColor: Color.lerp(a?.fillColor, b?.fillColor, t),
      enabledBorderColor:
          Color.lerp(a?.enabledBorderColor, b?.enabledBorderColor, t),
      focusedBorderColor:
          Color.lerp(a?.focusedBorderColor, b?.focusedBorderColor, t),
      borderWidth: lerpDouble(a?.borderWidth, b?.borderWidth, t),
      hintStyle: TextStyle.lerp(a?.hintStyle, b?.hintStyle, t),
      textStyle: TextStyle.lerp(a?.textStyle, b?.textStyle, t),
      iconColor: Color.lerp(a?.iconColor, b?.iconColor, t),
      iconSize: lerpDouble(a?.iconSize, b?.iconSize, t),
    );
  }

  @override
  int get hashCode => Object.hash(
        padding,
        contentPadding,
        borderRadius,
        filled,
        fillColor,
        enabledBorderColor,
        focusedBorderColor,
        borderWidth,
        hintStyle,
        textStyle,
        iconColor,
        iconSize,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is SelectSearchBarTheme &&
        other.padding == padding &&
        other.contentPadding == contentPadding &&
        other.borderRadius == borderRadius &&
        other.filled == filled &&
        other.fillColor == fillColor &&
        other.enabledBorderColor == enabledBorderColor &&
        other.focusedBorderColor == focusedBorderColor &&
        other.borderWidth == borderWidth &&
        other.hintStyle == hintStyle &&
        other.textStyle == textStyle &&
        other.iconColor == iconColor &&
        other.iconSize == iconSize;
  }
}
