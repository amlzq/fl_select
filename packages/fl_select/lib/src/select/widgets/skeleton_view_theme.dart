import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../select_theme.dart';

/// Theme configuration for the loading skeleton placeholders.
@immutable
class SelectSkeletonViewTheme with Diagnosticable {
  const SelectSkeletonViewTheme({this.color});

  /// The fill color of a skeleton placeholder tile.
  ///
  /// When null, [ColorScheme.surfaceContainerLow] is used. A `color` passed
  /// explicitly to the skeleton tile wins over this theme.
  final Color? color;

  /// Returns a copy of this theme with the given fields replaced.
  SelectSkeletonViewTheme copyWith({Color? color}) {
    return SelectSkeletonViewTheme(color: color ?? this.color);
  }

  /// Returns a new theme where non-null fields from [other] override the
  /// corresponding fields of this theme.
  SelectSkeletonViewTheme merge(SelectSkeletonViewTheme? other) {
    if (other == null) {
      return this;
    }
    return SelectSkeletonViewTheme(color: other.color ?? color);
  }

  /// The theme applying to skeleton placeholders under [context].
  static SelectSkeletonViewTheme of(BuildContext context) {
    return SelectTheme.of(context).skeletonViewTheme;
  }

  /// Linearly interpolates between two skeleton view themes.
  static SelectSkeletonViewTheme lerp(
    SelectSkeletonViewTheme? a,
    SelectSkeletonViewTheme? b,
    double t,
  ) {
    if (identical(a, b) && a != null) {
      return a;
    }
    return SelectSkeletonViewTheme(color: Color.lerp(a?.color, b?.color, t));
  }

  @override
  int get hashCode => color.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is SelectSkeletonViewTheme && other.color == color;
  }
}
