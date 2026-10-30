import 'package:fl_select/fl_select.dart';
import 'package:material_ui/material_ui.dart';

import 'delegate_factory.dart';
import 'playground_l10n.dart';
import 'playground_params.dart';
import 'result_panel.dart';

/// Places a popup trigger ([PopupSelectButton] / [PopupSelectBar]) opposite
/// to where its overlay opens, so the popup always has room on screen:
/// `below` opens downward below a top-aligned trigger, `above` upward above
/// a bottom-aligned one, and `adaptive` keeps the trigger centered.
Alignment _triggerAlignment(PopupSelectDirection direction) {
  return switch (direction) {
    PopupSelectDirection.below => Alignment.topCenter,
    PopupSelectDirection.above => Alignment.bottomCenter,
    PopupSelectDirection.adaptive => Alignment.center,
  };
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
/// footer panel ([ResultPanel]) so playground users can inspect what each
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
  /// selects: a purely decorative icon (no action).
  Widget _headerLeadingIcon(BuildContext context) => const Icon(Icons.tune);

  /// Sample [SelectHeader.trailing] widget for the Dialog / Bottom Sheet
  /// selects: closes the popup without applying (result null).
  ///
  /// Applying the current selection is the job of the panel's action bar (the
  /// Apply button), not the header — the header is a pure custom-widget slot
  /// and does not couple to the panel's internal state.
  Widget _headerCloseButton(BuildContext context) => IconButton(
    icon: const Icon(Icons.close),
    onPressed: () => Navigator.of(context).pop(),
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
    final resultPanel = ResultPanel(
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
                  // object, but the category delegates' selects are
                  // stateful widgets and their [ListView] children (each
                  // [SelectGridView] has [AutomaticKeepAliveClientMixin]) can
                  // cache the old layout
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
                // Follow the overlay direction: below → top, above → bottom,
                // adaptive → center, so the popup has room to open.
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Align(
                    alignment: _triggerAlignment(p.direction),
                    child: PopupSelectButton(
                      // Re-key on the overlay direction: a direction switch
                      // rebuilds the button, whose internal controller
                      // disposes and closes any popup still open at the old
                      // anchor.
                      key: ValueKey(p.direction),
                      selectDelegate: widget.delegate,
                      label: l10n.titleOf(p.delegate),
                      variant: p.buttonVariant,
                      direction: p.direction,
                      onChanged: (selected) => _onChanged(selected),
                      onApplied: (selected) => _onApplied(selected),
                    ),
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
                // Follow the overlay direction: below → top, above → bottom,
                // adaptive → center, so the popup has room to open.
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Align(
                    alignment: _triggerAlignment(p.direction),
                    child: PopupSelectBar(
                      // Re-key on the overlay direction: a direction switch
                      // rebuilds the bar, whose internal controller disposes
                      // and closes any popup still open at the old anchor.
                      key: ValueKey(p.direction),
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
                        leading: p.headerLeading ? _headerLeadingIcon(c) : null,
                        trailing: p.headerTrailing
                            ? _headerCloseButton(c)
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
                        leading: p.headerLeading ? _headerLeadingIcon(c) : null,
                        trailing: p.headerTrailing
                            ? _headerCloseButton(c)
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
