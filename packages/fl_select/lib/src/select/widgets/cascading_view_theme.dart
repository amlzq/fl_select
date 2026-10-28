import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../select_theme.dart';

/// Theme configuration for the cascading view (the multi-column item area
/// shared by `CascadingSelect` and the `SelectCascadingLayout` branch of the
/// category containers).
///
/// The theme describes the two ends of the cascading background ramp, which the
/// levels in between interpolate over.
///
/// A host that paints the first level itself owns the start of the ramp: the
/// start must match the surface painted behind the first column, or a seam
/// shows between them. `CascadingSelect` therefore ignores
/// [startBackgroundColor] and takes its sidebar's background
/// ([SelectSideBarTheme.backgroundColor]) instead. [startBackgroundColor] is for
/// a `CascadingView` used on its own, where no host paints that surface.
@immutable
class SelectCascadingViewTheme with Diagnosticable {
  const SelectCascadingViewTheme({
    this.startBackgroundColor,
    this.endBackgroundColor,
  });

  /// The background color of the first level, i.e. the start of the cascading
  /// background ramp.
  ///
  /// Keep it equal to the surface the view sits on, otherwise a seam shows
  /// between that surface and the first column. A `startBackgroundColor`
  /// passed to the cascading view wins over this theme; when both are null,
  /// [SelectThemeData.backgroundColor] is used.
  ///
  /// Hosts that paint the first level themselves (`CascadingSelect`, whose
  /// sidebar is that level) ignore this value.
  final Color? startBackgroundColor;

  /// The background color of the deepest level, i.e. the end of the cascading
  /// background ramp.
  ///
  /// Only levels >= 1 are painted, and the levels in between are interpolated
  /// over the depth of the tree being rendered: the ramp spans the category
  /// level plus the deepest descendant level. A column deeper than the ramp
  /// clamps to this color, and the selected item of a column is painted with
  /// the next level's color.
  ///
  /// When null, [ColorScheme.surfaceContainer] is used; an
  /// `endBackgroundColor` passed explicitly to the cascading view wins over
  /// this theme.
  final Color? endBackgroundColor;

  /// Returns a copy of this theme with the given fields replaced.
  SelectCascadingViewTheme copyWith({
    Color? startBackgroundColor,
    Color? endBackgroundColor,
  }) {
    return SelectCascadingViewTheme(
      startBackgroundColor: startBackgroundColor ?? this.startBackgroundColor,
      endBackgroundColor: endBackgroundColor ?? this.endBackgroundColor,
    );
  }

  /// Returns a new theme where non-null fields from [other] override the
  /// corresponding fields of this theme.
  SelectCascadingViewTheme merge(SelectCascadingViewTheme? other) {
    if (other == null) {
      return this;
    }
    return SelectCascadingViewTheme(
      startBackgroundColor: other.startBackgroundColor ?? startBackgroundColor,
      endBackgroundColor: other.endBackgroundColor ?? endBackgroundColor,
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
      startBackgroundColor: Color.lerp(
        a?.startBackgroundColor,
        b?.startBackgroundColor,
        t,
      ),
      endBackgroundColor: Color.lerp(
        a?.endBackgroundColor,
        b?.endBackgroundColor,
        t,
      ),
    );
  }

  @override
  int get hashCode => Object.hash(startBackgroundColor, endBackgroundColor);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is SelectCascadingViewTheme &&
        other.startBackgroundColor == startBackgroundColor &&
        other.endBackgroundColor == endBackgroundColor;
  }
}
