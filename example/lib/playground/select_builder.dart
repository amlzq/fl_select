import 'package:fl_select/fl_select.dart';
import 'package:flutter/material.dart';

import '../leyoujia/house_filters_repository.dart' as leyoujia;
import '../widgets/my_widgets.dart';
import '../zillow/house_filters_repository.dart' as zillow;
import 'playground_l10n.dart';
import 'playground_params.dart';

SelectGridTileVariant _gridVariant(TileVariant v) => v == TileVariant.outlined
    ? SelectGridTileVariant.outlined
    : SelectGridTileVariant.filled;

SelectChipVariant _chipVariant(TileVariant v) => v == TileVariant.outlined
    ? SelectChipVariant.outlined
    : SelectChipVariant.filled;

Widget _radioBuilder(BuildContext context, bool selected) =>
    MyRadio(value: selected);

/// Zillow's flatten sample ([HouseFiltersRepository.fetchMoreData]) assigns a
/// fixed [SelectGridLayout] (with its own column count / aspect ratio) to every
/// category. That makes the playground's Columns / Aspect Ratio controls have no
/// effect for the Flatten delegate, because [FlattenSelect] honors each
/// category's layout over the delegate's `crossAxisCount` / `childAspectRatio`.
///
/// Strip those per-category layouts so the grid falls back to the delegate's
/// `crossAxisCount` / `childAspectRatio` — i.e. the values driven by the
/// controls panel. Other delegate families (and Leyoujia's flatten sample, which
/// already ships layout-less categories) are unaffected.
Future<SelectEntries> _flattenEntriesWithoutFixedLayout(
  Future<SelectEntries> Function() loader,
) async {
  final entries = await loader();
  return entries.map((entry) {
    if (entry is SelectCategoryEntry) {
      return SelectCategoryEntry(
        id: entry.id,
        name: entry.name,
        children: entry.children,
        selectionMode: entry.selectionMode,
      );
    }
    return entry;
  }).toSet();
}

Widget _checkboxBuilder(BuildContext context, bool selected) =>
    MyCheckbox(value: selected);

/// Loader trio (entries / current selection / reset selection) for a single
/// delegate family. Keeping them together lets the playground swap the whole demo
/// data set (Zillow ↔ Leyoujia) behind one interface.
class DelegateLoaders {
  final Future<SelectEntries> Function() entries;
  final SelectEntries? Function() selected;
  final SelectEntries? Function() reset;

  const DelegateLoaders({
    required this.entries,
    required this.selected,
    required this.reset,
  });
}

/// Abstracts the demo data set used by the playground so the same delegate
/// builder works for both the English (Zillow) and Simplified Chinese
/// (Leyoujia) data.
class PlaygroundDataSource {
  final DelegateLoaders cascading;
  final DelegateLoaders grid;
  final DelegateLoaders flatten;
  final DelegateLoaders list;

  const PlaygroundDataSource({
    required this.cascading,
    required this.grid,
    required this.flatten,
    required this.list,
  });

  /// English demo → Zillow data.
  factory PlaygroundDataSource.zillow(zillow.HouseFiltersRepository repo) {
    return PlaygroundDataSource(
      cascading: DelegateLoaders(
        entries: repo.fetchNeighborhoodData,
        selected: repo.fetchNeighborhoodSelectedData,
        reset: repo.fetchNeighborhoodResetData,
      ),
      grid: DelegateLoaders(
        entries: repo.fetchRoomsData,
        selected: repo.fetchRoomsSelectedData,
        reset: repo.fetchRoomsResetData,
      ),
      flatten: DelegateLoaders(
        entries: () => _flattenEntriesWithoutFixedLayout(repo.fetchMoreData),
        selected: repo.fetchMoreSelectedData,
        reset: repo.fetchMoreResetData,
      ),
      list: DelegateLoaders(
        entries: repo.fetchSortData,
        selected: repo.fetchSortSelectedData,
        reset: repo.fetchSortResetData,
      ),
    );
  }

