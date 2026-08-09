import 'package:flutter/material.dart';

import 'cascading_select.dart';
import 'constants.dart';
import 'flatten_select.dart';
import 'grid_select.dart';
import 'list_select.dart';
import 'select_entry.dart';
import 'select_panel_theme.dart';
import 'widgets/widgets.dart';

/// Builds the action bar shown at the bottom of the select panel.
///
/// Implementations should trigger [onResetTap] and [onApplyTap] from UI controls
/// (e.g. buttons).
typedef SelectActionBarBuilder = Widget Function(
  BuildContext context, {
  required VoidCallback onResetTap,
  required VoidCallback onApplyTap,
});

/// Base configuration for a select.
///
/// A [SelectDelegate] is responsible for:
/// - Defining how entries are fetched and restored (via loader callbacks).
/// - Defining UI/theme overrides (colors and per-widget themes).
/// - Building the select body widget, a loading skeleton and an error widget.
///
/// The actual selection state is managed by [SelectController] and widgets
/// under `src/select/`.
abstract class SelectDelegate {
  SelectDelegate({
    this.selectionMode = SelectionMode.single,
    required this.entriesLoader,
    this.selectedEntriesLoader,
    this.resetEntriesLoader,
    this.actionBarBuilder,
    this.selectedColor,
    this.onSelectedColor,
    this.backgroundColor,
    this.onBackgroundColor,
    this.backgroundColorHigh,
    this.backgroundColorHighest,
    this.onBackgroundColorHighest,
    this.resetText,
    this.applyText,
    this.actionBarTheme,
    this.tabBarTheme,
    this.sideBarTheme,
    this.gridTileTheme,
    this.listTileTheme,
    this.fieldTileTheme,
    this.expansionTileTheme,
    this.chipBarTheme,
    this.panelTheme,
    this.skeletonBuilder,
    this.errorBuilder,
  });

  /// Selection mode applied to category entries.
  final SelectionMode selectionMode;

  /// Fetches the full selectable entries for this select.
  ///
  /// The select panel can display a loading skeleton while awaiting the
  /// result.
  final Future<SelectEntries> Function() entriesLoader;

  Future<SelectEntries>? _data;

  /// The selectable entries future, lazily initialized from [entriesLoader]
  /// on first access.
  Future<SelectEntries>? get data => _data ??= entriesLoader();

  /// Returns the previously selected entries to restore.
  ///
  /// This is typically used for restoring state when reopening the select.
  final SelectEntries? Function()? selectedEntriesLoader;

  SelectEntries? _selectedData;

  /// The previously selected entries, lazily initialized from
  /// [selectedEntriesLoader] on first access.
  ///
  /// Can be set explicitly to override the cached value.
  SelectEntries? get selectedData =>
      _selectedData ??= selectedEntriesLoader?.call();
  set selectedData(SelectEntries? value) => _selectedData = value;

  /// Returns the selection that should be used when "Reset" is tapped.
  final SelectEntries? Function()? resetEntriesLoader;

  SelectEntries? _resetData;

  /// The reset selection entries, lazily initialized from [resetEntriesLoader]
  /// on first access.
  SelectEntries? get resetData => _resetData ??= resetEntriesLoader?.call();

  /// Optional builder to customize the action bar UI.
  final SelectActionBarBuilder? actionBarBuilder;

  /// The background color used for selected entries.
  final Color? selectedColor;

  /// Text/icon color used on top of [selectedColor].
  final Color? onSelectedColor;

  /// Base background color used by the select panel.
  final Color? backgroundColor;

  /// Text/icon color used on top of [backgroundColor].
  final Color? onBackgroundColor;

  /// A higher-contrast background color used for elevated sections.
  final Color? backgroundColorHigh;

  /// The highest-contrast background color (often used for nested levels).
  final Color? backgroundColorHighest;

  /// Text/icon color used on top of [backgroundColorHighest].
  final Color? onBackgroundColorHighest;

  final String? resetText;

  final String? applyText;

  /// Theme overrides for the action bar widget.
  final SelectActionBarTheme? actionBarTheme;

  /// Theme overrides for the tab bar (horizontal category bar).
  final SelectTabBarTheme? tabBarTheme;

  /// Theme overrides for the side bar (vertical category bar).
  final SelectSideBarTheme? sideBarTheme;

  /// Theme overrides for grid tiles.
  final SelectGridTileTheme? gridTileTheme;

  /// Theme overrides for list tiles.
  final SelectListTileTheme? listTileTheme;

  /// Theme overrides for range field tiles.
  final SelectFieldTileTheme? fieldTileTheme;

  /// Theme overrides for expansion tiles.
  final SelectExpansionTileTheme? expansionTileTheme;

  /// Theme overrides for the selected chips bar.
  final SelectChipBarTheme? chipBarTheme;

