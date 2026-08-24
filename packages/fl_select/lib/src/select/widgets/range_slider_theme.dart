import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../select_theme.dart';

/// Theme configuration for [SelectRangeSlider].
@immutable
class SelectRangeSliderTheme with Diagnosticable {
  const SelectRangeSliderTheme({
    this.endLabelStyle,
    this.activeTrackColor,
    this.inactiveTrackColor,
    this.thumbColor,
    this.thumbFillColor,
    this.selectedColor,
    this.trackHeight,
    this.thumbRadius,
  });

  /// Overrides the end-label text style (e.g. "$0" / "$20M+").
  final TextStyle? endLabelStyle;

  /// Overrides the color of the selected track segment.
  final Color? activeTrackColor;

  /// Overrides the color of the unselected track segments.
  final Color? inactiveTrackColor;

  /// Overrides the border color of the thumbs.
  final Color? thumbColor;

  /// Overrides the fill color of the thumbs.
  final Color? thumbFillColor;

  /// Overrides the default accent color (used when the more specific track /
  /// thumb colors are not set).
  final Color? selectedColor;

  /// Overrides the track height in logical pixels.
  final double? trackHeight;

  /// Overrides the thumb radius in logical pixels.
  final double? thumbRadius;

  SelectRangeSliderTheme copyWith({
    TextStyle? endLabelStyle,
    Color? activeTrackColor,
    Color? inactiveTrackColor,
    Color? thumbColor,
    Color? thumbFillColor,
    Color? selectedColor,
    double? trackHeight,
    double? thumbRadius,
  }) {
    return SelectRangeSliderTheme(
      endLabelStyle: endLabelStyle ?? this.endLabelStyle,
      activeTrackColor: activeTrackColor ?? this.activeTrackColor,
      inactiveTrackColor: inactiveTrackColor ?? this.inactiveTrackColor,
      thumbColor: thumbColor ?? this.thumbColor,
      thumbFillColor: thumbFillColor ?? this.thumbFillColor,
      selectedColor: selectedColor ?? this.selectedColor,
      trackHeight: trackHeight ?? this.trackHeight,
      thumbRadius: thumbRadius ?? this.thumbRadius,
    );
  }

  static SelectRangeSliderTheme of(BuildContext context) {
    return SelectTheme.of(context).rangeSliderTheme;
  }

  static SelectRangeSliderTheme lerp(
    SelectRangeSliderTheme? a,
    SelectRangeSliderTheme? b,
    double t,
  ) {
    if (identical(a, b) && a != null) return a;
    return SelectRangeSliderTheme(
      endLabelStyle: TextStyle.lerp(a?.endLabelStyle, b?.endLabelStyle, t),
      activeTrackColor: Color.lerp(a?.activeTrackColor, b?.activeTrackColor, t),
      inactiveTrackColor:
          Color.lerp(a?.inactiveTrackColor, b?.inactiveTrackColor, t),
      thumbColor: Color.lerp(a?.thumbColor, b?.thumbColor, t),
      thumbFillColor: Color.lerp(a?.thumbFillColor, b?.thumbFillColor, t),
      selectedColor: Color.lerp(a?.selectedColor, b?.selectedColor, t),
      trackHeight: t < 0.5
          ? (a?.trackHeight ?? b?.trackHeight)
          : (b?.trackHeight ?? a?.trackHeight),
      thumbRadius: t < 0.5
          ? (a?.thumbRadius ?? b?.thumbRadius)
          : (b?.thumbRadius ?? a?.thumbRadius),
    );
  }

  @override
  int get hashCode => Object.hash(
        endLabelStyle,
        activeTrackColor,
        inactiveTrackColor,
        thumbColor,
        thumbFillColor,
        selectedColor,
        trackHeight,
        thumbRadius,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is SelectRangeSliderTheme &&
        other.endLabelStyle == endLabelStyle &&
        other.activeTrackColor == activeTrackColor &&
        other.inactiveTrackColor == inactiveTrackColor &&
        other.thumbColor == thumbColor &&
        other.thumbFillColor == thumbFillColor &&
        other.selectedColor == selectedColor &&
        other.trackHeight == trackHeight &&
        other.thumbRadius == thumbRadius;
  }
}