  /// Simplified Chinese demo → Leyoujia data.
  factory PlaygroundDataSource.leyoujia(leyoujia.HouseFiltersRepository repo) {
    return PlaygroundDataSource(
      cascading: DelegateLoaders(
        entries: repo.fetchRegionData,
        selected: repo.fetchRegionSelectedData,
        reset: repo.fetchRegionResetData,
      ),
      grid: DelegateLoaders(
        entries: repo.fetchBuyPriceData,
        selected: repo.fetchBuyPriceSelectedData,
        reset: repo.fetchBuyPriceResetData,
      ),
      flatten: DelegateLoaders(
        entries: repo.fetchFloorPlanBuyData,
        selected: repo.fetchFloorPlanBuySelectedData,
        reset: repo.fetchFloorPlanBuyResetData,
      ),
      list: DelegateLoaders(
        entries: repo.fetchSortBuyData,
        selected: repo.fetchSortBuySelectedData,
        reset: repo.fetchSortBuyResetData,
      ),
    );
  }
}

/// Reusable delegates keyed by the params that affect the delegate identity.
///
/// Column count / aspect ratio / spacing ARE part of the key: the grid and
/// flatten delegates read `crossAxisCount`, `childAspectRatio` and the spacings
/// from the delegate at build time (see [GridSelectDelegate] /
/// [FlattenSelectDelegate]), so
/// excluding them would keep reusing a stale delegate and make the Columns /
/// Aspect / Spacing controls have no effect.
///
/// The delegate is still cached so that changing *other* params (e.g. seed
/// color, theme) does not discard the applied selection stored in
/// [SelectDelegate.selectedData]; only the params in this key recreate it.
String _delegateKey(
  PlaygroundLanguage language,
  PlaygroundParams p,
) =>
    '${language.name}|${p.delegate}|${p.selectionMode}|${p.tileVariant}|'
    '${p.crossAxisCount}|${p.childAspectRatio}|${p.spacing}';

/// Selection-identity key: the params that define *which* selection state a
/// delegate carries. Column count / aspect ratio / spacing are intentionally
/// excluded — those only affect rendering and are handled by [buildDelegate]
/// so the applied selection survives a Columns / Aspect / Spacing tweak.
String _selectionKey(PlaygroundLanguage language, PlaygroundParams p) =>
    '${language.name}|${p.delegate}|${p.selectionMode}|${p.tileVariant}';

/// Builds (or reuses) a [SelectDelegate] for the current [PlaygroundParams].
///
/// The delegate is cached in [delegateCache] (keyed by the full param set,
/// including column count / aspect ratio / spacing) so changing those renders
/// with a delegate that actually carries the new values — the library reads
/// `crossAxisCount`, `childAspectRatio` and the spacings from the delegate at
/// build time.
///
/// Because [handleApply] writes the applied selection back to the delegate via
/// [SelectDelegate.selectedData], recreating the delegate on a Columns /
/// Aspect / Spacing tweak would otherwise drop that state. [selectionCache]
/// (keyed by the selection-identity params only) keeps the most recent delegate
/// for a given selection, and its `selectedData` is carried over to the freshly
/// built delegate so reopening the panel still restores the selection.
SelectDelegate buildDelegate(
  PlaygroundParams p,
  PlaygroundDataSource data,
  PlaygroundLanguage language, {
  required Map<String, SelectDelegate> delegateCache,
  required Map<String, SelectDelegate> selectionCache,
}) {
  final key = _delegateKey(language, p);
  final existing = delegateCache[key];
  if (existing != null) return existing;
  final delegate = _createDelegate(p, data);
  final previous = selectionCache[_selectionKey(language, p)];
  if (previous != null && previous != delegate) {
    delegate.selectedEntries = previous.selectedEntries;
  }
  delegateCache[key] = delegate;
  selectionCache[_selectionKey(language, p)] = delegate;
  return delegate;
}

