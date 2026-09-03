import 'package:fl_select/fl_select.dart';
import 'package:flutter/material.dart';

import 'entry_repository.dart';
import 'my_widgets.dart';
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
    // the two-level delegates (tabNav / sideNav / expandable)
    // share the two-level sample.
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
  final chipBarTheme = SelectChipBarTheme(variant: _chipVariant(p.tileVariant));
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
        chipBarTheme: chipBarTheme,
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

  /// Navigator hosting the route-backed select opened from this screen — i.e.
  /// the dialog / bottom sheet pushed by [showSelect] /
  /// [showModalBottomSelect].
  ///
  /// Captured so [dispose] can dismiss a select that is still open: those
  /// routes live in the navigator's overlay rather than in this widget's
  /// subtree, so they survive the entry-point switch that disposes this
  /// screen and would otherwise stay on top of the newly built one.
  NavigatorState? _selectNavigator;

  void _onChanged(Object? value) => setState(() => _lastChanged = value);
  void _onApplied(Object? value) => setState(() => _lastApplied = value);

  @override
  void didUpdateWidget(covariant EntryPointScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A dialog / bottom-sheet select captured the *old* delegate when it was
    // opened; switching the delegate family leaves that stale popup on top
    // of the rebuilt phone. Close it so the next open uses the new delegate.
    if (oldWidget.params.delegate != widget.params.delegate &&
        _selectNavigator != null) {
      final navigator = _selectNavigator!;
      _selectNavigator = null;
      // Deferred by one frame, same reasoning as [dispose]: popping during
      // the build that delivers the new params would mark the navigator
      // dirty mid-build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (navigator.mounted) navigator.popUntil((route) => route.isFirst);
      });
    }
  }

  @override
  void dispose() {
    final navigator = _selectNavigator;
    _selectNavigator = null;
    if (navigator != null) {
      // Deferred by one frame: dispose() runs while the framework is still
      // building, and popping synchronously would mark the navigator dirty
      // in the middle of that build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Only the pushed select routes are popped: `isFirst` is the phone's
        // base page, which [PlaygroundPage] never removes.
        if (navigator.mounted) navigator.popUntil((route) => route.isFirst);
      });
    }
    super.dispose();
  }

  /// Sample [SelectHeader.leading] widget for the Dialog / Bottom Sheet
  /// selects: closes the popup without a result.
  Widget _headerCloseButton(BuildContext context) => IconButton(
    icon: const Icon(Icons.close),
    onPressed: () => Navigator.of(context).pop(),
  );

  /// Sample [SelectHeader.trailing] widget for the Dialog / Bottom Sheet
  /// selects: pops with a "confirmed" marker so the result panel reacts.
  Widget _headerConfirmButton(BuildContext context) => IconButton(
    icon: const Icon(Icons.check),
    onPressed: () => Navigator.of(context).pop('confirmed'),
  );

  /// The single open button of the Dialog / Bottom Sheet entry points: it
  /// opens the select of the delegate family chosen in the panel.
  Widget _openButton(
    BuildContext context,
    Future<Object?> Function(BuildContext, SelectDelegate, Widget title) open,
  ) {
    final l10n = widget.l10n;
    return Center(
      child: TextButton(
        onPressed: () async {
          _selectNavigator = Navigator.of(context);
          final result = await open(
            context,
            widget.delegate,
            Text(l10n.titleOf(widget.params.delegate)),
          );
          // The entry point may have switched (and this state been
          // disposed) while the select was open.
          if (!mounted) return;
          _selectNavigator = null;
          _onApplied(result);
        },
        child: Text(l10n.openSelect),
      ),
    );
  }

  /// Builds a select delegate for one tab of the popup bar, using the current
  /// playground params but a fixed delegate family so each tab shows a
  /// distinct select (one per [Delegate] family).
  ///
  /// The bar has no "active delegate" of its own, so every family renders
  /// with the panel's current geometry — which only grid and wrap read.
  SelectDelegate _tabDelegate(Delegate delegate) => buildDelegate(
    widget.params.copyWith(delegate: delegate),
    widget.data,
    delegateCache: widget.delegateCache,
    selectionCache: widget.selectionCache,
  );

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
                  // Geometry MUST be included: changing it yields a new delegate
                  // object, but the two-level delegates' selects are stateful
                  // widgets and their [ListView] children (each [SelectGridView]
                  // has [AutomaticKeepAliveClientMixin]) can cache the old layout
                  // when only the delegate object changes live.
                  // Re-keying the view forces a clean rebuild so Columns / Aspect
                  // Ratio actually take effect. The in-progress selection is not
                  // lost: [buildDelegate] restores it from [selectionCache].
                  key: ValueKey(
                    '${p.delegate}|${p.selectionMode}|${p.tileVariant}|'
                    '${p.crossAxisCount}|${p.childAspectRatio}|'
                    '${p.crossAxisSpacing}|${p.mainAxisSpacing}|'
                    '${p.spacing}|${p.runSpacing}|${p.cascadingScrollable}|'
                    '${p.searchEnabled}',
                  ),
                  delegate: widget.delegate,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  onChanged: (SelectEntries selected) {
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
      case EntryPoint.button:
        return Scaffold(
          appBar: AppBar(title: Text(l10n.phonePopupButtonTitle)),
          body: Column(
            children: <Widget>[
              Expanded(
                child: Center(
                  child: PopupSelectButton(
                    selectDelegate: widget.delegate,
                    label: l10n.titleOf(p.delegate),
                    variant: p.buttonVariant,
                    direction: p.direction,
                    onChanged: (selected) => _onChanged(selected),
                    onApplied: (selected) => _onApplied(selected),
                  ),
                ),
              ),
              resultPanel,
            ],
          ),
        );
      case EntryPoint.bar:
        final tabs = <(Delegate, String)>[
          (Delegate.list, l10n.layoutList),
          (Delegate.grid, l10n.layoutGrid),
          (Delegate.wrap, l10n.layoutWrap),
          (Delegate.cascading, l10n.layoutCascading),
          (Delegate.tabNav, l10n.layoutTabNav),
          (Delegate.sideNav, l10n.layoutSideNav),
          (Delegate.expandable, l10n.layoutExpandable),
        ];
        return Scaffold(
          appBar: AppBar(title: Text(l10n.phonePopupBarTitle)),
          body: Column(
            children: <Widget>[
              Expanded(
                child: Center(
                  child: PopupSelectBar(
                    isScrollable: p.isScrollable,
                    direction: p.direction,
                    tabs: <PopupTab>[
                      for (final tab in tabs) PopupTab(label: tab.$2),
                    ],
                    selectDelegates: <SelectDelegate>[
                      for (final tab in tabs) _tabDelegate(tab.$1),
                    ],
                    onChanged: (tabData, selected) =>
                        _onChanged((tabData: tabData, selected: selected)),
                    onApplied: (tabData, selected) =>
                        _onApplied((tabData: tabData, selected: selected)),
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
                    builder: (ctx) => _openButton(
                      ctx,
                      (c, delegate, title) => showSelect(
                        context: c,
                        delegate: delegate,
                        title: title,
                        leading: p.headerLeading ? _headerCloseButton(c) : null,
                        trailing: p.headerTrailing
                            ? _headerConfirmButton(c)
                            : null,
                        centerTitle: p.centerTitle,
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
                    builder: (ctx) => _openButton(
                      ctx,
                      (c, delegate, title) => showModalBottomSelect(
                        context: c,
                        delegate: delegate,
                        title: title,
                        leading: p.headerLeading ? _headerCloseButton(c) : null,
                        trailing: p.headerTrailing
                            ? _headerConfirmButton(c)
                            : null,
                        centerTitle: p.centerTitle,
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
///
/// A snackbar-style action button in the header toggles the panel: tapping it
/// expands the panel upwards over most of the body so long values stay
/// readable; tapping again collapses it back to the compact strip.
class _ResultPanel extends StatefulWidget {
  const _ResultPanel({required this.l10n, this.changed, this.applied});

  final PlaygroundL10n l10n;
  final Object? changed;
  final Object? applied;

  @override
  State<_ResultPanel> createState() => _ResultPanelState();
}

class _ResultPanelState extends State<_ResultPanel> {
  static const double _collapsedHeight = 112;

  /// Share of the body height the panel covers when expanded.
  static const double _expandedFactor = 0.65;

  bool _expanded = false;

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = widget.l10n;
    final isDark = theme.brightness == Brightness.dark;
    final background = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w600,
    );
    final valueStyle = theme.textTheme.bodySmall;

    String format(Object? value) => value == null ? '—' : value.toString();

    // The phone preview renders inside a [FittedBox], so the incoming layout
    // constraints are unbounded (maxHeight = infinity). The scoped
    // [MediaQuery] above the phone [Navigator] carries the true phone size
    // (kPhoneContentSize), so measure the expanded height against it instead.
    final expandedHeight = MediaQuery.sizeOf(context).height * _expandedFactor;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      height: _expanded ? expandedHeight : _collapsedHeight,
      decoration: BoxDecoration(color: background),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(child: Text(l10n.resultPanelTitle, style: labelStyle)),
                // Snackbar-style action: compact text button, arrow hints
                // the expand direction.
                TextButton.icon(
                  onPressed: _toggle,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    minimumSize: const Size(0, 30),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  icon: Icon(
                    _expanded
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_up,
                    size: 16,
                  ),
                  label: Text(
                    _expanded
                        ? l10n.resultPanelCollapse
                        : l10n.resultPanelExpand,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '${l10n.onChangedLabel}: ${format(widget.changed)}',
                      style: valueStyle,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${l10n.onAppliedLabel}: ${format(widget.applied)}',
                      style: valueStyle,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
