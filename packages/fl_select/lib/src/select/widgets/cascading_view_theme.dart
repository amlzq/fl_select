import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../select_theme.dart';

/// Theme configuration for the cascading view (the multi-column item area
/// shared by `CascadingSelect` and the `SelectCascadingLayout` branch of the
/// category containers).
@immutable
class SelectCascadingViewTheme with Diagnosticable {
  const SelectCascadingViewTheme({this.backgroundColors});

  /// Overrides the background colors of the cascading columns, indexed by
  /// depth level: index 0 is the category level, index 1 the first children
  /// column, index 2 the next column, and so on.
  ///
  /// Only levels >= 1 are painted. A column whose level is beyond the end of
  /// the list clamps to the last color, and the selected item of a column is
  /// painted with the next level's color.
  ///
  /// When null (or empty) the gradient is derived from the ambient
  /// [SelectThemeData]: [SelectThemeData.backgroundColor] at the category level
  /// interpolated towards [SelectThemeData.backgroundColorHighest] at the
  /// deepest level. `backgroundColors` passed explicitly to the cascading view
  /// wins over this theme.
  final List<Color>? backgroundColors;

  /// Returns a copy of this theme with the given fields replaced.
  SelectCascadingViewTheme copyWith({List<Color>? backgroundColors}) {
    return SelectCascadingViewTheme(
      backgroundColors: backgroundColors ?? this.backgroundColors,
    );
  }

  /// Returns a new theme where non-null fields from [other] override the
  /// corresponding fields of this theme.
  SelectCascadingViewTheme merge(SelectCascadingViewTheme? other) {
    if (other == null) {
      return this;
    }
    return SelectCascadingViewTheme(
      backgroundColors: other.backgroundColors ?? backgroundColors,
    );
  }

  /// The theme applying to the cascading view under [context].
  static SelectCascadingViewTheme of(BuildContext context) {
    return SelectTheme.of(context).cascadingViewTheme;
  }

  /// Linearly interpolates between two cascading view themes.
  static SelectCascadingViewTheme lerp(
    SelectCascadingViewTheme? a,
    SelectCascadingViewTheme? b,
    double t,
  ) {
    if (identical(a, b) && a != null) {
      return a;
    }
    return SelectCascadingViewTheme(
      backgroundColors: _lerpColors(
        a?.backgroundColors,
        b?.backgroundColors,
        t,
      ),
    );
  }

  /// Element-wise lerp of two color lists; falls back to a hard switch when
  /// only one side is provided or the lengths differ (each level is an
  /// independent step of the same depth-based gradient).
  static List<Color>? _lerpColors(List<Color>? a, List<Color>? b, double t) {
    if (a == null || b == null || a.length != b.length) {
      return t < 0.5 ? a ?? b : b ?? a;
    }
    return List<Color>.generate(a.length, (index) {
      return Color.lerp(a[index], b[index], t)!;
    });
  }

  @override
  int get hashCode => Object.hashAll(backgroundColors ?? const <Color>[]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is SelectCascadingViewTheme &&
        listEquals(other.backgroundColors, backgroundColors);
  }
}
