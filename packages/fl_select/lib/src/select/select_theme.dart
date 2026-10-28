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

  /// Returns the nearest [SelectThemeData], or an empty one (every value left
  /// to the Material theme) when there is none.
  ///
  /// The returned colors and control themes are the raw overrides and may be
  /// null; use [selectedColorOf], [onSelectedColorOf], [backgroundColorOf],
  /// [onBackgroundColorOf], [radioThemeOf] and [checkboxThemeOf] for the
  /// resolved values.
  static SelectThemeData of(BuildContext context) {
    final SelectTheme? inheritedTheme = context
        .dependOnInheritedWidgetOfExactType<SelectTheme>();
    return inheritedTheme?.data ?? const SelectThemeData();
  }

  /// The color of selected entries: [SelectThemeData.selectedColor], else
  /// [ColorScheme.primary].
  static Color selectedColorOf(BuildContext context) =>
      of(context).selectedColor ?? Theme.of(context).colorScheme.primary;

  /// The color on top of [selectedColorOf]: [SelectThemeData.onSelectedColor],
  /// else [ColorScheme.onPrimary].
  static Color onSelectedColorOf(BuildContext context) =>
      of(context).onSelectedColor ?? Theme.of(context).colorScheme.onPrimary;

  /// The panel background: [SelectThemeData.backgroundColor], else
  /// [ColorScheme.surface].
  static Color backgroundColorOf(BuildContext context) =>
      of(context).backgroundColor ?? Theme.of(context).colorScheme.surface;

  /// The color on top of [backgroundColorOf]:
  /// [SelectThemeData.onBackgroundColor], else [ColorScheme.onSurface].
  static Color onBackgroundColorOf(BuildContext context) =>
      of(context).onBackgroundColor ?? Theme.of(context).colorScheme.onSurface;

  /// The radio control theme: [SelectThemeData.radioTheme], else
  /// [ThemeData.radioTheme].
  static RadioThemeData radioThemeOf(BuildContext context) =>
      of(context).radioTheme ?? Theme.of(context).radioTheme;

  /// The checkbox control theme: [SelectThemeData.checkboxTheme], else
  /// [ThemeData.checkboxTheme].
  static CheckboxThemeData checkboxThemeOf(BuildContext context) =>
      of(context).checkboxTheme ?? Theme.of(context).checkboxTheme;

  /// Merges the given [data] into the ambient [SelectThemeData].
  ///
  /// A value [data] leaves unset keeps the ambient one. Each component theme
  /// (`listTileTheme`, `panelTheme`, ...) is merged field by field; a color or
  /// `radioTheme` / `checkboxTheme` is replaced only when [data] sets it.
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
