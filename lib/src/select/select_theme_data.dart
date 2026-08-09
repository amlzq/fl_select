import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'select_panel_theme.dart';
import 'widgets/action_bar_theme.dart';
import 'widgets/chip_bar_theme.dart';
import 'widgets/expansion_tile_theme.dart';
import 'widgets/field_tile_theme.dart';
import 'widgets/grid_tile_theme.dart';
import 'widgets/list_tile_theme.dart';
import 'widgets/range_slider_theme.dart';
import 'widgets/side_bar_theme.dart';
import 'widgets/tab_bar_theme.dart';

/// Theme configuration for select widgets.
///
/// This object is usually derived from a Material [ThemeData] plus optional
/// overrides, and is consumed by select widgets to keep styling consistent.
@immutable
class SelectThemeData with Diagnosticable {
  /// Creates a [SelectThemeData] by reading defaults from [theme] and applying
  /// optional overrides.
  factory SelectThemeData(
    ThemeData theme, {
    Color? selectedColor,
    Color? onSelectedColor,
    Color? backgroundColor,
    Color? onBackgroundColor,
    Color? backgroundColorHigh,
    Color? backgroundColorHighest,
    Color? onBackgroundColorHighest,
    SelectActionBarTheme? actionBarTheme,
    SelectTabBarTheme? tabBarTheme,
    SelectSideBarTheme? sideBarTheme,
    SelectGridTileTheme? gridTileTheme,
    SelectListTileTheme? listTileTheme,
    SelectFieldTileTheme? fieldTileTheme,
    SelectExpansionTileTheme? expansionTileTheme,
    SelectRangeSliderTheme? rangeSliderTheme,
    RadioThemeData? radioTheme,
    CheckboxThemeData? checkboxTheme,
    SelectChipBarTheme? chipBarThemeData,
    SelectPanelTheme? panelTheme,
  }) {
    return SelectThemeData.raw(
      selectedColor: selectedColor ?? theme.colorScheme.primary,
      onSelectedColor: onSelectedColor ?? theme.colorScheme.onPrimary,
      backgroundColor: backgroundColor ?? theme.colorScheme.surface,
      onBackgroundColor: onBackgroundColor ?? theme.colorScheme.onSurface,
      backgroundColorHigh:
          backgroundColorHigh ?? theme.colorScheme.surfaceContainerLow,
      backgroundColorHighest:
          backgroundColorHighest ?? theme.colorScheme.surfaceContainer,
      onBackgroundColorHighest:
          onBackgroundColorHighest ?? theme.colorScheme.onSurfaceVariant,
      actionBarTheme: actionBarTheme ?? const SelectActionBarTheme(),
      tabBarTheme: tabBarTheme ?? const SelectTabBarTheme(),
      sideBarTheme: sideBarTheme ?? const SelectSideBarTheme(),
      gridTileTheme: gridTileTheme ?? const SelectGridTileTheme(),
      listTileTheme: listTileTheme ?? const SelectListTileTheme(),
      fieldTileTheme: fieldTileTheme ?? const SelectFieldTileTheme(),
      expansionTileTheme:
          expansionTileTheme ?? const SelectExpansionTileTheme(),
      rangeSliderTheme: rangeSliderTheme ?? const SelectRangeSliderTheme(),
      radioTheme: radioTheme ?? const RadioThemeData(),
      checkboxTheme: checkboxTheme ?? const CheckboxThemeData(),
      chipBarThemeData: chipBarThemeData ?? const SelectChipBarTheme(),
      panelTheme: panelTheme ?? const SelectPanelTheme(),
    );
  }

  /// Creates a [SelectThemeData] with explicit values.
  const SelectThemeData.raw({
    required this.selectedColor,
    required this.onSelectedColor,
    required this.backgroundColor,
    required this.onBackgroundColor,
    required this.backgroundColorHigh,
    required this.backgroundColorHighest,
    required this.onBackgroundColorHighest,
    required this.actionBarTheme,
    required this.tabBarTheme,
    required this.sideBarTheme,
    required this.gridTileTheme,
    required this.listTileTheme,
    required this.fieldTileTheme,
    required this.expansionTileTheme,
    required this.rangeSliderTheme,
    required this.radioTheme,
    required this.checkboxTheme,
    required this.chipBarThemeData,
    required this.panelTheme,
  });

