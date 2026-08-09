import 'package:flutter/material.dart';

import 'select_theme_data.dart';

/// Provides [SelectThemeData] to select widgets.
///
/// This works similarly to Material's theme widgets and supports merging via
/// [SelectTheme.merge].
class SelectTheme extends InheritedTheme {
  const SelectTheme({
    super.key,
    required this.data,
    required super.child,
  });

  final SelectThemeData data;

  /// Returns the nearest [SelectThemeData] or a fallback derived from the
  /// current Material [ThemeData].
  static SelectThemeData of(BuildContext context) {
    final SelectTheme? inheritedTheme =
        context.dependOnInheritedWidgetOfExactType<SelectTheme>();
    return inheritedTheme?.data ?? SelectThemeData.fallback(Theme.of(context));
  }

  /// Merges the given [data] into the ambient [SelectThemeData].
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
        final merged = SelectTheme.of(context).copyWith(
          selectedColor: data.selectedColor,
          onSelectedColor: data.onSelectedColor,
          backgroundColor: data.backgroundColor,
          onBackgroundColor: data.onBackgroundColor,
          backgroundColorHigh: data.backgroundColorHigh,
          backgroundColorHighest: data.backgroundColorHighest,
          onBackgroundColorHighest: data.onBackgroundColorHighest,
          actionBarTheme: data.actionBarTheme,
          tabBarTheme: data.tabBarTheme,
          sideBarTheme: data.sideBarTheme,
          gridTileTheme: data.gridTileTheme,
          listTileTheme: data.listTileTheme,
          fieldTileTheme: data.fieldTileTheme,
          expansionTileTheme: data.expansionTileTheme,
          rangeSliderTheme: data.rangeSliderTheme,
          radioTheme: data.radioTheme,
          checkboxTheme: data.checkboxTheme,
          chipBarThemeData: data.chipBarThemeData,
        );
        return SelectTheme(
          key: key,
          data: merged.copyWith(panelTheme: data.panelTheme),
          child: child,
        );
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
