// ignore_for_file: deprecated_member_use_from_same_package

import 'package:material_ui/material_ui.dart';

import 'select_theme_data.dart';

/// Provides [SelectThemeData] to select widgets.
///
/// This works similarly to Material's theme widgets and supports merging via
/// [SelectTheme.merge].
class SelectTheme extends InheritedTheme {
  const SelectTheme({super.key, required this.data, required super.child});

  final SelectThemeData data;

  /// Returns the nearest [SelectThemeData] or a fallback derived from the
  /// current Material [ThemeData].
  static SelectThemeData of(BuildContext context) {
    final SelectTheme? inheritedTheme = context
        .dependOnInheritedWidgetOfExactType<SelectTheme>();
    return inheritedTheme?.data ?? SelectThemeData.fallback(Theme.of(context));
  }

  /// Merges the given [data] into the ambient [SelectThemeData].
  ///
  /// Each component theme (`listTileTheme`, `panelTheme`, ...) is merged field
  /// by field: a field [data] leaves null keeps the ambient value.
  ///
  /// The colors and the `radioTheme` / `checkboxTheme` are the exception. They
  /// are not nullable on [SelectThemeData] — a value was already filled in from
  /// the Material theme when [data] was built — so [data] replaces the ambient
  /// ones as a whole.
  static Widget merge({
    Key? key,
    SelectThemeData? data,
    required Widget child,
  }) {
    if (data == null) {
      return child;
    }
    return Builder(
      builder: (context) {
        final ambient = SelectTheme.of(context);
        final merged = ambient.copyWith(
          selectedColor: data.selectedColor,
          onSelectedColor: data.onSelectedColor,
          backgroundColor: data.backgroundColor,
          onBackgroundColor: data.onBackgroundColor,
          backgroundColorHigh: data.backgroundColorHigh,
          backgroundColorHighest: data.backgroundColorHighest,
          onBackgroundColorHighest: data.onBackgroundColorHighest,
          radioTheme: data.radioTheme,
          checkboxTheme: data.checkboxTheme,
          actionBarTheme: ambient.actionBarTheme.merge(data.actionBarTheme),
          tabBarTheme: ambient.tabBarTheme.merge(data.tabBarTheme),
          sideBarTheme: ambient.sideBarTheme.merge(data.sideBarTheme),
          gridTileTheme: ambient.gridTileTheme.merge(data.gridTileTheme),
          listTileTheme: ambient.listTileTheme.merge(data.listTileTheme),
          fieldTileTheme: ambient.fieldTileTheme.merge(data.fieldTileTheme),
          expansionTileTheme: ambient.expansionTileTheme.merge(
            data.expansionTileTheme,
          ),
          rangeSliderTheme: ambient.rangeSliderTheme.merge(
            data.rangeSliderTheme,
          ),
          chipBarTheme: ambient.chipBarTheme.merge(data.chipBarTheme),
          panelTheme: ambient.panelTheme.merge(data.panelTheme),
          searchBarTheme: ambient.searchBarTheme.merge(data.searchBarTheme),
          wrapViewTheme: ambient.wrapViewTheme.merge(data.wrapViewTheme),
          cascadingViewTheme: ambient.cascadingViewTheme.merge(
            data.cascadingViewTheme,
          ),
          skeletonViewTheme: ambient.skeletonViewTheme.merge(
            data.skeletonViewTheme,
          ),
          counterTheme: ambient.counterTheme.merge(data.counterTheme),
        );
        return SelectTheme(key: key, data: merged, child: child);
      },
    );
  }

  @override
  bool updateShouldNotify(SelectTheme oldWidget) => data != oldWidget.data;

  @override
  Widget wrap(BuildContext context, Widget child) {
    return SelectTheme(data: data, child: child);
  }
}
