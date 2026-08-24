import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'select_theme.dart';

/// Defines the elevation, shadow and shape decoration applied to the
/// [SelectPanel] background.
///
/// Unlike the host-level decoration (e.g. [Dialog.elevation] /
/// [showModalBottomSheet]'s `shape`), this theme is applied to the panel
/// background itself and therefore works for every host, including inline
/// [SelectPanel] and the dropdown overlay. The two layers are independent and
/// can be used together or separately.
///
/// All fields are nullable. When [elevation] and [shape] are both `null`, the
/// panel falls back to a plain [ColoredBox] (the previous flat behavior), so
/// existing usage is unaffected.
@immutable
class SelectPanelTheme with Diagnosticable {
  const SelectPanelTheme({
    this.elevation,
    this.shadowColor,
    this.surfaceTintColor,
    this.shape,
    this.clipBehavior,
  });

  /// The z-coordinate at which to place the panel.
  ///
  /// Passed to [Material.elevation]. When non-null, the panel renders as a
  /// [Material] so that it casts a shadow (and consumes [shape]).
  final double? elevation;

  /// The color of the shadow cast by the panel's elevation.
  ///
  /// Passed to [Material.shadowColor].
  final Color? shadowColor;

  /// The color used as a surface tint overlay on the panel.
  ///
  /// Passed to [Material.surfaceTintColor]; in Material 3 this tints the
  /// background with the seed color instead of drawing a flat shadow.
  final Color? surfaceTintColor;

  /// The shape of the panel's border / corner rounding.
  ///
  /// Passed to [Material.shape]. Common choices are
  /// [RoundedRectangleBorder] with a [BorderRadius].
  final ShapeBorder? shape;

  /// The clip behavior applied to the panel when [shape] has a rounded corner.
  ///
  /// Passed to [Material.clipBehavior].
  final Clip? clipBehavior;

  /// Returns the nearest [SelectPanelTheme] from the ambient
  /// [SelectThemeData].
  static SelectPanelTheme of(BuildContext context) {
    return SelectTheme.of(context).panelTheme;
  }

  /// Returns a copy of this theme with the given fields replaced.
  SelectPanelTheme copyWith({
    double? elevation,
    Color? shadowColor,
    Color? surfaceTintColor,
    ShapeBorder? shape,
    Clip? clipBehavior,
  }) {
    return SelectPanelTheme(
      elevation: elevation ?? this.elevation,
      shadowColor: shadowColor ?? this.shadowColor,
      surfaceTintColor: surfaceTintColor ?? this.surfaceTintColor,
      shape: shape ?? this.shape,
      clipBehavior: clipBehavior ?? this.clipBehavior,
    );
  }

  /// Linearly interpolates between two panel themes.
  static SelectPanelTheme lerp(
      SelectPanelTheme? a, SelectPanelTheme? b, double t) {
    if (identical(a, b) && a != null) {
      return a;
    }
    return SelectPanelTheme(
      elevation: lerpDouble(a?.elevation, b?.elevation, t),
      shadowColor: Color.lerp(a?.shadowColor, b?.shadowColor, t),
      surfaceTintColor: Color.lerp(a?.surfaceTintColor, b?.surfaceTintColor, t),
      shape: ShapeBorder.lerp(a?.shape, b?.shape, t),
      clipBehavior: t < 0.5 ? a?.clipBehavior : b?.clipBehavior,
    );
  }

  @override
  int get hashCode => Object.hash(
        elevation,
        shadowColor,
        surfaceTintColor,
        shape,
        clipBehavior,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is SelectPanelTheme &&
        other.elevation == elevation &&
        other.shadowColor == shadowColor &&
        other.surfaceTintColor == surfaceTintColor &&
        other.shape == shape &&
        other.clipBehavior == clipBehavior;
  }
}
