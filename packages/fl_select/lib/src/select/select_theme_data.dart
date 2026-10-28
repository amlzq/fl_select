// ignore_for_file: deprecated_member_use_from_same_package

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import 'select_panel_theme.dart';
import 'widgets/action_bar_theme.dart';
import 'widgets/cascading_view_theme.dart';
import 'widgets/chip_bar_theme.dart';
import 'widgets/counter_theme.dart';
import 'widgets/expansion_tile_theme.dart';
import 'widgets/field_tile_theme.dart';
import 'widgets/grid_tile_theme.dart';
import 'widgets/list_tile_theme.dart';
import 'widgets/range_slider_theme.dart';
import 'widgets/search_bar_theme.dart';
import 'widgets/side_bar_theme.dart';
import 'widgets/skeleton_view_theme.dart';
import 'widgets/tab_bar_theme.dart';
import 'widgets/wrap_view_theme.dart';

/// Theme configuration for select widgets.
///
/// Holds only the values to override: anything left null is resolved by the
/// widgets from the Material [ThemeData] they are built under.
@immutable
class SelectThemeData with Diagnosticable {
  /// Creates a [SelectThemeData] holding only the values to override.
  ///
  /// Every color and control theme is nullable: `null` means "not set", and the
  /// widgets then resolve the value from the Material [ThemeData] they are
  /// built under (see [SelectTheme.selectedColorOf] and its siblings). This is
  /// what lets [SelectTheme.merge] keep an ambient value that the merged data
  /// leaves unset, and keeps the defaults in step with a changing
  /// [ThemeData] (e.g. a light/dark switch).
  const SelectThemeData({
    this.selectedColor,
    this.onSelectedColor,
    this.backgroundColor,
    this.onBackgroundColor,
    @Deprecated(
      'No longer read by select widgets. Use SelectSideBarTheme.selectedTileColor and SelectSkeletonViewTheme.color instead.',
    )
    this.backgroundColorHigh,
    @Deprecated(
      'No longer read by select widgets. Use the tile, chip, range slider and cascading view themes\' own colors instead.',
    )
    this.backgroundColorHighest,
    @Deprecated(
      'No longer read by select widgets. Use the tile, chip, range slider and counter themes\' own colors instead.',
    )
    this.onBackgroundColorHighest,
    this.actionBarTheme = const SelectActionBarTheme(),
    this.tabBarTheme = const SelectTabBarTheme(),
    this.sideBarTheme = const SelectSideBarTheme(),
    this.gridTileTheme = const SelectGridTileTheme(),
    this.listTileTheme = const SelectListTileTheme(),
    this.fieldTileTheme = const SelectFieldTileTheme(),
    this.expansionTileTheme = const SelectExpansionTileTheme(),
    this.rangeSliderTheme = const SelectRangeSliderTheme(),
    this.radioTheme,
    this.checkboxTheme,
    this.chipBarTheme = const SelectChipBarTheme(),
    this.panelTheme = const SelectPanelTheme(),
    this.searchBarTheme = const SelectSearchBarTheme(),
    this.wrapViewTheme = const SelectWrapViewTheme(),
    this.cascadingViewTheme = const SelectCascadingViewTheme(),
    this.skeletonViewTheme = const SelectSkeletonViewTheme(),
    this.counterTheme = const SelectCounterTheme(),
  });

  /// The background color used for selected entries.
  ///
  /// When null, [ColorScheme.primary] is used.
  final Color? selectedColor;

  /// Text/icon color used on top of [selectedColor].
  ///
  /// Overrides the selected text color of filled grid tiles, field tiles and
  /// chips, which otherwise pick white or black by background brightness. It
  /// is applied regardless of the tile or chip color, so pair it with
  /// `selectedTileColor` / `selectedChipColor` when those are customized.
  /// When null, [ColorScheme.onPrimary] is used elsewhere.
  final Color? onSelectedColor;

  /// Base background color used by the select panel.
  ///
  /// When null, [ColorScheme.surface] is used.
  final Color? backgroundColor;