SelectDelegate _createDelegate(PlaygroundParams p, PlaygroundDataSource data) {
  final chipBarTheme = SelectChipBarTheme(variant: _chipVariant(p.tileVariant));
  switch (p.delegate) {
    case Delegate.cascading:
      return CascadingSelectDelegate(
        entriesLoader: data.cascading.entries,
        selectedEntriesLoader: data.cascading.selected,
        resetEntriesLoader: data.cascading.reset,
        selectionMode: p.selectionMode,
        radioBuilder: _radioBuilder,
        checkboxBuilder: _checkboxBuilder,
        chipBarTheme: chipBarTheme,
        sideBarTheme: const SelectSideBarTheme(width: 150),
      );
    case Delegate.grid:
      // Grid / Flatten delegates use the default radio & checkbox widgets, so
      // the custom [MyRadio]/[MyCheckbox] builders are not forwarded here.
      return GridSelectDelegate(
        entriesLoader: data.grid.entries,
        selectedEntriesLoader: data.grid.selected,
        resetEntriesLoader: data.grid.reset,
        selectionMode: p.selectionMode,
        crossAxisCount: p.crossAxisCount,
        childAspectRatio: p.childAspectRatio,
        crossAxisSpacing: p.spacing,
        mainAxisSpacing: p.spacing,
        gridTileTheme:
            SelectGridTileTheme(variant: _gridVariant(p.tileVariant)),
        chipBarTheme: chipBarTheme,
      );
    case Delegate.flatten:
      return FlattenSelectDelegate(
        entriesLoader: data.flatten.entries,
        selectedEntriesLoader: data.flatten.selected,
        resetEntriesLoader: data.flatten.reset,
        selectionMode: p.selectionMode,
        gridTileTheme:
            SelectGridTileTheme(variant: _gridVariant(p.tileVariant)),
        chipBarTheme: chipBarTheme,
        sideBarTheme: const SelectSideBarTheme(width: 110),
      );
    case Delegate.list:
      return ListSelectDelegate(
        entriesLoader: data.list.entries,
        selectedEntriesLoader: data.list.selected,
        resetEntriesLoader: data.list.reset,
        selectionMode: p.selectionMode,
        listTileTheme: const SelectListTileTheme(),
        radioBuilder: _radioBuilder,
        checkboxBuilder: _checkboxBuilder,
        chipBarTheme: chipBarTheme,
      );
  }
}

/// Builds the widget shown on the phone screen for the chosen entry point.
///
/// Wrapped in a stateful [EntryPointScreen] so the latest `onChanged` /
/// `onApplied` values can be captured and displayed in a footer panel.
///
/// Dialog / bottom-sheet triggers use a nested [Builder] context so that
/// [showSelect] / [showModalBottomSelect] pick up the phone's local
/// (parameter-driven) theme rather than the surrounding app theme.
Widget buildPhoneScreen(
  PlaygroundParams p,
  SelectDelegate delegate,
  PlaygroundL10n l10n, {
  required PlaygroundDataSource data,
  required Map<String, SelectDelegate> delegateCache,
  required Map<String, SelectDelegate> selectionCache,
}) {
  // Keyed by the entry point so switching entry points resets the captured
  // callback results (each entry point exposes different callbacks).
  return EntryPointScreen(
    key: ValueKey(p.entryPoint),
    params: p,
    delegate: delegate,
    l10n: l10n,
    data: data,
    delegateCache: delegateCache,
    selectionCache: selectionCache,
  );
}

/// Stateful phone screen for a chosen entry point.
///
/// Besides rendering the trigger widget, it captures the latest values fired
/// by the select's `onChanged` / `onApplied` callbacks and shows them in a
/// footer panel ([_ResultPanel]) so playground users can inspect what each
/// callback returns.
///
/// [SelectView] applies immediately and hides the action bar, so its
/// [SelectView.onChanged] is mirrored into both fields. [showSelect] /
/// [showModalBottomSelect] deliver their result through the returned
/// [Future], which is shown as the applied value (no `onChanged` exists for
/// these entry points).
class EntryPointScreen extends StatefulWidget {
  const EntryPointScreen({
    required this.params,
    required this.delegate,
    required this.l10n,
    required this.data,
    required this.delegateCache,
    required this.selectionCache,
    super.key,
  });

  final PlaygroundParams params;
  final SelectDelegate delegate;
  final PlaygroundL10n l10n;
  final PlaygroundDataSource data;
  final Map<String, SelectDelegate> delegateCache;
  final Map<String, SelectDelegate> selectionCache;

  @override
  State<EntryPointScreen> createState() => _EntryPointScreenState();
}

class _EntryPointScreenState extends State<EntryPointScreen> {
  Object? _lastChanged;
  Object? _lastApplied;

  void _onChanged(Object? value) => setState(() => _lastChanged = value);
  void _onApplied(Object? value) => setState(() => _lastApplied = value);