  /// Theme overrides for the panel's elevation, shadow and shape decoration.
  ///
  /// When provided, this is merged into the ambient [SelectThemeData] used by
  /// [SelectPanel], so it applies to every host (inline [SelectView],
  /// [showSelect], [showModalBottomSelect] and the dropdown overlay). It is
  /// independent from the host-level decoration (e.g. [Dialog.elevation]).
  final SelectPanelTheme? panelTheme;

  /// Optional builder for the loading skeleton.
  final WidgetBuilder? skeletonBuilder;

  /// Optional builder invoked when [data] fails to load.
  ///
  /// When omitted, a simple [Text] widget showing the error is rendered.
  final Widget Function(Object error, StackTrace? stackTrace)? errorBuilder;

  /// Builds the select body widget.
  ///
  /// [entries] are the full selectable entries. [previousSelected] represents
  /// a previously applied selection, if any.
  Widget buildBody(
    BuildContext context,
    List<SelectEntry> entries,
    Set<SelectEntry>? previousSelected,
  );

  /// Builds the loading skeleton.
  Widget buildSkeleton(BuildContext context);

  /// Builds the error widget shown when [data] fails to load.
  ///
  /// Returns the result of [errorBuilder] when provided, otherwise a simple
  /// [Text] widget showing the error.
  Widget buildError(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    return errorBuilder?.call(error, stackTrace) ??
        Center(child: Text('Error: $error'));
  }
}

/// A cascading select for tree-structured data.
///
/// This layout shows categories on the left and a cascading list to the right.
class CascadingSelectDelegate extends SelectDelegate {
  CascadingSelectDelegate({
    this.categoryBackgroundColor,
    this.terminalBackgroundColor,
    this.checkboxBuilder,
    this.radioBuilder,
    this.isScrollable = false,
    super.selectionMode = SelectionMode.single,
    required super.entriesLoader,
    super.selectedEntriesLoader,
    super.resetEntriesLoader,
    super.actionBarBuilder,
    super.selectedColor,
    super.onSelectedColor,
    super.backgroundColor,
    super.onBackgroundColor,
    super.backgroundColorHigh,
    super.backgroundColorHighest,
    super.onBackgroundColorHighest,
    super.resetText,
    super.applyText,
    super.actionBarTheme,
    super.tabBarTheme,
    super.sideBarTheme,
    super.gridTileTheme,
    super.listTileTheme,
    super.fieldTileTheme,
    super.expansionTileTheme,
    super.chipBarTheme,
    super.panelTheme,
    super.skeletonBuilder,
    super.errorBuilder,
  });

  /// Background color used for the category column.
  final Color? categoryBackgroundColor;

  /// Background color used for the terminal (deepest) column.
  final Color? terminalBackgroundColor;

  /// Optional custom radio widget builder.
  final ToggleWidgetBuilder? radioBuilder;

  /// Optional custom checkbox widget builder.
  final ToggleWidgetBuilder? checkboxBuilder;

  final bool isScrollable;

  @override
  Widget buildBody(
    BuildContext context,
    List<SelectEntry> entries,
    Set<SelectEntry>? previousSelected,
  ) {
    return CascadingSelect(
      delegate: this,
      entries: entries,
      previousSelected: previousSelected,
    );
  }

  @override
  Widget buildSkeleton(BuildContext context) {
    return skeletonBuilder?.call(context) ??
        CascadingSelectSkeleton(
          sideBarWidth: sideBarTheme?.width,
          backgroundColor: backgroundColor,
        );
  }
}

/// A single-column list select.
class ListSelectDelegate extends SelectDelegate {
  ListSelectDelegate({
    this.checkboxBuilder,
    this.radioBuilder,
    super.selectionMode = SelectionMode.single,
    required super.entriesLoader,
    super.selectedEntriesLoader,
    super.resetEntriesLoader,
    super.actionBarBuilder,
    super.selectedColor,
    super.onSelectedColor,
    super.backgroundColor,
    super.onBackgroundColor,
    super.backgroundColorHigh,
    super.backgroundColorHighest,
    super.onBackgroundColorHighest,
    super.resetText,
    super.applyText,
    super.actionBarTheme,
    super.tabBarTheme,
    super.sideBarTheme,
    super.gridTileTheme,
    super.listTileTheme,
    super.fieldTileTheme,
    super.expansionTileTheme,
    super.chipBarTheme,
    super.panelTheme,
    super.skeletonBuilder,
    super.errorBuilder,
  });

  /// Optional custom radio widget builder.
  final ToggleWidgetBuilder? radioBuilder;

  /// Optional custom checkbox widget builder.
  final ToggleWidgetBuilder? checkboxBuilder;

