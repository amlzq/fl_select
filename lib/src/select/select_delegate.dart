import 'package:flutter/material.dart';

import 'cascading_select.dart';
import 'constants.dart';
import 'flatten_select.dart';
import 'grid_select.dart';
import 'list_select.dart';
import 'select_entry.dart';
import 'select_panel_theme.dart';
import 'select_search_filter.dart';
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
/// - Defining its data, either synchronously (`entries`, `selectedEntries`
///   and `resetEntries`) or lazily via loader callbacks.
/// - Defining UI/theme overrides (colors and per-widget themes).
/// - Building the select body widget, a loading skeleton and an error widget.
///
/// The actual selection state is managed by [SelectController] and widgets
/// under `src/select/`.
abstract class SelectDelegate {
  SelectDelegate({
    this.selectionMode = SelectionMode.single,
    SelectEntries? entries,
    this.entriesLoader,
    SelectEntries? selectedEntries,
    this.selectedEntriesLoader,
    SelectEntries? resetEntries,
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
    this.searchEnabled = false,
    this.searchPredicate,
    this.searchHintText,
    this.searchDebounceDuration = const Duration(milliseconds: 300),
    this.searchBarTheme,
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
  })  : _entries = entries,
        _selectedEntries = selectedEntries,
        _resetEntries = resetEntries,
        assert(
          (entries != null) != (entriesLoader != null),
          'Provide exactly one of entries or entriesLoader.',
        ),
        assert(
          selectedEntries == null || selectedEntriesLoader == null,
          'Provide at most one of selectedEntries or selectedEntriesLoader.',
        ),
        assert(
          resetEntries == null || resetEntriesLoader == null,
          'Provide at most one of resetEntries or resetEntriesLoader.',
        );

  /// The panel-wide selection mode.
  ///
  /// Governs flat (non-categorized) entries directly and acts as the
  /// fallback for any [SelectCategoryEntry] that leaves its
  /// [SelectCategoryEntry.selectionMode] null.
  ///
  /// In [SelectionMode.single], selecting a leaf deselects every other
  /// category's selections (cross-category exclusion) and applies
  /// immediately instead of waiting for the apply action. In
  /// [SelectionMode.multiple], selections accumulate until applied.
  final SelectionMode selectionMode;

  final SelectEntries? _entries;

  /// The full selectable entries supplied synchronously, if any.
  ///
  /// When non-null, the select body renders them directly on the first
  /// frame — without going through a loading skeleton — and [entriesLoader]
  /// must be null. The entries are fixed for the delegate's lifetime;
  /// create a new delegate when the data changes.
  SelectEntries? get entries => _entries;

  /// Whether the entries were supplied synchronously via [entries], as
  /// opposed to an [entriesLoader].
  bool get hasSyncEntries => _entries != null;

  /// Fetches the full selectable entries for this select.
  ///
  /// The select panel can display a loading skeleton while awaiting the
  /// result. Exactly one of [entries] and [entriesLoader] must be provided.
  final Future<SelectEntries> Function()? entriesLoader;

  Future<SelectEntries>? _asyncEntries;

  /// The selectable entries future, lazily initialized on first access from
  /// [entries] (wrapped in [Future.value]) or [entriesLoader].
  Future<SelectEntries>? get asyncEntries => _asyncEntries ??=
      _entries != null ? Future.value(_entries) : entriesLoader?.call();

  /// Returns the previously selected entries to restore.
  ///
  /// This is typically used for restoring state when reopening the select.
  final SelectEntries? Function()? selectedEntriesLoader;

  SelectEntries? _selectedEntries;

  /// The previously selected entries to restore.
  ///
  /// Returns the value passed to the constructor, if any (in which case
  /// [selectedEntriesLoader] is never called). Otherwise the value is
  /// lazily initialized from [selectedEntriesLoader] on first access.
  ///
  /// Can be set explicitly to override the cached value.
  SelectEntries? get selectedEntries =>
      _selectedEntries ??= selectedEntriesLoader?.call();
  set selectedEntries(SelectEntries? value) => _selectedEntries = value;

  /// Returns the selection that should be used when "Reset" is tapped.
  final SelectEntries? Function()? resetEntriesLoader;

  SelectEntries? _resetEntries;

  /// The reset selection entries, lazily initialized from [resetEntriesLoader]
  /// on first access, or the value passed to the constructor.
  SelectEntries? get resetEntries =>
      _resetEntries ??= resetEntriesLoader?.call();

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

  /// Whether the search bar is visible in the select panel.
  ///
  /// When `true`, a search bar is rendered above the body. Typing a query
  /// filters the displayed entries using [searchPredicate] while preserving
  /// the original layout and selection state.
  ///
  /// Defaults to `false`.
  final bool searchEnabled;