  /// Convenience factory that uses [theme] defaults without any overrides.
  factory SelectThemeData.fallback(ThemeData theme) => SelectThemeData(theme);

  /// The background color used for selected entries.
  final Color selectedColor;

  /// Text/icon color used on top of [selectedColor].
  final Color onSelectedColor;

  /// Base background color used by the select panel.
  final Color backgroundColor;

  /// Text/icon color used on top of [backgroundColor].
  final Color onBackgroundColor;

  /// A higher-contrast background color used for elevated sections.
  final Color backgroundColorHigh;

  /// The highest-contrast background color (often used for nested levels).
  final Color backgroundColorHighest;

  /// Text/icon color used on top of [backgroundColorHighest].
  final Color onBackgroundColorHighest;

  /// Theme overrides for the action bar widget.
  final SelectActionBarTheme actionBarTheme;

  /// Theme overrides for the tab bar widget.
  final SelectTabBarTheme tabBarTheme;

  /// Theme overrides for the side bar widget.
  final SelectSideBarTheme sideBarTheme;

  /// Theme overrides for grid tiles.
  final SelectGridTileTheme gridTileTheme;

  /// Theme overrides for list tiles.
  final SelectListTileTheme listTileTheme;

  /// Theme overrides for range field tiles.
  final SelectFieldTileTheme fieldTileTheme;

  final SelectExpansionTileTheme expansionTileTheme;

  /// Theme overrides for the range slider widget.
  final SelectRangeSliderTheme rangeSliderTheme;

  /// Theme used for radio controls when rendered by select widgets.
  final RadioThemeData radioTheme;

  /// Theme used for checkbox controls when rendered by select widgets.
  final CheckboxThemeData checkboxTheme;

  /// Theme overrides for the selected chips bar.
  final SelectChipBarTheme chipBarThemeData;

  /// Theme overrides for the panel's elevation, shadow and shape decoration.
  final SelectPanelTheme panelTheme;

  /// Creates a copy of this theme data with the given fields replaced.
  SelectThemeData copyWith({
    Color? selectedColor,
    Color? onSelectedColor,
    Color? backgroundColor,
    Color? onBackgroundColor,
    Color? backgroundColorHigh,
    Color? backgroundColorHighest,
    Color? onBackgroundColorHighest,
    SelectActionBarTheme? actionBarTheme,
    SelectTabBarTheme? tabBarTheme,
    SelectSideBarTheme? sideBarTheme,
    SelectGridTileTheme? gridTileTheme,
    SelectListTileTheme? listTileTheme,
    SelectFieldTileTheme? fieldTileTheme,
    SelectExpansionTileTheme? expansionTileTheme,
    SelectRangeSliderTheme? rangeSliderTheme,
    RadioThemeData? radioTheme,
    CheckboxThemeData? checkboxTheme,
    SelectChipBarTheme? chipBarThemeData,
    SelectPanelTheme? panelTheme,
  }) {
    return SelectThemeData.raw(
      selectedColor: selectedColor ?? this.selectedColor,
      onSelectedColor: onSelectedColor ?? this.onSelectedColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      onBackgroundColor: onBackgroundColor ?? this.onBackgroundColor,
      backgroundColorHigh: backgroundColorHigh ?? this.backgroundColorHigh,
      backgroundColorHighest:
          backgroundColorHighest ?? this.backgroundColorHighest,
      onBackgroundColorHighest:
          onBackgroundColorHighest ?? this.onBackgroundColorHighest,
      actionBarTheme: actionBarTheme ?? this.actionBarTheme,
      tabBarTheme: tabBarTheme ?? this.tabBarTheme,
      sideBarTheme: sideBarTheme ?? this.sideBarTheme,
      gridTileTheme: gridTileTheme ?? this.gridTileTheme,
      listTileTheme: listTileTheme ?? this.listTileTheme,
      fieldTileTheme: fieldTileTheme ?? this.fieldTileTheme,
      expansionTileTheme: expansionTileTheme ?? this.expansionTileTheme,
      rangeSliderTheme: rangeSliderTheme ?? this.rangeSliderTheme,
      radioTheme: radioTheme ?? this.radioTheme,
      checkboxTheme: checkboxTheme ?? this.checkboxTheme,
      chipBarThemeData: chipBarThemeData ?? this.chipBarThemeData,
      panelTheme: panelTheme ?? this.panelTheme,
    );
  }

