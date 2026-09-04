import 'package:flutter/material.dart';

import '../i18n/select_localizations.dart';
import 'cascading_select.dart';
import 'constants.dart';
import 'expandable_select.dart';
import 'flatten_select.dart';
import 'grid_select.dart';
import 'list_select.dart';
import 'select_entry.dart';
import 'select_layout.dart';
import 'select_panel_theme.dart';
import 'select_search_filter.dart';
import 'side_nav_select.dart';
import 'tab_nav_select.dart';
import 'widgets/widgets.dart';
import 'wrap_select.dart';

/// Builds the action bar shown at the bottom of the select panel.
///
/// Implementations should trigger [onResetTap] and [onApplyTap] from UI controls
/// (e.g. buttons).
typedef SelectActionBarBuilder = Widget Function(
  BuildContext context, {
  required VoidCallback onResetTap,
  required VoidCallback onApplyTap,
});

/// Builds a fully custom item widget for one select entry.
///
/// When provided to a delegate's `itemBuilder`, the returned widget replaces
/// the default item widget (radio/checkbox list tile, grid tile or chip)
/// entirely, including the built-in selected-state visuals. Render your own
/// selected highlight from [selected] and wire [onTap] to a gesture handler
/// (e.g. [InkWell.onTap]) so the entry toggles through the library's normal
/// selection flow.
///
/// Only regular entries are passed to the builder; custom range entries keep
/// rendering as the built-in min/max input field.
typedef SelectItemBuilder = Widget Function(
  BuildContext context,
  SelectEntry entry, {
  required bool selected,
  required VoidCallback onTap,
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

  /// Optional builder invoked when [entriesLoader] fails to load.
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

  /// Builds the error widget shown when [entriesLoader] fails to load.
  ///
  /// Returns the result of [errorBuilder] when provided, otherwise a simple
  /// [Text] widget showing the error.
  Widget buildError(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    return errorBuilder?.call(error, stackTrace) ??
        Center(
          child: Text(
            SelectLocalizations.of(context)?.error(error) ?? 'Error: $error',
          ),
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
    this.itemBuilder,
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

  /// Optional builder that fully replaces each item's widget.
  ///
  /// When non-null, regular entries render as the returned widget instead of
  /// the default radio/checkbox list tile; the builder renders its own
  /// selected-state visuals from `selected` and wires `onTap` (e.g. via
  /// [InkWell]) to trigger the selection. Custom range entries still render
  /// as the built-in min/max input field.
  ///
  /// Only used when rendering flat (parentless) data; the deprecated
  /// two-level fallback to [ExpandableSelectDelegate] does not forward it.
  final SelectItemBuilder? itemBuilder;

  @override
  Widget buildBody(
    BuildContext context,
    List<SelectEntry> entries,
    Set<SelectEntry>? selectedEntries, {
    String searchQuery = '',
  }) {
    if (entries.isNotEmpty && entries.first is SelectCategoryEntry) {
      assert(() {
        if (!_didWarnCategoryData) {
          _didWarnCategoryData = true;
          debugPrint(
            'ListSelectDelegate: rendering two-level (category) data is '
            'deprecated; use ExpandableSelectDelegate instead. '
            'Will be removed in a future minor version.',
          );
        }
        return true;
      }());
      return ExpandableSelect(
        delegate: ExpandableSelectDelegate(
          selectionMode: selectionMode,
          entries: entries.toSet(),
          selectedEntries: selectedEntries,
          resetEntries: resetEntries,
          actionBarBuilder: actionBarBuilder,
          selectedColor: selectedColor,
          onSelectedColor: onSelectedColor,
          backgroundColor: backgroundColor,
          onBackgroundColor: onBackgroundColor,
          backgroundColorHigh: backgroundColorHigh,
          backgroundColorHighest: backgroundColorHighest,
          onBackgroundColorHighest: onBackgroundColorHighest,
          resetText: resetText,
          applyText: applyText,
          searchEnabled: searchEnabled,
          searchPredicate: searchPredicate,
          searchHintText: searchHintText,
          searchDebounceDuration: searchDebounceDuration,
          searchBarTheme: searchBarTheme,
          actionBarTheme: actionBarTheme,
          sideBarTheme: sideBarTheme,
          tabBarTheme: tabBarTheme,
          gridTileTheme: gridTileTheme,
          listTileTheme: listTileTheme,
          fieldTileTheme: fieldTileTheme,
          expansionTileTheme: expansionTileTheme,
          chipBarTheme: chipBarTheme,
          panelTheme: panelTheme,
          skeletonBuilder: skeletonBuilder,
          errorBuilder: errorBuilder,
          radioBuilder: radioBuilder,
          checkboxBuilder: checkboxBuilder,
        ),
        entries: entries,
        selectedEntries: selectedEntries,
        searchQuery: searchQuery,
        searchPredicate: searchPredicate,
      );
    }
    return ListSelect(
      delegate: this,
      entries: entries,
      selectedEntries: selectedEntries,
      searchQuery: searchQuery,
      searchPredicate: searchPredicate,
    );
  }

  /// Whether the deprecation warning for two-level data has been emitted.
  static bool _didWarnCategoryData = false;

  @override
  Widget buildSkeleton(BuildContext context) {
    return skeletonBuilder?.call(context) ??
        ListSelectSkeleton(selectionMode: selectionMode);
  }
}

/// A grid select for flat (parentless) data.
///
/// The top-level entries render directly in a grid; no category tabs are
/// shown.
///
/// Rendering two-level (category) data through this delegate is deprecated;
/// use [TabNavSelectDelegate] instead. It will be removed in a future minor
/// version.
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
    this.itemBuilder,
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

  /// Optional builder that fully replaces each tile's widget.
  ///
  /// When non-null, regular entries render as the returned widget instead of
  /// the default grid tile; the builder renders its own selected-state
  /// visuals from `selected` and wires `onTap` (e.g. via [InkWell]) to
  /// trigger the selection. Custom range entries still render as the built-in
  /// min/max input field.
  ///
  /// Only used when rendering flat (parentless) data; the deprecated
  /// two-level fallback to [TabNavSelectDelegate] does not forward it.
  final SelectItemBuilder? itemBuilder;

  @override
  Widget buildBody(
    BuildContext context,
    List<SelectEntry> entries,
    Set<SelectEntry>? selectedEntries, {
    String searchQuery = '',
  }) {
    if (entries.isNotEmpty && entries.first is SelectCategoryEntry) {
      assert(() {
        if (!_didWarnCategoryData) {
          _didWarnCategoryData = true;
          debugPrint(
            'GridSelectDelegate: rendering two-level (category) data is '
            'deprecated; use TabNavSelectDelegate instead. '
            'Will be removed in a future minor version.',
          );
        }
        return true;
      }());
      return TabNavSelect(
        delegate: TabNavSelectDelegate(
          defaultLayout: SelectGridLayout(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            mainAxisSpacing: mainAxisSpacing,
            crossAxisSpacing: crossAxisSpacing,
          ),
          selectionMode: selectionMode,
          entries: entries.toSet(),
          selectedEntries: selectedEntries,
          resetEntries: resetEntries,
          actionBarBuilder: actionBarBuilder,
          selectedColor: selectedColor,
          onSelectedColor: onSelectedColor,
          backgroundColor: backgroundColor,
          onBackgroundColor: onBackgroundColor,
          backgroundColorHigh: backgroundColorHigh,
          backgroundColorHighest: backgroundColorHighest,
          onBackgroundColorHighest: onBackgroundColorHighest,
          resetText: resetText,
          applyText: applyText,
          searchEnabled: searchEnabled,
          searchPredicate: searchPredicate,
          searchHintText: searchHintText,
          searchDebounceDuration: searchDebounceDuration,
          searchBarTheme: searchBarTheme,
          actionBarTheme: actionBarTheme,
          sideBarTheme: sideBarTheme,
          tabBarTheme: tabBarTheme,
          gridTileTheme: gridTileTheme,
          listTileTheme: listTileTheme,
          fieldTileTheme: fieldTileTheme,
          expansionTileTheme: expansionTileTheme,
          chipBarTheme: chipBarTheme,
          panelTheme: panelTheme,
          skeletonBuilder: skeletonBuilder,
          errorBuilder: errorBuilder,
          radioBuilder: radioBuilder,
          checkboxBuilder: checkboxBuilder,
        ),
        entries: entries,
        selectedEntries: selectedEntries,
        searchQuery: searchQuery,
        searchPredicate: searchPredicate,
      );
    }
    return GridSelect(
      delegate: this,
      entries: entries,
      selectedEntries: selectedEntries,
      searchQuery: searchQuery,
      searchPredicate: searchPredicate,
    );
  }

  /// Whether the deprecation warning for two-level data has been emitted.
  static bool _didWarnCategoryData = false;

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

/// A wrap select for flat (parentless) data.
///
/// The top-level entries render directly as a wrapable chip bar; no
/// category navigation is shown.
///
/// Two-level (category) structures are not supported; use
/// [SideNavSelectDelegate] for two-level data.
class WrapSelectDelegate extends SelectDelegate {
  WrapSelectDelegate({
    this.spacing = 0.0,
    this.runSpacing = 0.0,
    this.itemBuilder,
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
  }) : assert(
          entries == null ||
              entries.isEmpty ||
              entries.first is! SelectCategoryEntry,
          'WrapSelectDelegate only supports flat (parentless) data. '
          'Use SideNavSelectDelegate for two-level (category) data.',
        );

  /// Horizontal spacing between chips in a wrapped row.
  ///
  /// Forwarded to [SelectChipBar.spacing]. Defaults to 0.0.
  final double spacing;

  /// Vertical spacing between wrapped chip rows.
  ///
  /// Forwarded to [SelectChipBar.runSpacing]. Defaults to 0.0.
  final double runSpacing;

  /// Optional builder that fully replaces each chip's widget.
  ///
  /// When non-null, regular entries render as the returned widget instead of
  /// the default chip; the builder renders its own selected-state visuals
  /// from `selected` and wires `onTap` (e.g. via [InkWell]) to trigger the
  /// selection. Custom range entries still render as the built-in min/max
  /// input field.
  final SelectItemBuilder? itemBuilder;

  @override
  Widget buildBody(
    BuildContext context,
    List<SelectEntry> entries,
    Set<SelectEntry>? selectedEntries, {
    String searchQuery = '',
  }) {
    assert(
      entries.isEmpty || entries.first is! SelectCategoryEntry,
      'WrapSelectDelegate only supports flat (parentless) data. '
      'Use SideNavSelectDelegate for two-level (category) data.',
    );
    return WrapSelect(
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
        WrapSelectSkeleton(spacing: spacing, runSpacing: runSpacing);
  }
}

/// A cascading select for two-level-or-deeper (category) tree data.
///
/// This layout shows categories on the left and cascading item columns to
/// the right, expanding one column per level with unlimited depth
/// (category -> child -> grandchild -> ...).
///
/// Flat (parentless) structures are not supported; use
/// [ListSelectDelegate], [GridSelectDelegate] or [WrapSelectDelegate]
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

/// A tab-nav (top-navigation) select for two-level (category) data.
///
/// Category tabs on top drive which category's children are shown below,
/// laid out by the category's `layout` (defaulting to [defaultLayout], then
/// to a 3-column grid). When only one category is available, the tab bar is
/// hidden.
///
/// Flat (parentless) structures are not supported; use
/// [GridSelectDelegate] or [ListSelectDelegate] for flat data.
///
/// At most two levels are rendered; levels nested deeper than the second
/// are not rendered. Use [CascadingSelectDelegate] for multi-level
/// (cascading) data.
class TabNavSelectDelegate extends SelectDelegate {
  TabNavSelectDelegate({
    this.defaultLayout,
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
  }) : assert(
          entries == null ||
              entries.isEmpty ||
              entries.first is SelectCategoryEntry,
          'TabNavSelectDelegate only supports two-level (category) data. '
          'Use ListSelectDelegate, GridSelectDelegate or '
          'WrapSelectDelegate for flat data.',
        );

  /// The layout used by categories that leave their `layout` null,
  /// defaulting to a 3-column grid (`SelectGridLayout(crossAxisCount: 3)`)
  /// when null.
  final SelectLayout? defaultLayout;

  /// Optional custom radio widget builder.
  final ToggleWidgetBuilder? radioBuilder;

  /// Optional custom checkbox widget builder.
  final ToggleWidgetBuilder? checkboxBuilder;

  /// Whether the category tab bar can be scrolled horizontally.
  ///
  /// If true, the tabs are laid out at their natural width inside a
  /// horizontal scroll view. If false (the default), the tabs are expanded
  /// to divide the available width equally.
  final bool isScrollable;

  @override
  Widget buildBody(
    BuildContext context,
    List<SelectEntry> entries,
    Set<SelectEntry>? selectedEntries, {
    String searchQuery = '',
  }) {
    assert(
      entries.isEmpty || entries.first is SelectCategoryEntry,
      'TabNavSelectDelegate only supports two-level (category) data. '
      'Use GridSelectDelegate or ListSelectDelegate for flat data.',
    );
    return TabNavSelect(
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
        TabNavSelectSkeleton(
          itemCount: 15,
          crossAxisCount: 3,
        );
  }
}

/// Deprecated "flatten" select.
///
/// - For two-level (category) data, use [SideNavSelectDelegate] (renamed).
/// - For flat (parentless) data, use [WrapSelectDelegate].
@Deprecated(
  'Use SideNavSelectDelegate for two-level data or WrapSelectDelegate for '
  'flat data. Will be removed in a future minor version.',
)
class FlattenSelectDelegate extends SelectDelegate {
  FlattenSelectDelegate({
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

  /// Copies this delegate's configuration into a [SideNavSelectDelegate].
  SideNavSelectDelegate toSideNav() => SideNavSelectDelegate(
        selectionMode: selectionMode,
        entries: entries,
        entriesLoader: entriesLoader,
        selectedEntries: selectedEntries,
        selectedEntriesLoader: selectedEntriesLoader,
        resetEntries: resetEntries,
        resetEntriesLoader: resetEntriesLoader,
        actionBarBuilder: actionBarBuilder,
        selectedColor: selectedColor,
        onSelectedColor: onSelectedColor,
        backgroundColor: backgroundColor,
        onBackgroundColor: onBackgroundColor,
        backgroundColorHigh: backgroundColorHigh,
        backgroundColorHighest: backgroundColorHighest,
        onBackgroundColorHighest: onBackgroundColorHighest,
        resetText: resetText,
        applyText: applyText,
        searchEnabled: searchEnabled,
        searchPredicate: searchPredicate,
        searchHintText: searchHintText,
        searchDebounceDuration: searchDebounceDuration,
        searchBarTheme: searchBarTheme,
        actionBarTheme: actionBarTheme,
        sideBarTheme: sideBarTheme,
        tabBarTheme: tabBarTheme,
        gridTileTheme: gridTileTheme,
        listTileTheme: listTileTheme,
        fieldTileTheme: fieldTileTheme,
        expansionTileTheme: expansionTileTheme,
        chipBarTheme: chipBarTheme,
        panelTheme: panelTheme,
      );

  /// Copies this delegate's configuration into a [WrapSelectDelegate].
  ///
  /// Passes the historical default chip spacing (12.0) for backward
  /// compatibility, since [WrapSelectDelegate] now defaults to 0.0.
  WrapSelectDelegate toWrap() => WrapSelectDelegate(
        spacing: 12.0,
        runSpacing: 12.0,
        selectionMode: selectionMode,
        entries: entries,
        entriesLoader: entriesLoader,
        selectedEntries: selectedEntries,
        selectedEntriesLoader: selectedEntriesLoader,
        resetEntries: resetEntries,
        resetEntriesLoader: resetEntriesLoader,
        actionBarBuilder: actionBarBuilder,
        selectedColor: selectedColor,
        onSelectedColor: onSelectedColor,
        backgroundColor: backgroundColor,
        onBackgroundColor: onBackgroundColor,
        backgroundColorHigh: backgroundColorHigh,
        backgroundColorHighest: backgroundColorHighest,
        onBackgroundColorHighest: onBackgroundColorHighest,
        resetText: resetText,
        applyText: applyText,
        searchEnabled: searchEnabled,
        searchPredicate: searchPredicate,
        searchHintText: searchHintText,
        searchDebounceDuration: searchDebounceDuration,
        searchBarTheme: searchBarTheme,
        actionBarTheme: actionBarTheme,
        sideBarTheme: sideBarTheme,
        tabBarTheme: tabBarTheme,
        gridTileTheme: gridTileTheme,
        listTileTheme: listTileTheme,
        fieldTileTheme: fieldTileTheme,
        expansionTileTheme: expansionTileTheme,
        chipBarTheme: chipBarTheme,
        panelTheme: panelTheme,
      );

  @override
  Widget buildBody(
    BuildContext context,
    List<SelectEntry> entries,
    Set<SelectEntry>? selectedEntries, {
    String searchQuery = '',
  }) {
    // ignore: deprecated_member_use_from_same_package
    return FlattenSelect(
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
        SideNavSelectSkeleton(
          sideBarWidth: sideBarTheme?.width,
        );
  }
}

/// A side-navigation select for two-level (category) data.
///
/// Category navigation sits on the left; tapping it scrolls the single
/// right column to that category's children, laid out by the category's
/// `layout` (defaulting to [defaultLayout], then to a wrapable chip
/// layout). Scrolling the right column highlights the left side.
///
/// Flat (parentless) structures are not supported; use
/// [WrapSelectDelegate] for flat data.
///
/// At most two levels are rendered; levels nested deeper than the second
/// are not rendered. Use [CascadingSelectDelegate] for multi-level
/// (cascading) data.
class SideNavSelectDelegate extends SelectDelegate {
  SideNavSelectDelegate({
    this.defaultLayout,
    this.isScrollable = true,
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
  }) : assert(
          entries == null ||
              entries.isEmpty ||
              entries.first is SelectCategoryEntry,
          'SideNavSelectDelegate only supports two-level (category) data. '
          'Use WrapSelectDelegate for flat data.',
        );

  final SelectLayout? defaultLayout;

  /// Whether the left category sidebar can be scrolled vertically.
  ///
  /// If true (the default), the category tiles are laid out at their natural
  /// height inside a vertical scroll view. If false, the tiles are expanded
  /// to divide the sidebar's available height equally (when the sidebar has
  /// a bounded height).
  ///
  /// This only affects the left category sidebar; the right content column
  /// is always scrollable.
  final bool isScrollable;

  @override
  Widget buildBody(
    BuildContext context,
    List<SelectEntry> entries,
    Set<SelectEntry>? selectedEntries, {
    String searchQuery = '',
  }) {
    assert(
      entries.isEmpty || entries.first is SelectCategoryEntry,
      'SideNavSelectDelegate only supports two-level (category) data. '
      'Use WrapSelectDelegate for flat data.',
    );
    return SideNavSelect(
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
        SideNavSelectSkeleton(
          sideBarWidth: sideBarTheme?.width,
        );
  }
}

/// An expandable-group select for two-level (category) data.
///
/// Each category renders as an expandable tile whose children are laid
/// out by the category's `layout` (defaulting to [defaultLayout], then to
/// a list layout). A category's `header`/`footer` entries (if any) render
/// as chip bars above/below that category's expanded content.
///
/// Flat (parentless) structures are not supported; use
/// [ListSelectDelegate] for flat data.
///
/// At most two levels are rendered; levels nested deeper than the second
/// are not rendered. Use [CascadingSelectDelegate] for multi-level
/// (cascading) data.
class ExpandableSelectDelegate extends SelectDelegate {
  ExpandableSelectDelegate({
    this.defaultLayout,
    this.radioBuilder,
    this.checkboxBuilder,
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
  }) : assert(
          entries == null ||
              entries.isEmpty ||
              entries.first is SelectCategoryEntry,
          'ExpandableSelectDelegate only supports two-level (category) '
          'data. Use ListSelectDelegate for flat data.',
        );

  /// Layout used when a category does not specify its own `layout`.
  ///
  /// Defaults to a list layout.
  final SelectLayout? defaultLayout;

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
    assert(
      entries.isEmpty || entries.first is SelectCategoryEntry,
      'ExpandableSelectDelegate only supports two-level (category) data. '
      'Use ListSelectDelegate for flat data.',
    );
    return ExpandableSelect(
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
        ExpandableSelectSkeleton(
          selectionMode: selectionMode,
        );
  }
}
