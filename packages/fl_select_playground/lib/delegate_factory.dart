import 'package:fl_select/fl_select.dart';
import 'package:material_ui/material_ui.dart';

import 'entry_repository.dart';
import 'my_widgets.dart';
import 'playground_params.dart';

SelectGridTileVariant _gridVariant(TileVariant v) => v == TileVariant.outlined
    ? SelectGridTileVariant.outlined
    : SelectGridTileVariant.filled;

SelectChipVariant _chipVariant(TileVariant v) => v == TileVariant.outlined
    ? SelectChipVariant.outlined
    : SelectChipVariant.filled;

Widget _radioBuilder(BuildContext context, bool selected) =>
    MyRadio(value: selected);

Widget _checkboxBuilder(BuildContext context, bool selected) =>
    MyCheckbox(value: selected);

/// Loader trio (entries / current selection / reset selection) for a single
/// delegate family. Keeping them together lets the playground swap a whole
/// demo data set behind one interface.
class DelegateLoaders {
  final Future<SelectEntries> Function() entriesLoader;
  final SelectEntries? selected;
  final SelectEntries? reset;

  const DelegateLoaders({
    required this.entriesLoader,
    required this.selected,
    required this.reset,
  });
}

/// Bundles the demo data used by the playground so the same delegate builder
/// works for every delegate family. The data set comes from a single
/// language-independent [EntryRepository].
class PlaygroundDataSource {
  final DelegateLoaders list;
  final DelegateLoaders grid;
  final DelegateLoaders wrap;
  final DelegateLoaders cascading;
  final DelegateLoaders tabNav;
  final DelegateLoaders sideNav;
  final DelegateLoaders expandable;

  const PlaygroundDataSource({
    required this.list,
    required this.grid,
    required this.wrap,
    required this.cascading,
    required this.tabNav,
    required this.sideNav,
    required this.expandable,
  });

  /// Builds the demo data set from [repo].
  factory PlaygroundDataSource.fromRepository(EntryRepository repo) {
    // the category delegates (tabNav / sideNav / expandable)
    // share the category sample.
    final twoLevel = DelegateLoaders(
      entriesLoader: repo.fetchTwoLevelData,
      selected: repo.twoLevelSelectedData,
      reset: repo.twoLevelResetData,
    );
    return PlaygroundDataSource(
      list: DelegateLoaders(
        entriesLoader: repo.fetchListData,
        selected: repo.listSelectedData,
        reset: repo.listResetData,
      ),
      grid: DelegateLoaders(
        entriesLoader: repo.fetchGridData,
        selected: repo.gridSelectedData,
        reset: repo.gridResetData,
      ),
      wrap: DelegateLoaders(
        entriesLoader: repo.fetchWrapData,
        selected: repo.wrapSelectedData,
        reset: repo.wrapResetData,
      ),
      cascading: DelegateLoaders(
        entriesLoader: repo.fetchCascadingData,
        selected: repo.cascadingSelectedData,
        reset: repo.cascadingResetData,
      ),
      tabNav: twoLevel,
      sideNav: twoLevel,
      expandable: twoLevel,
    );
  }
}

/// Reusable delegates keyed by the params that affect the delegate identity.
///
/// Every geometry value is part of the key: grid reads `crossAxisCount` /
/// `childAspectRatio` / `crossAxisSpacing` / `mainAxisSpacing` and wrap reads
/// `spacing` / `runSpacing` from their constructors at build time, so
/// excluding them would keep reusing a stale delegate and make the geometry
/// controls have no effect.
///
/// The delegate is still cached so that changing *other* params (e.g. seed
/// color, theme) does not discard the applied selection stored in
/// [SelectDelegate.selectedData]; only the params in this key recreate it.
String _delegateKey(PlaygroundParams p) =>
    '${p.delegate}|${p.selectionMode}|${p.tileVariant}|'
    '${p.crossAxisCount}|${p.childAspectRatio}|'
    '${p.crossAxisSpacing}|${p.mainAxisSpacing}|'
    '${p.spacing}|${p.runSpacing}|${p.cascadingScrollable}|'
    '${p.searchEnabled}';

/// Selection-identity key: the params that define *which* selection state a
/// delegate carries. Geometry is intentionally excluded — it only affects
/// rendering and is handled by [buildDelegate] so the applied selection
/// survives a Columns / Aspect Ratio / Spacing tweak.
String _selectionKey(PlaygroundParams p) =>
    '${p.delegate}|${p.selectionMode}|${p.tileVariant}';

/// Builds (or reuses) a [SelectDelegate] for the current [PlaygroundParams].
///
/// The delegate is cached in [delegateCache] (keyed by the full param set,
/// including geometry) so changing those renders with a delegate that
/// actually carries the new values — the library reads the geometry from the
/// delegate at build time.
///
/// Because [handleApply] writes the applied selection back to the delegate via
/// [SelectDelegate.selectedData], recreating the delegate on a geometry tweak
/// would otherwise drop that state. [selectionCache] (keyed by the
/// selection-identity params only) keeps the most recent delegate for a given
/// selection, and its `selectedData` is carried over to the freshly built
/// delegate so reopening the panel still restores the selection.
SelectDelegate buildDelegate(
  PlaygroundParams p,
  PlaygroundDataSource data, {
  required Map<String, SelectDelegate> delegateCache,
  required Map<String, SelectDelegate> selectionCache,
}) {
  final key = _delegateKey(p);
  if (delegateCache[key] != null) return delegateCache[key]!;
  final delegate = _createDelegate(p, data);
  final previous = selectionCache[_selectionKey(p)];
  if (previous != null && previous != delegate) {
    delegate.selectedEntries = previous.selectedEntries;
  }
  delegateCache[key] = delegate;
  selectionCache[_selectionKey(p)] = delegate;
  return delegate;
}

