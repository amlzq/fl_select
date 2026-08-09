import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../select_theme.dart';
import 'side_bar.dart';

/// Defines a theme for [SelectSideBar] widgets.
@immutable
class SelectSideBarTheme with Diagnosticable {
  const SelectSideBarTheme({
    this.backgroundColor,
    this.width,
    this.padding,
    this.selectedColor,
    this.labelStyle,
    this.selectedLabelStyle,
    this.selectedTileColor,
    this.indicatorColor,
    this.indicatorHeight,
    this.indicatorPadding,
    this.indicatorAnimationDuration,
  });

  /// Overrides the default value of [SelectSideBar.selectedColor].
  final Color? backgroundColor;

  /// Overrides the default value of [SelectSideBar.width].
  final double? width;

  /// Overrides the default value of [SelectSideBar.padding].
  final EdgeInsetsGeometry? padding;

  /// Overrides the default value of [SelectSideBar.selectedColor].
  final Color? selectedColor;

  /// Overrides the default value of [SelectSideBar.labelStyle].
  final TextStyle? labelStyle;

  /// Overrides the default value of [SelectSideBar.selectedLabelStyle].
  final TextStyle? selectedLabelStyle;

  /// Overrides the default value of [SelectSideBar.selectedTileColor].
  final Color? selectedTileColor;

  /// Overrides the default value of [SelectSideBar.indicatorColor].
  final Color? indicatorColor;

  /// Overrides the default value of [SelectSideBar.indicatorHeight].
  final double? indicatorHeight;

  /// Overrides the default value of [SelectSideBar.indicatorPadding].
  final EdgeInsetsGeometry? indicatorPadding;

  /// Overrides the default value of [SelectSideBar.indicatorAnimationDuration].
  final Duration? indicatorAnimationDuration;

  /// Returns a copy of this theme with the given fields replaced.
  SelectSideBarTheme copyWith({
    Color? backgroundColor,
    double? width,
    EdgeInsetsGeometry? padding,
    Color? selectedColor,
    TextStyle? labelStyle,
    TextStyle? selectedLabelStyle,
    Color? selectedTileColor,
    Color? indicatorColor,
    double? indicatorHeight,
    EdgeInsetsGeometry? indicatorPadding,
    Duration? indicatorAnimationDuration,
  }) {
    return SelectSideBarTheme(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      width: width ?? this.width,
      padding: padding ?? this.padding,
      selectedColor: selectedColor ?? this.selectedColor,
      labelStyle: labelStyle ?? this.labelStyle,
      selectedLabelStyle: selectedLabelStyle ?? this.selectedLabelStyle,
      selectedTileColor: selectedTileColor ?? this.selectedTileColor,
      indicatorColor: indicatorColor ?? this.indicatorColor,
      indicatorHeight: indicatorHeight ?? this.indicatorHeight,
      indicatorPadding: indicatorPadding ?? this.indicatorPadding,
      indicatorAnimationDuration:
          indicatorAnimationDuration ?? this.indicatorAnimationDuration,
    );
  }

  static SelectSideBarTheme of(BuildContext context) {
    return SelectTheme.of(context).sideBarTheme;
  }

  /// Linearly interpolates between two category bar themes.
  static SelectSideBarTheme lerp(
      SelectSideBarTheme? a, SelectSideBarTheme? b, double t) {
    if (identical(a, b) && a != null) {
      return a;
    }
    return SelectSideBarTheme(
      backgroundColor: Color.lerp(a?.backgroundColor, b?.backgroundColor, t),
      width: lerpDouble(a?.width, b?.width, t),
      padding: EdgeInsetsGeometry.lerp(a?.padding, b?.padding, t),
      selectedColor: Color.lerp(a?.selectedColor, b?.selectedColor, t),
      labelStyle: TextStyle.lerp(a?.labelStyle, b?.labelStyle, t),
      selectedLabelStyle: TextStyle.lerp(
        a?.selectedLabelStyle,
        b?.selectedLabelStyle,
        t,
      ),
      selectedTileColor: Color.lerp(
        a?.selectedTileColor,
        b?.selectedTileColor,
        t,
      ),
      indicatorColor: Color.lerp(a?.indicatorColor, b?.indicatorColor, t),
      indicatorHeight: lerpDouble(a?.indicatorHeight, b?.indicatorHeight, t),
      indicatorPadding: EdgeInsetsGeometry.lerp(
        a?.indicatorPadding,
        b?.indicatorPadding,
        t,
      ),
    );
  }

  @override
  int get hashCode => Object.hash(
        backgroundColor,
        width,
        padding,
        selectedColor,
        labelStyle,
        selectedLabelStyle,
        selectedTileColor,
        indicatorColor,
        indicatorHeight,
        indicatorPadding,
        indicatorAnimationDuration,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is SelectSideBarTheme &&
        other.backgroundColor == backgroundColor &&
        other.width == width &&
        other.padding == padding &&
        other.selectedColor == selectedColor &&
        other.labelStyle == labelStyle &&
        other.selectedLabelStyle == selectedLabelStyle &&
        other.selectedTileColor == selectedTileColor &&
        other.indicatorColor == indicatorColor &&
        other.indicatorHeight == indicatorHeight &&
        other.indicatorPadding == indicatorPadding &&
        other.indicatorAnimationDuration == indicatorAnimationDuration;
  }
}
