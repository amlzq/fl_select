import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../select_theme.dart';

/// Theme configuration for the cascading view (the multi-column item area
/// shared by `CascadingSelect` and the `SelectCascadingLayout` branch of the
/// category containers).
///
/// The theme owns the **end** of the background ramp only. Its start is the
/// surface the host already painted behind the first column — the panel
/// background by default, the sidebar in `CascadingSelect` — so it is not a
/// style knob: the host that paints that surface passes it through
/// `CascadingView.startBackgroundColor`.
@immutable
class SelectCascadingViewTheme with Diagnosticable {
  const SelectCascadingViewTheme({this.endBackgroundColor});

  /// The background color of the deepest level, i.e. the end of the cascading
  /// background ramp.
  ///
  /// Only levels >= 1 are painted, and the levels in between are interpolated
  /// over the depth of the tree being rendered: the ramp spans the category
  /// level plus the deepest descendant level. A column deeper than the ramp
  /// clamps to this color, and the selected item of a column is painted with
  /// the next level's color.
  ///
  /// When null, [SelectThemeData.backgroundColorHighest] is used; an
  /// `endBackgroundColor` passed explicitly to the cascading view wins over
  /// this theme.
  final Color? endBackgroundColor;

  /// Returns a copy of this theme with the given fields replaced.
  SelectCascadingViewTheme copyWith({Color? endBackgroundColor}) {
    return SelectCascadingViewTheme(
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
      endBackgroundColor: Color.lerp(
        a?.endBackgroundColor,
        b?.endBackgroundColor,
        t,
      ),
    );
  }

  @override
  int get hashCode => endBackgroundColor.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is SelectCascadingViewTheme &&
        other.endBackgroundColor == endBackgroundColor;
  }
}
