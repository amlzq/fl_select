import 'package:flutter/material.dart';

import 'select/select_theme_data.dart';
import 'select_overlay_style.dart';

/// Theme extension for [PopupSelectButton].
///
/// Add this extension to your app theme to override the default visuals of the
/// four button variants (elevated / filled / outlined / text) and the
/// styles used when the panel is opened.
@immutable
class PopupSelectButtonTheme extends ThemeExtension<PopupSelectButtonTheme> {
  const PopupSelectButtonTheme({
    this.backgroundColor,
    this.foregroundColor,
    this.overlayColor,
    this.shadowColor,
    this.surfaceTintColor,
    this.side,
    this.shape,
    this.textStyle,
    this.iconColor,
    this.padding,
    this.elevation,
    this.overlayStyle,
    this.selectTheme,
  });

  /// Overrides the default value of the button background color.
  final Color? backgroundColor;

  /// Overrides the default value of the button foreground (label/icon) color.
  final Color? foregroundColor;

  /// Splash/highlight color used on press/hover.
  final Color? overlayColor;

  /// Overrides the default value of [Material.shadowColor].
  final Color? shadowColor;

  /// Overrides the default value of [Material.surfaceTintColor].
  final Color? surfaceTintColor;

  /// Border used by the button (mainly relevant for the outlined variant).
  final BorderSide? side;

  /// Shape of the button. The [side] is merged into it automatically.
  final OutlinedBorder? shape;

  /// Overrides the default label text style.
  final TextStyle? textStyle;

  /// Overrides the default value of the trailing icon color.
  final Color? iconColor;

  /// Overrides the default button padding.
  final EdgeInsetsGeometry? padding;

  /// Overrides the default button elevation.
  final double? elevation;

  /// Default overlay style applied to `SelectOverlay`.
  final SelectOverlayStyle? overlayStyle;

  /// Default theme overrides applied to select widgets inside the overlay.
  final SelectThemeData? selectTheme;

  @override
  PopupSelectButtonTheme copyWith({
    Color? backgroundColor,
    Color? foregroundColor,
    Color? overlayColor,
    Color? shadowColor,
    Color? surfaceTintColor,
    BorderSide? side,
    OutlinedBorder? shape,
    TextStyle? textStyle,
    Color? iconColor,
    EdgeInsetsGeometry? padding,
    double? elevation,
    SelectOverlayStyle? overlayStyle,
    SelectThemeData? selectTheme,
  }) {
    return PopupSelectButtonTheme(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      foregroundColor: foregroundColor ?? this.foregroundColor,
      overlayColor: overlayColor ?? this.overlayColor,
      shadowColor: shadowColor ?? this.shadowColor,
      surfaceTintColor: surfaceTintColor ?? this.surfaceTintColor,
      side: side ?? this.side,
      shape: shape ?? this.shape,
      textStyle: textStyle ?? this.textStyle,
      iconColor: iconColor ?? this.iconColor,
      padding: padding ?? this.padding,
      elevation: elevation ?? this.elevation,
      overlayStyle: overlayStyle ?? this.overlayStyle,
      selectTheme: selectTheme ?? this.selectTheme,
    );
  }

  /// Returns the [PopupSelectButtonTheme] from the nearest [Theme], or null.
  static PopupSelectButtonTheme? maybeOf(BuildContext context) {
    return Theme.of(context).extension<PopupSelectButtonTheme>();
  }

  @override
  int get hashCode => Object.hash(
        backgroundColor,
        foregroundColor,
        overlayColor,
        shadowColor,
        surfaceTintColor,
        side,
        shape,
        textStyle,
        iconColor,
        padding,
        elevation,
        overlayStyle,
        selectTheme,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is PopupSelectButtonTheme &&
        other.backgroundColor == backgroundColor &&
        other.foregroundColor == foregroundColor &&
        other.overlayColor == overlayColor &&
        other.shadowColor == shadowColor &&
        other.surfaceTintColor == surfaceTintColor &&
        other.side == side &&
        other.shape == shape &&
        other.textStyle == textStyle &&
        other.iconColor == iconColor &&
        other.padding == padding &&
        other.elevation == elevation &&
        other.overlayStyle == overlayStyle &&
        other.selectTheme == selectTheme;
  }

  @override
  ThemeExtension<PopupSelectButtonTheme> lerp(
      covariant ThemeExtension<PopupSelectButtonTheme>? other, double t) {
    if (other is! PopupSelectButtonTheme) {
      return this;
    }
    return PopupSelectButtonTheme(
      backgroundColor: Color.lerp(backgroundColor, other.backgroundColor, t),
      foregroundColor: Color.lerp(foregroundColor, other.foregroundColor, t),
      overlayColor: Color.lerp(overlayColor, other.overlayColor, t),
      shadowColor: Color.lerp(shadowColor, other.shadowColor, t),
      surfaceTintColor: Color.lerp(surfaceTintColor, other.surfaceTintColor, t),
      side: side != null && other.side != null
          ? BorderSide.lerp(side!, other.side!, t)
          : t < 0.5
              ? side
              : other.side,
      shape: ShapeBorder.lerp(shape, other.shape, t) as OutlinedBorder?,
      textStyle: TextStyle.lerp(textStyle, other.textStyle, t),
      iconColor: Color.lerp(iconColor, other.iconColor, t),
      padding: EdgeInsetsGeometry.lerp(padding, other.padding, t),
      elevation: elevation != null && other.elevation != null
          ? elevation! + (other.elevation! - elevation!) * t
          : t < 0.5
              ? elevation
              : other.elevation,
      overlayStyle: overlayStyle,
      selectTheme: SelectThemeData.lerp(selectTheme, other.selectTheme, t),
    );
  }
}