  /// Custom predicate used to match entries against a search query.
  ///
  /// Defaults to [defaultSelectSearchPredicate] (case-insensitive substring
  /// match on [SelectEntry.name]).
  final SelectSearchPredicate? searchPredicate;

  /// Hint text shown in the search bar when the input is empty.
  final String? searchHintText;

  /// The debounce delay before filtering entries after the search text
  /// changes.
  ///
  /// Defaults to 300 ms.
  final Duration searchDebounceDuration;

  /// Theme overrides for the search bar.
  ///
  /// When `null`, the surrounding [SelectTheme]'s `searchBarTheme` is used,
  /// falling back to Material defaults.
  final SelectSearchBarTheme? searchBarTheme;

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
  /// [entries] are the full selectable entries. [selectedEntries] represents
  /// a previously applied selection, if any.
  ///
  /// [searchQuery] is the current search query string. When non-empty, the
  /// body should filter its displayed entries using [searchPredicate] while
  /// keeping the original [entries] for state binding.
  Widget buildBody(
    BuildContext context,
    List<SelectEntry> entries,
    Set<SelectEntry>? selectedEntries, {
    String searchQuery = '',
  });

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

/// A cascading select for two-level-or-deeper (category) tree data.
///
/// This layout shows categories on the left and cascading item columns to
/// the right, expanding one column per level with unlimited depth
/// (category -> child -> grandchild -> ...).
///
/// Flat (parentless) structures are not supported; use
/// [ListSelectDelegate], [GridSelectDelegate] or [FlattenSelectDelegate]
/// for flat data.
class CascadingSelectDelegate extends SelectDelegate {
  CascadingSelectDelegate({
    this.categoryBackgroundColor,
    this.terminalBackgroundColor,
    this.checkboxBuilder,
    this.radioBuilder,
    this.isScrollable = false,
    super.selectionMode,
    super.entries,
    super.entriesLoader,
    super.selectedEntries,
    super.selectedEntriesLoader,
    super.resetEntries,
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
    super.searchEnabled,
    super.searchPredicate,
    super.searchHintText,
    super.searchDebounceDuration,
    super.searchBarTheme,
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
    Set<SelectEntry>? selectedEntries, {
    String searchQuery = '',
  }) {
    return CascadingSelect(
      delegate: this,
      entries: entries,
      selectedEntries: selectedEntries,
      searchQuery: searchQuery,
      searchPredicate: searchPredicate,
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

/// A list select that renders entries as a single expandable list.
///
/// Supports both flat and two-level structures:
/// - Flat: parentless entries render directly in a single list.
/// - Two-level: each [SelectCategoryEntry] renders as an expandable group
///   whose children are laid out by the category's `layout`.
///
/// At most two levels are rendered; levels nested deeper than the second
/// are not rendered. Use [CascadingSelectDelegate] for multi-level
/// (cascading) data.
class ListSelectDelegate extends SelectDelegate {
  ListSelectDelegate({
    this.checkboxBuilder,
    this.radioBuilder,
    super.selectionMode,
    super.entries,
    super.entriesLoader,
    super.selectedEntries,
    super.selectedEntriesLoader,
    super.resetEntries,
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
    super.searchEnabled,
    super.searchPredicate,
    super.searchHintText,
    super.searchDebounceDuration,
    super.searchBarTheme,
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
    Set<SelectEntry>? selectedEntries, {
    String searchQuery = '',
  }) {
    return ListSelect(
      delegate: this,
      entries: entries,
      selectedEntries: selectedEntries,
      searchQuery: searchQuery,
      searchPredicate: searchPredicate,
    );
  }

  @override
  Widget buildSkeleton(BuildContext context) {
    return skeletonBuilder?.call(context) ??
        ListSelectSkeleton(selectionMode: selectionMode);
  }
}

/// A grid select with category tabs.
///
/// Supports both flat and two-level structures:
/// - Flat: parentless entries render directly in a grid and no category
///   tabs are shown.
/// - Two-level: category tabs on top drive which category's children are
///   shown below, laid out by the category's `layout` (defaulting to a
///   grid built from this delegate's grid parameters).
///
/// At most two levels are rendered; levels nested deeper than the second
/// are not rendered. Use [CascadingSelectDelegate] for multi-level
/// (cascading) data.
class GridSelectDelegate extends SelectDelegate {
  GridSelectDelegate({
    required this.crossAxisCount,
    this.mainAxisSpacing = 0.0,
    this.crossAxisSpacing = 0.0,
    this.childAspectRatio = 1.0,
    this.checkboxBuilder,
    this.radioBuilder,
    super.selectionMode,
    super.entries,
    super.entriesLoader,
    super.selectedEntries,
    super.selectedEntriesLoader,
    super.resetEntries,
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
    super.searchEnabled,
    super.searchPredicate,
    super.searchHintText,
    super.searchDebounceDuration,
    super.searchBarTheme,
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
    Set<SelectEntry>? selectedEntries, {
    String searchQuery = '',
  }) {
    return GridSelect(
      delegate: this,
      entries: entries,
      selectedEntries: selectedEntries,
      searchQuery: searchQuery,
      searchPredicate: searchPredicate,
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

/// A "flatten" select that renders each category's children in a single
/// scrollable column with a category sidebar on the left.
///
/// Supports both flat and two-level structures:
/// - Flat: parentless entries render directly as a wrapable chip bar and
///   no category sidebar is shown.
/// - Two-level: tapping the left sidebar scrolls the right column to the
///   category's children, laid out by the category's `layout` (defaulting
///   to a chip layout).
///
/// At most two levels are rendered; levels nested deeper than the second
/// are not rendered. Use [CascadingSelectDelegate] for multi-level
/// (cascading) data.
class FlattenSelectDelegate extends SelectDelegate {
  FlattenSelectDelegate({
    @Deprecated(
      'Use SelectGridLayout.crossAxisCount on SelectCategoryEntry.layout instead.',
    )
    this.crossAxisCount = 2,
    @Deprecated(
      'Use SelectGridLayout.mainAxisSpacing on SelectCategoryEntry.layout instead.',
    )
    this.mainAxisSpacing = 0.0,
    @Deprecated(
      'Use SelectGridLayout.crossAxisSpacing on SelectCategoryEntry.layout instead.',
    )
    this.crossAxisSpacing = 0.0,
    @Deprecated(
      'Use SelectGridLayout.childAspectRatio on SelectCategoryEntry.layout instead.',
    )
    this.childAspectRatio = 1.0,
    super.selectionMode,
    super.entries,
    super.entriesLoader,
    super.selectedEntries,
    super.selectedEntriesLoader,
    super.resetEntries,
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
    super.searchEnabled,
    super.searchPredicate,
    super.searchHintText,
    super.searchDebounceDuration,
    super.searchBarTheme,
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
  ///
  /// Deprecated: `FlattenSelect` no longer uses the delegate's grid
  /// parameters. Set a [SelectGridLayout] on
  /// [SelectCategoryEntry.layout] instead.
  @Deprecated(
    'Use SelectGridLayout.crossAxisCount on SelectCategoryEntry.layout instead.',
  )
  final int crossAxisCount;

  /// Spacing between rows.
  ///
  /// Deprecated: `FlattenSelect` no longer uses the delegate's grid
  /// parameters. Set a [SelectGridLayout] on
  /// [SelectCategoryEntry.layout] instead.
  @Deprecated(
    'Use SelectGridLayout.mainAxisSpacing on SelectCategoryEntry.layout instead.',
  )
  final double mainAxisSpacing;

  /// Spacing between columns.
  ///
  /// Deprecated: `FlattenSelect` no longer uses the delegate's grid
  /// parameters. Set a [SelectGridLayout] on
  /// [SelectCategoryEntry.layout] instead.
  @Deprecated(
    'Use SelectGridLayout.crossAxisSpacing on SelectCategoryEntry.layout instead.',
  )
  final double crossAxisSpacing;

  /// Child aspect ratio for each tile.
  ///
  /// Deprecated: `FlattenSelect` no longer uses the delegate's grid
  /// parameters. Set a [SelectGridLayout] on
  /// [SelectCategoryEntry.layout] instead.
  @Deprecated(
    'Use SelectGridLayout.childAspectRatio on SelectCategoryEntry.layout instead.',
  )
  final double childAspectRatio;

  @override
  Widget buildBody(
    BuildContext context,
    List<SelectEntry> entries,
    Set<SelectEntry>? selectedEntries, {
    String searchQuery = '',
  }) {
    return FlattenSelect(
      delegate: this,
      entries: entries,
      selectedEntries: selectedEntries,
      searchQuery: searchQuery,
      searchPredicate: searchPredicate,
      // ignore: deprecated_member_use_from_same_package
      crossAxisCount: crossAxisCount,
      // ignore: deprecated_member_use_from_same_package
      mainAxisSpacing: mainAxisSpacing,
      // ignore: deprecated_member_use_from_same_package
      crossAxisSpacing: crossAxisSpacing,
      // ignore: deprecated_member_use_from_same_package
      childAspectRatio: childAspectRatio,
    );
  }

  @override
  Widget buildSkeleton(BuildContext context) {
    return skeletonBuilder?.call(context) ??
        FlattenSelectSkeleton(
          sideBarWidth: sideBarTheme?.width,
          // ignore: deprecated_member_use_from_same_package
          crossAxisCount: crossAxisCount,
          // ignore: deprecated_member_use_from_same_package
          mainAxisSpacing: mainAxisSpacing,
          // ignore: deprecated_member_use_from_same_package
          crossAxisSpacing: crossAxisSpacing,
          // ignore: deprecated_member_use_from_same_package
          childAspectRatio: childAspectRatio,
        );
  }
}