  @override
  Widget buildBody(
    BuildContext context,
    List<SelectEntry> entries,
    Set<SelectEntry>? previousSelected,
  ) {
    return ListSelect(
      delegate: this,
      entries: entries,
      previousSelected: previousSelected,
    );
  }

  @override
  Widget buildSkeleton(BuildContext context) {
    return skeletonBuilder?.call(context) ??
        ListSelectSkeleton(selectionMode: selectionMode);
  }
}

/// A grid select.
class GridSelectDelegate extends SelectDelegate {
  GridSelectDelegate({
    required this.crossAxisCount,
    this.mainAxisSpacing = 0.0,
    this.crossAxisSpacing = 0.0,
    this.childAspectRatio = 1.0,
    this.checkboxBuilder,
    this.radioBuilder,
    super.selectionMode = SelectionMode.single,
    required super.entriesLoader,
    super.selectedEntriesLoader,
    super.resetEntriesLoader,
    super.actionBarBuilder,
    super.selectedColor,
    super.onSelectedColor,
    super.backgroundColor,
    super.onBackgroundColor,
    super.backgroundColorHigh,
    super.backgroundColorHighest,
    super.onBackgroundColorHighest,
    super.resetText,
    super.applyText,
    super.actionBarTheme,
    super.sideBarTheme,
    super.tabBarTheme,
    super.gridTileTheme,
    super.listTileTheme,
    super.fieldTileTheme,
    super.expansionTileTheme,
    super.chipBarTheme,
    super.panelTheme,
    super.skeletonBuilder,
    super.errorBuilder,
  });

  /// Number of columns in the grid.
  final int crossAxisCount;

  /// Spacing between rows.
  final double mainAxisSpacing;

  /// Spacing between columns.
  final double crossAxisSpacing;

  /// Child aspect ratio for each tile.
  final double childAspectRatio;

  /// Optional custom radio widget builder.
  final ToggleWidgetBuilder? radioBuilder;

  /// Optional custom checkbox widget builder.
  final ToggleWidgetBuilder? checkboxBuilder;

  @override
  Widget buildBody(
    BuildContext context,
    List<SelectEntry> entries,
    Set<SelectEntry>? previousSelected,
  ) {
    return GridSelect(
      delegate: this,
      entries: entries,
      previousSelected: previousSelected,
    );
  }

  @override
  Widget buildSkeleton(BuildContext context) {
    return skeletonBuilder?.call(context) ??
        GridSelectSkeleton(
          itemCount: 15,
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: mainAxisSpacing,
          crossAxisSpacing: crossAxisSpacing,
          childAspectRatio: childAspectRatio,
        );
  }
}

/// A "flatten" select that renders children in a grid while keeping the
/// hierarchy behavior.
class FlattenSelectDelegate extends SelectDelegate {
  FlattenSelectDelegate({
    required this.crossAxisCount,
    this.mainAxisSpacing = 0.0,
    this.crossAxisSpacing = 0.0,
    this.childAspectRatio = 1.0,
    super.selectionMode = SelectionMode.single,
    required super.entriesLoader,
    super.selectedEntriesLoader,
    super.resetEntriesLoader,
    super.actionBarBuilder,
    super.selectedColor,
    super.onSelectedColor,
    super.backgroundColor,
    super.onBackgroundColor,
    super.backgroundColorHigh,
    super.backgroundColorHighest,
    super.onBackgroundColorHighest,
    super.resetText,
    super.applyText,
    super.actionBarTheme,
    super.sideBarTheme,
    super.tabBarTheme,
    super.gridTileTheme,
    super.listTileTheme,
    super.fieldTileTheme,
    super.expansionTileTheme,
    super.chipBarTheme,
    super.panelTheme,
    super.skeletonBuilder,
    super.errorBuilder,
  });

  /// Number of columns in the flattened grid.
  final int crossAxisCount;

  /// Spacing between rows.
  final double mainAxisSpacing;

  /// Spacing between columns.
  final double crossAxisSpacing;

  /// Child aspect ratio for each tile.
  final double childAspectRatio;

  @override
  Widget buildBody(
    BuildContext context,
    List<SelectEntry> entries,
    Set<SelectEntry>? previousSelected,
  ) {
    return FlattenSelect(
      delegate: this,
      entries: entries,
      previousSelected: previousSelected,
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: mainAxisSpacing,
      crossAxisSpacing: crossAxisSpacing,
      childAspectRatio: childAspectRatio,
    );
  }

  @override
  Widget buildSkeleton(BuildContext context) {
    return skeletonBuilder?.call(context) ??
        FlattenSelectSkeleton(
          sideBarWidth: sideBarTheme?.width,
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: mainAxisSpacing,
          crossAxisSpacing: crossAxisSpacing,
          childAspectRatio: childAspectRatio,
        );
  }
}