  /// Builds the 4 per-delegate-family open buttons (Cascading / Grid / Flatten
  /// / List). Each opens the current entry point's select ([showSelect] or
  /// [showModalBottomSelect]) with the matching delegate family, so users can
  /// exercise every delegate from a single Dialog / Bottom Sheet screen.
  ///
  /// [open] is invoked with the resolved delegate and must return the select
  /// result future; it should call [showSelect] for the Dialog entry point or
  /// [showModalBottomSelect] for the Bottom Sheet entry point.
  Widget _familyOpenButtons(
    BuildContext context,
    Future<Object?> Function(BuildContext, SelectDelegate, Widget title) open,
  ) {
    final l10n = widget.l10n;
    final entries = <(Delegate, String, String)>[
      (Delegate.cascading, l10n.openCascadingSelect, l10n.titleCascadingSelect),
      (Delegate.grid, l10n.openGridSelect, l10n.titleGridSelect),
      (Delegate.flatten, l10n.openFlattenSelect, l10n.titleFlattenSelect),
      (Delegate.list, l10n.openListSelect, l10n.titleListSelect),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: entries.map((e) {
          final title = Text(e.$3);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: FilledButton(
              onPressed: () async {
                final result = await open(
                  context,
                  _tabDelegate(e.$1),
                  title,
                );
                _onApplied(result);
              },
              child: Text(e.$2),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Builds a select delegate for one tab of the dropdown bar, using the
  /// current playground params but a fixed delegate family so each tab shows a
  /// distinct select (cascading / grid / flatten / list).
  ///
  /// Each tab applies the per-delegate default Columns / Aspect Ratio (see
  /// [defaultCrossAxisCountByDelegate] / [defaultChildAspectRatioByDelegate])
  /// so the bar always renders with the defaults for that family instead of
  /// reusing the global (controls-panel) values.
  SelectDelegate _tabDelegate(Delegate delegate) {
    final tabParams = widget.params.copyWith(
      delegate: delegate,
      crossAxisCount: defaultCrossAxisCountByDelegate[delegate],
      childAspectRatio: defaultChildAspectRatioByDelegate[delegate],
    );
    return buildDelegate(
      tabParams,
      widget.data,
      widget.l10n.language,
      delegateCache: widget.delegateCache,
      selectionCache: widget.selectionCache,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.params;
    final l10n = widget.l10n;
    final resultPanel = _ResultPanel(
      l10n: l10n,
      changed: _lastChanged,
      applied: _lastApplied,
    );

    switch (p.entryPoint) {
      case EntryPoint.view:
        return Scaffold(
          appBar: AppBar(title: Text(l10n.phoneViewTitle)),
          body: Column(
            children: <Widget>[
              Expanded(
                child: SelectView(
                  // Key the view by every param that affects its rendered output.
                  // Columns / aspect ratio / spacing MUST be included: changing
                  // them yields a new delegate object, but the Flatten delegate's
                  // [FlattenSelect] is a stateful widget and its [ListView] children
                  // (each [SelectGridView] has [AutomaticKeepAliveClientMixin]) can
                  // cache the old layout when only the delegate object changes live.
                  // Re-keying the view forces a clean rebuild so Columns / Aspect
                  // Ratio actually take effect. The in-progress selection is not
                  // lost: [buildDelegate] restores it from [selectionCache].
                  key: ValueKey(
                    '${l10n.language}|${p.delegate}|${p.crossAxisCount}|'
                    '${p.childAspectRatio}|${p.spacing}|${p.selectionMode}|'
                    '${p.tileVariant}',
                  ),
                  delegate: widget.delegate,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  onChanged: (selected) {
                    // SelectView applies immediately: change == apply.
                    _onChanged(selected);
                    _onApplied(selected);
                  },
                ),
              ),
              resultPanel,
            ],
          ),
        );
      case EntryPoint.popupBar:
        final tabDelegates = <SelectDelegate>[
          _tabDelegate(Delegate.cascading),
          _tabDelegate(Delegate.grid),
          _tabDelegate(Delegate.flatten),
          _tabDelegate(Delegate.list),
        ];
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.phonePopupBarTitle),
            bottom: PopupSelectBar(
              tabs: <PopupTab>[
                PopupTab(label: l10n.layoutCascading),
                PopupTab(label: l10n.layoutGrid),
                PopupTab(label: l10n.layoutFlatten),
                PopupTab(label: l10n.layoutList),
              ],
              selectDelegates: tabDelegates,
              onChanged: (tabData, selected) =>
                  _onChanged((tabData: tabData, selected: selected)),
              onApplied: (tabData, selected) =>
                  _onApplied((tabData: tabData, selected: selected)),
            ),
          ),
          body: Column(
            children: <Widget>[
              Expanded(child: Center(child: Text(l10n.tapBarHint))),
              resultPanel,
            ],
          ),
        );
      case EntryPoint.popupButton:
        return Scaffold(
          appBar: AppBar(title: Text(l10n.phonePopupButtonTitle)),
          body: Column(
            children: <Widget>[
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      // cascadingSelect: elevated style, aligned to the left.
                      Align(
                        alignment: Alignment.centerLeft,
                        child: PopupSelectButton.elevated(
                          selectDelegate: _tabDelegate(Delegate.cascading),
                          label: l10n.titleCascadingSelect,
                          onChanged: (selected) => _onChanged(selected),
                          onApplied: (selected) => _onApplied(selected),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // gridSelect: filled style (default), centered.
                      Align(
                        alignment: Alignment.center,
                        child: PopupSelectButton(
                          selectDelegate: _tabDelegate(Delegate.grid),
                          label: l10n.titleGridSelect,
                          onChanged: (selected) => _onChanged(selected),
                          onApplied: (selected) => _onApplied(selected),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // flattenSelect: outlined style, aligned to the right.
                      Align(
                        alignment: Alignment.centerRight,
                        child: PopupSelectButton.outlined(
                          selectDelegate: _tabDelegate(Delegate.flatten),
                          label: l10n.titleFlattenSelect,
                          onChanged: (selected) => _onChanged(selected),
                          onApplied: (selected) => _onApplied(selected),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // listSelect: elevated style, offset 100px from the left edge.
                      Padding(
                        padding: const EdgeInsets.only(left: 100),
                        child: PopupSelectButton.elevated(
                          selectDelegate: _tabDelegate(Delegate.list),
                          label: l10n.titleListSelect,
                          onChanged: (selected) => _onChanged(selected),
                          onApplied: (selected) => _onApplied(selected),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              resultPanel,
            ],
          ),
        );
      case EntryPoint.dialog:
        return Scaffold(
          appBar: AppBar(title: Text(l10n.phoneDialogTitle)),
          body: Column(
            children: <Widget>[
              Expanded(
                child: Center(
                  child: Builder(
                    builder: (ctx) => _familyOpenButtons(
                      ctx,
                      (c, delegate, title) => showSelect(
                        context: c,
                        delegate: delegate,
                        title: title,
                        useRootNavigator: false,
                      ),
                    ),
                  ),
                ),
              ),
              resultPanel,
            ],
          ),
        );
      case EntryPoint.bottomSheet:
        return Scaffold(
          appBar: AppBar(title: Text(l10n.phoneBottomSheetTitle)),
          body: Column(
            children: <Widget>[
              Expanded(
                child: Center(
                  child: Builder(
                    builder: (ctx) => _familyOpenButtons(
                      ctx,
                      (c, delegate, title) => showModalBottomSelect(
                        context: c,
                        delegate: delegate,
                        title: title,
                      ),
                    ),
                  ),
                ),
              ),
              resultPanel,
            ],
          ),
        );
    }
  }
}

/// Footer panel that shows the most recent `onChanged` / `onApplied` values
/// for the active entry point.
class _ResultPanel extends StatelessWidget {
  const _ResultPanel({
    required this.l10n,
    this.changed,
    this.applied,
  });

  final PlaygroundL10n l10n;
  final Object? changed;
  final Object? applied;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final background = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w600,
    );
    final valueStyle = theme.textTheme.bodySmall;

    String format(Object? value) => value == null ? '—' : value.toString();

    return SizedBox(
      width: double.infinity,
      height: 112,
      child: DecoratedBox(
        decoration: BoxDecoration(color: background),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(l10n.resultPanelTitle, style: labelStyle),
              const SizedBox(height: 4),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '${l10n.onChangedLabel}: ${format(changed)}',
                        style: valueStyle,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${l10n.onAppliedLabel}: ${format(applied)}',
                        style: valueStyle,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