SelectDelegate _createDelegate(PlaygroundParams p, PlaygroundDataSource data) {
  // Since 0.14.0 the single-row `SelectChipBar` and the wrapping
  // `SelectWrapView` own independent themes: `chipBarTheme` styles the bars
  // (a category's header/footer), `wrapViewTheme` styles the wrap form. Build
  // both from the same chip variant so either surface renders the chosen tile
  // style without falling back to the deprecated shared-chip-theme bridge.
  final chipVariant = _chipVariant(p.tileVariant);
  final chipBarTheme = SelectChipBarTheme(variant: chipVariant);
  final wrapViewTheme = SelectWrapViewTheme(variant: chipVariant);
  switch (p.delegate) {
    case Delegate.list:
      return ListSelectDelegate(
        entriesLoader: data.list.entriesLoader,
        selectedEntries: data.list.selected,
        resetEntries: data.list.reset,
        selectionMode: p.selectionMode,
        listTileTheme: const SelectListTileTheme(),
        radioBuilder: _radioBuilder,
        checkboxBuilder: _checkboxBuilder,
        searchEnabled: p.searchEnabled,
        searchPredicate: (entry, query) {
          return entry.name?.contains(query) == true;
        },
      );
    case Delegate.grid:
      return GridSelectDelegate(
        entriesLoader: data.grid.entriesLoader,
        selectedEntries: data.grid.selected,
        resetEntries: data.grid.reset,
        selectionMode: p.selectionMode,
        crossAxisCount: p.crossAxisCount,
        childAspectRatio: p.childAspectRatio,
        crossAxisSpacing: p.crossAxisSpacing,
        mainAxisSpacing: p.mainAxisSpacing,
        gridTileTheme: SelectGridTileTheme(
          variant: _gridVariant(p.tileVariant),
        ),
        searchEnabled: p.searchEnabled,
        searchPredicate: (entry, query) {
          return entry.name?.contains(query) == true;
        },
      );
    case Delegate.wrap:
      return WrapSelectDelegate(
        entriesLoader: data.wrap.entriesLoader,
        selectedEntries: data.wrap.selected,
        resetEntries: data.wrap.reset,
        selectionMode: p.selectionMode,
        spacing: p.spacing,
        runSpacing: p.runSpacing,
        wrapViewTheme: wrapViewTheme,
        searchEnabled: p.searchEnabled,
        searchPredicate: (entry, query) {
          return entry.name?.contains(query) == true;
        },
      );
    case Delegate.cascading:
      return CascadingSelectDelegate(
        entriesLoader: data.cascading.entriesLoader,
        selectedEntries: data.cascading.selected,
        resetEntries: data.cascading.reset,
        selectionMode: p.selectionMode,
        radioBuilder: _radioBuilder,
        checkboxBuilder: _checkboxBuilder,
        chipBarTheme: chipBarTheme,
        sideBarTheme: const SelectSideBarTheme(width: 120),
        isScrollable: p.cascadingScrollable,
        searchEnabled: p.searchEnabled,
        searchPredicate: (entry, query) {
          return entry.name?.contains(query) == true;
        },
      );
    case Delegate.tabNav:
      return TabNavSelectDelegate(
        defaultLayout: SelectGridLayout(
          crossAxisCount: 3,
          childAspectRatio: 3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
        ),
        entriesLoader: data.tabNav.entriesLoader,
        selectedEntries: data.tabNav.selected,
        resetEntries: data.tabNav.reset,
        selectionMode: p.selectionMode,
        gridTileTheme: SelectGridTileTheme(
          variant: _gridVariant(p.tileVariant),
        ),
        chipBarTheme: chipBarTheme,
        isScrollable: true,
        searchEnabled: p.searchEnabled,
        searchPredicate: (entry, query) {
          return entry.name?.contains(query) == true;
        },
      );
    case Delegate.sideNav:
      return SideNavSelectDelegate(
        defaultLayout: SelectWrapLayout(spacing: 12, runSpacing: 12),
        entriesLoader: data.sideNav.entriesLoader,
        selectedEntries: data.sideNav.selected,
        resetEntries: data.sideNav.reset,
        selectionMode: p.selectionMode,
        gridTileTheme: SelectGridTileTheme(
          variant: _gridVariant(p.tileVariant),
        ),
        chipBarTheme: chipBarTheme,
        wrapViewTheme: wrapViewTheme,
        sideBarTheme: const SelectSideBarTheme(width: 110),
        searchEnabled: p.searchEnabled,
        searchPredicate: (entry, query) {
          return entry.name?.contains(query) == true;
        },
      );
    case Delegate.expandable:
      return ExpandableSelectDelegate(
        entriesLoader: data.expandable.entriesLoader,
        selectedEntries: data.expandable.selected,
        resetEntries: data.expandable.reset,
        selectionMode: p.selectionMode,
        radioBuilder: _radioBuilder,
        checkboxBuilder: _checkboxBuilder,
        gridTileTheme: SelectGridTileTheme(
          variant: _gridVariant(p.tileVariant),
        ),
        chipBarTheme: chipBarTheme,
        searchEnabled: p.searchEnabled,
        searchPredicate: (entry, query) {
          return entry.name?.contains(query) == true;
        },
      );
  }
}