  /// Text/icon color used on top of [backgroundColor].
  ///
  /// Sets the default unselected text color of the list, grid and field tiles,
  /// the chips and the counter. When null, [ColorScheme.onSurfaceVariant] is
  /// used there ([SelectTheme.onBackgroundColorOf] itself resolves to
  /// [ColorScheme.onSurface]).
  final Color? onBackgroundColor;

  /// A higher-contrast background color used for elevated sections.
  @Deprecated(
    'No longer read by select widgets. Use SelectSideBarTheme.selectedTileColor and SelectSkeletonViewTheme.color instead.',
  )
  final Color? backgroundColorHigh;

  /// The highest-contrast background color (often used for nested levels).
  @Deprecated(
    'No longer read by select widgets. Use the tile, chip, range slider and cascading view themes\' own colors instead.',
  )
  final Color? backgroundColorHighest;

  /// Text/icon color used on top of [backgroundColorHighest].
  @Deprecated(
    'No longer read by select widgets. Use the tile, chip, range slider and counter themes\' own colors instead.',
  )
  final Color? onBackgroundColorHighest;

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

  /// Theme overrides for expansion tiles.
  final SelectExpansionTileTheme expansionTileTheme;

  /// Theme overrides for the range slider widget.
  final SelectRangeSliderTheme rangeSliderTheme;

  /// Theme used for radio controls when rendered by select widgets.
  ///
  /// When null, the ambient [ThemeData.radioTheme] is used.
  final RadioThemeData? radioTheme;

  /// Theme used for checkbox controls when rendered by select widgets.
  ///
  /// When null, the ambient [ThemeData.checkboxTheme] is used.
  final CheckboxThemeData? checkboxTheme;

  /// Theme overrides for the chip bar widget.
  final SelectChipBarTheme chipBarTheme;

  /// Theme overrides for the panel's elevation, shadow and shape decoration.
  final SelectPanelTheme panelTheme;

  /// Theme overrides for the search bar.
  final SelectSearchBarTheme searchBarTheme;

  /// Theme overrides for the wrap view.
  final SelectWrapViewTheme wrapViewTheme;

  /// Theme overrides for the cascading view (multi-column item area).
  final SelectCascadingViewTheme cascadingViewTheme;

  /// Theme overrides for the loading skeleton placeholders.
  final SelectSkeletonViewTheme skeletonViewTheme;

  /// Theme overrides for the spin-box counter.
  final SelectCounterTheme counterTheme;

  /// Creates a copy of this theme data with the given fields replaced.
  SelectThemeData copyWith({
    Color? selectedColor,
    Color? onSelectedColor,
    Color? backgroundColor,
    Color? onBackgroundColor,
    @Deprecated(
      'No longer read by select widgets. Use SelectSideBarTheme.selectedTileColor and SelectSkeletonViewTheme.color instead.',
    )
    Color? backgroundColorHigh,
    @Deprecated(
      'No longer read by select widgets. Use the tile, chip, range slider and cascading view themes\' own colors instead.',
    )
    Color? backgroundColorHighest,
    @Deprecated(
      'No longer read by select widgets. Use the tile, chip, range slider and counter themes\' own colors instead.',
    )
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
    SelectChipBarTheme? chipBarTheme,
    SelectPanelTheme? panelTheme,
    SelectSearchBarTheme? searchBarTheme,
    SelectWrapViewTheme? wrapViewTheme,
    SelectCascadingViewTheme? cascadingViewTheme,
    SelectSkeletonViewTheme? skeletonViewTheme,
    SelectCounterTheme? counterTheme,
  }) {
    return SelectThemeData(
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
      chipBarTheme: chipBarTheme ?? this.chipBarTheme,
      panelTheme: panelTheme ?? this.panelTheme,
      searchBarTheme: searchBarTheme ?? this.searchBarTheme,
      wrapViewTheme: wrapViewTheme ?? this.wrapViewTheme,
      cascadingViewTheme: cascadingViewTheme ?? this.cascadingViewTheme,
      skeletonViewTheme: skeletonViewTheme ?? this.skeletonViewTheme,
      counterTheme: counterTheme ?? this.counterTheme,
    );
  }

