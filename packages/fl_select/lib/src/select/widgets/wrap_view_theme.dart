import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../select_theme.dart';
import 'chip.dart';

/// Theme configuration for the wrap view.
@immutable
class SelectWrapViewTheme with Diagnosticable {
  const SelectWrapViewTheme({
    this.backgroundColor,
    this.padding,
    this.variant,
    this.chipColor,
    this.selectedChipColor,
    this.labelStyle,
    this.selectedLabelStyle,
  });

  /// Overrides the default value of the background color.
  final Color? backgroundColor;

  /// Overrides the default value of the padding.
  final EdgeInsetsGeometry? padding;

  /// Overrides the default value of the variant.
  final SelectChipVariant? variant;

  /// Overrides the default value of the chip color.
  final Color? chipColor;

  /// Overrides the default value of the selected chip color.
  final Color? selectedChipColor;

  /// Overrides the default value of the label style.
  final TextStyle? labelStyle;

  /// Overrides the default value of the selected label style.
  final TextStyle? selectedLabelStyle;

  /// Returns a copy of this theme with the given fields replaced.
  SelectWrapViewTheme copyWith({
    Color? backgroundColor,
    EdgeInsetsGeometry? padding,
    SelectChipVariant? variant,
    Color? chipColor,
    Color? selectedChipColor,
    TextStyle? labelStyle,
    TextStyle? selectedLabelStyle,
  }) {
    return SelectWrapViewTheme(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      padding: padding ?? this.padding,
      variant: variant ?? this.variant,
      chipColor: chipColor ?? this.chipColor,
      selectedChipColor: selectedChipColor ?? this.selectedChipColor,
      labelStyle: labelStyle ?? this.labelStyle,
      selectedLabelStyle: selectedLabelStyle ?? this.selectedLabelStyle,
    );
  }

  /// Returns a new theme where non-null fields from [other] override the
  /// corresponding fields of this theme.
  SelectWrapViewTheme merge(SelectWrapViewTheme? other) {
    if (other == null) {
      return this;
    }
    return SelectWrapViewTheme(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      padding: other.padding ?? padding,
      variant: other.variant ?? variant,
      chipColor: other.chipColor ?? chipColor,
      selectedChipColor: other.selectedChipColor ?? selectedChipColor,
      labelStyle: other.labelStyle ?? labelStyle,
      selectedLabelStyle: other.selectedLabelStyle ?? selectedLabelStyle,
    );
  }

  /// The theme applying to the wrap view under [context].
  ///
  /// The wrap view resolves its own theme only. The deprecated `chipBarTheme`,
  /// which used to style the wrap view as well, is mapped into this theme by
  /// `SelectPanel` while it composes the ambient theme data.
  static SelectWrapViewTheme of(BuildContext context) {
    return SelectTheme.of(context).wrapViewTheme;
  }

  /// Linearly interpolates between two wrap view themes.
  static SelectWrapViewTheme lerp(
    SelectWrapViewTheme? a,
    SelectWrapViewTheme? b,
    double t,
  ) {
    if (identical(a, b) && a != null) {
      return a;
    }
    return SelectWrapViewTheme(
      backgroundColor: Color.lerp(a?.backgroundColor, b?.backgroundColor, t),
      padding: EdgeInsetsGeometry.lerp(a?.padding, b?.padding, t),
      variant: t < 0.5 ? a?.variant : b?.variant,
      chipColor: Color.lerp(a?.chipColor, b?.chipColor, t),
      selectedChipColor: Color.lerp(
        a?.selectedChipColor,
        b?.selectedChipColor,
        t,
      ),
      labelStyle: TextStyle.lerp(a?.labelStyle, b?.labelStyle, t),
      selectedLabelStyle: TextStyle.lerp(
        a?.selectedLabelStyle,
        b?.selectedLabelStyle,
        t,
      ),
    );
  }

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    padding,
    variant,
    chipColor,
    selectedChipColor,
    labelStyle,
    selectedLabelStyle,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is SelectWrapViewTheme &&
        other.backgroundColor == backgroundColor &&
        other.variant == variant &&
        other.padding == padding &&
        other.chipColor == chipColor &&
        other.selectedChipColor == selectedChipColor &&
        other.labelStyle == labelStyle &&
        other.selectedLabelStyle == selectedLabelStyle;
  }
}
