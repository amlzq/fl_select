import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../select_theme.dart';

/// Theme configuration for the spin-box counter.
@immutable
class SelectCounterTheme with Diagnosticable {
  const SelectCounterTheme({this.valueColor, this.selectedValueColor});

  /// The color of the value text while the counter rests on its first
  /// (zero / "Any") position.
  ///
  /// When null, [ColorScheme.onSurfaceVariant] is used.
  final Color? valueColor;

  /// The color of the value text once the counter has moved off its first
  /// position.
  ///
  /// When null, [SelectThemeData.selectedColor] is used.
  final Color? selectedValueColor;

  /// Returns a copy of this theme with the given fields replaced.
  SelectCounterTheme copyWith({Color? valueColor, Color? selectedValueColor}) {
    return SelectCounterTheme(
      valueColor: valueColor ?? this.valueColor,
      selectedValueColor: selectedValueColor ?? this.selectedValueColor,
    );
  }

  /// Returns a new theme where non-null fields from [other] override the
  /// corresponding fields of this theme.
  SelectCounterTheme merge(SelectCounterTheme? other) {
    if (other == null) {
      return this;
    }
    return SelectCounterTheme(
      valueColor: other.valueColor ?? valueColor,
      selectedValueColor: other.selectedValueColor ?? selectedValueColor,
    );
  }

  /// The theme applying to counters under [context].
  static SelectCounterTheme of(BuildContext context) {
    return SelectTheme.of(context).counterTheme;
  }

  /// Linearly interpolates between two counter themes.
  static SelectCounterTheme lerp(
    SelectCounterTheme? a,
    SelectCounterTheme? b,
    double t,
  ) {
    if (identical(a, b) && a != null) {
      return a;
    }
    return SelectCounterTheme(
      valueColor: Color.lerp(a?.valueColor, b?.valueColor, t),
      selectedValueColor: Color.lerp(
        a?.selectedValueColor,
        b?.selectedValueColor,
        t,
      ),
    );
  }

  @override
  int get hashCode => Object.hash(valueColor, selectedValueColor);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is SelectCounterTheme &&
        other.valueColor == valueColor &&
        other.selectedValueColor == selectedValueColor;
  }
}