  /// Linearly interpolates between two theme data objects.
  static SelectThemeData? lerp(
    SelectThemeData? a,
    SelectThemeData? b,
    double t,
  ) {
    if (identical(a, b)) {
      return a;
    }
    return SelectThemeData(
      selectedColor: Color.lerp(a?.selectedColor, b?.selectedColor, t),
      onSelectedColor: Color.lerp(a?.onSelectedColor, b?.onSelectedColor, t),
      backgroundColor: Color.lerp(a?.backgroundColor, b?.backgroundColor, t),
      onBackgroundColor: Color.lerp(
        a?.onBackgroundColor,
        b?.onBackgroundColor,
        t,
      ),
      backgroundColorHigh: Color.lerp(
        a?.backgroundColorHigh,
        b?.backgroundColorHigh,
        t,
      ),
      backgroundColorHighest: Color.lerp(
        a?.backgroundColorHighest,
        b?.backgroundColorHighest,
        t,
      ),
      onBackgroundColorHighest: Color.lerp(
        a?.onBackgroundColorHighest,
        b?.onBackgroundColorHighest,
        t,
      ),
      actionBarTheme: SelectActionBarTheme.lerp(
        a?.actionBarTheme,
        b?.actionBarTheme,
        t,
      ),
      tabBarTheme: SelectTabBarTheme.lerp(a?.tabBarTheme, b?.tabBarTheme, t),
      sideBarTheme: SelectSideBarTheme.lerp(
        a?.sideBarTheme,
        b?.sideBarTheme,
        t,
      ),
      gridTileTheme: SelectGridTileTheme.lerp(
        a?.gridTileTheme,
        b?.gridTileTheme,
        t,
      ),
      listTileTheme: SelectListTileTheme.lerp(
        a?.listTileTheme,
        b?.listTileTheme,
        t,
      ),
      fieldTileTheme: SelectFieldTileTheme.lerp(
        a?.fieldTileTheme,
        b?.fieldTileTheme,
        t,
      ),
      expansionTileTheme: SelectExpansionTileTheme.lerp(
        a?.expansionTileTheme,
        b?.expansionTileTheme,
        t,
      ),
      rangeSliderTheme: SelectRangeSliderTheme.lerp(
        a?.rangeSliderTheme,
        b?.rangeSliderTheme,
        t,
      ),
      radioTheme: a?.radioTheme == null && b?.radioTheme == null
          ? null
          : RadioThemeData.lerp(a?.radioTheme, b?.radioTheme, t),
      checkboxTheme: a?.checkboxTheme == null && b?.checkboxTheme == null
          ? null
          : CheckboxThemeData.lerp(a?.checkboxTheme, b?.checkboxTheme, t),
      chipBarTheme: SelectChipBarTheme.lerp(
        a?.chipBarTheme,
        b?.chipBarTheme,
        t,
      ),
      panelTheme: SelectPanelTheme.lerp(a?.panelTheme, b?.panelTheme, t),
      searchBarTheme: SelectSearchBarTheme.lerp(
        a?.searchBarTheme,
        b?.searchBarTheme,
        t,
      ),
      wrapViewTheme: SelectWrapViewTheme.lerp(
        a?.wrapViewTheme,
        b?.wrapViewTheme,
        t,
      ),
      cascadingViewTheme: SelectCascadingViewTheme.lerp(
        a?.cascadingViewTheme,
        b?.cascadingViewTheme,
        t,
      ),
      skeletonViewTheme: SelectSkeletonViewTheme.lerp(
        a?.skeletonViewTheme,
        b?.skeletonViewTheme,
        t,
      ),
      counterTheme: SelectCounterTheme.lerp(
        a?.counterTheme,
        b?.counterTheme,
        t,
      ),
    );
  }

  @override
  int get hashCode => Object.hashAll([
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
    chipBarTheme,
    panelTheme,
    searchBarTheme,
    wrapViewTheme,
    cascadingViewTheme,
    skeletonViewTheme,
    counterTheme,
  ]);

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
        other.chipBarTheme == chipBarTheme &&
        other.panelTheme == panelTheme &&
        other.searchBarTheme == searchBarTheme &&
        other.wrapViewTheme == wrapViewTheme &&
        other.cascadingViewTheme == cascadingViewTheme &&
        other.skeletonViewTheme == skeletonViewTheme &&
        other.counterTheme == counterTheme;
  }
}