  /// Linearly interpolates between two theme data objects.
  static SelectThemeData? lerp(
      SelectThemeData? a, SelectThemeData? b, double t) {
    if (identical(a, b)) {
      return a;
    }
    return SelectThemeData.raw(
      selectedColor: Color.lerp(a?.selectedColor, b?.selectedColor, t)!,
      onSelectedColor: Color.lerp(a?.onSelectedColor, b?.onSelectedColor, t)!,
      backgroundColor: Color.lerp(a?.backgroundColor, b?.backgroundColor, t)!,
      onBackgroundColor:
          Color.lerp(a?.onBackgroundColor, b?.onBackgroundColor, t)!,
      backgroundColorHigh:
          Color.lerp(a?.backgroundColorHigh, b?.backgroundColorHigh, t)!,
      backgroundColorHighest:
          Color.lerp(a?.backgroundColorHighest, b?.backgroundColorHighest, t)!,
      onBackgroundColorHighest: Color.lerp(
          a?.onBackgroundColorHighest, b?.onBackgroundColorHighest, t)!,
      actionBarTheme:
          SelectActionBarTheme.lerp(a?.actionBarTheme, b?.actionBarTheme, t),
      tabBarTheme: SelectTabBarTheme.lerp(a?.tabBarTheme, b?.tabBarTheme, t),
      sideBarTheme:
          SelectSideBarTheme.lerp(a?.sideBarTheme, b?.sideBarTheme, t),
      gridTileTheme:
          SelectGridTileTheme.lerp(a?.gridTileTheme, b?.gridTileTheme, t),
      listTileTheme:
          SelectListTileTheme.lerp(a?.listTileTheme, b?.listTileTheme, t),
      fieldTileTheme:
          SelectFieldTileTheme.lerp(a?.fieldTileTheme, b?.fieldTileTheme, t),
      expansionTileTheme: SelectExpansionTileTheme.lerp(
          a?.expansionTileTheme, b?.expansionTileTheme, t),
      rangeSliderTheme: SelectRangeSliderTheme.lerp(
          a?.rangeSliderTheme, b?.rangeSliderTheme, t),
      radioTheme: RadioThemeData.lerp(a?.radioTheme, b?.radioTheme, t),
      checkboxTheme:
          CheckboxThemeData.lerp(a?.checkboxTheme, b?.checkboxTheme, t),
      chipBarThemeData:
          SelectChipBarTheme.lerp(a?.chipBarThemeData, b?.chipBarThemeData, t),
      panelTheme: SelectPanelTheme.lerp(a?.panelTheme, b?.panelTheme, t),
    );
  }

  @override
  int get hashCode => Object.hash(
        selectedColor,
        onSelectedColor,
        backgroundColor,
        onBackgroundColor,
        backgroundColorHigh,
        backgroundColorHighest,
        onBackgroundColorHighest,
        actionBarTheme,
        tabBarTheme,
        sideBarTheme,
        gridTileTheme,
        listTileTheme,
        fieldTileTheme,
        expansionTileTheme,
        rangeSliderTheme,
        radioTheme,
        checkboxTheme,
        chipBarThemeData,
        panelTheme,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is SelectThemeData &&
        other.selectedColor == selectedColor &&
        other.onSelectedColor == onSelectedColor &&
        other.backgroundColor == backgroundColor &&
        other.onBackgroundColor == onBackgroundColor &&
        other.backgroundColorHigh == backgroundColorHigh &&
        other.backgroundColorHighest == backgroundColorHighest &&
        other.onBackgroundColorHighest == onBackgroundColorHighest &&
        other.actionBarTheme == actionBarTheme &&
        other.tabBarTheme == tabBarTheme &&
        other.sideBarTheme == sideBarTheme &&
        other.gridTileTheme == gridTileTheme &&
        other.listTileTheme == listTileTheme &&
        other.fieldTileTheme == fieldTileTheme &&
        other.expansionTileTheme == expansionTileTheme &&
        other.rangeSliderTheme == rangeSliderTheme &&
        other.radioTheme == radioTheme &&
        other.checkboxTheme == checkboxTheme &&
        other.chipBarThemeData == chipBarThemeData &&
        other.panelTheme == panelTheme;
  }
}
