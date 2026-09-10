import 'dart:async';

import 'package:flutter/material.dart';

import 'constants.dart';
import 'select_controller.dart';
import 'select_delegate.dart';
import 'select_entry.dart';
import 'select_theme.dart';
import 'select_theme_data.dart';
import 'widgets/widgets.dart';

/// A widget that renders a [SelectDelegate] and manages its selection state.
///
/// The panel loads the delegate's data ([SelectDelegate.entries] or
/// [SelectDelegate.entriesLoader]) and displays the select body once the data
/// is available, or a skeleton while it is loading. Select widgets rendered by
/// the panel are styled according to [selectTheme].
///
/// The selection state is driven by a [SelectController]. If [controller] is
/// omitted, the panel creates and owns an internal controller. In both cases
/// (an internal controller or a caller-provided one), the panel forwards
/// selection events through the [onChangeTap], [onApplyTap] and [onResetTap]
/// callbacks. When [controller] is provided, the caller still owns it and can
/// drive the selection programmatically (for example, with
/// [SelectController.select]); the panel-level callbacks are fired in addition
/// to any listeners registered directly on the controller.
///
/// The active controller is exposed to descendants via
/// [SelectControllerProvider].
class SelectPanel extends StatefulWidget {
  const SelectPanel({
    super.key,
    required this.delegate,
    this.controller,
    this.onChangeTap,
    this.onApplyTap,
    this.onResetTap,
    this.selectTheme,
  });

  final SelectDelegate delegate;

  /// Optional controller that drives the selection state.
  ///
  /// When provided, callers can call [SelectController.select] and other
  /// methods from outside the panel. The panel will not dispose a controller
  /// that it did not create.
  ///
  /// When a controller is supplied, the panel-level [onChangeTap],
  /// [onApplyTap] and [onResetTap] callbacks are forwarded in addition to any
  /// listeners registered directly on the controller. The panel will not
  /// dispose a controller that it did not create.
  final SelectController? controller;

  /// Fired when the selection changes.
  ///
  /// Forwarded in both cases, whether [controller] is provided or not.
  final SelectCallback? onChangeTap;

  /// Fired when the selection is applied.
  ///
  /// Forwarded in both cases, whether [controller] is provided or not.
  final SelectCallback? onApplyTap;

  /// Fired when reset is triggered.
  ///
  /// Forwarded in both cases, whether [controller] is provided or not.
  final VoidCallback? onResetTap;

  /// Theme overrides applied to the select widgets rendered by the panel.
  ///
  /// When null, a [SelectThemeData] derived from the ambient Material
  /// [ThemeData] is used. The delegate-level theme fields (when provided)
  /// are merged field-wise on top of this theme.
  final SelectThemeData? selectTheme;

  @override
  State<SelectPanel> createState() => _SelectPanelState();
}

class _SelectPanelState extends State<SelectPanel> {
  SelectController? _internalController;
  final List<VoidCallback> _unregister = [];

  // Search state
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;
  String _searchQuery = '';
  Timer? _debounceTimer;

  SelectController get _controller => widget.controller ?? _internalController!;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
    if (widget.controller == null) {
      _createInternalController();
    }
    _registerForwardingListeners();
  }

  void _createInternalController() {
    _internalController = SelectController(
      selectionMode: widget.delegate.selectionMode,
      selectedEntries: widget.delegate.selectedEntries,
      resetEntries: widget.delegate.resetEntries,
    );
  }

  /// Forwards the panel-level callbacks on the active controller, whether it is
  /// the internal one or a caller-provided one. Listeners are re-registered
  /// whenever the effective controller instance changes.
  void _registerForwardingListeners() {
    _unregister.add(_controller.addChangeListener((selected) {
      widget.onChangeTap?.call(selected);
    }));
    _unregister.add(_controller.addApplyListener((selected) {
      widget.onApplyTap?.call(selected);
    }));
    _unregister.add(_controller.addResetListener(() {
      widget.onResetTap?.call();
    }));
  }

  void _unregisterForwardingListeners() {
    for (final u in _unregister) {
      u();
    }
    _unregister.clear();
  }

  void _disposeInternalController() {
    _internalController?.dispose();
    _internalController = null;
  }

  @override
  void didUpdateWidget(covariant SelectPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _unregisterForwardingListeners();
      if (oldWidget.controller == null) {
        _disposeInternalController();
      }
      if (widget.controller == null) {
        _createInternalController();
      }
      _registerForwardingListeners();
    }
    // A new delegate means a new select (e.g. switching tabs reuses this
    // panel state inside a PopupSelectBar overlay). The search query is
    // delegate-scoped, so clear it instead of leaking it into the other
    // select.
    if (widget.delegate != oldWidget.delegate) {
      _resetSearchState();
    }
  }

  /// Clears the search text, cancels any pending debounce and drops focus,
  /// so a previously typed query does not filter the next delegate's entries.
  void _resetSearchState() {
    _debounceTimer?.cancel();
    _searchQuery = '';
    if (_searchController.text.isNotEmpty) {
      _searchController.clear();
    }
    if (_searchFocusNode.hasFocus) {
      _searchFocusNode.unfocus();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _unregisterForwardingListeners();
    _disposeInternalController();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(
      widget.delegate.searchDebounceDuration,
      () {
        if (!mounted) return;
        setState(() {
          _searchQuery = value.trim();
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme =
        widget.selectTheme ?? SelectThemeData.fallback(Theme.of(context));
    final delegateActionBarTheme = widget.delegate.actionBarTheme;
    final delegateSearchBarTheme = widget.delegate.searchBarTheme;
    final delegateTabBarTheme = widget.delegate.tabBarTheme;
    final delegateListTileTheme = widget.delegate.listTileTheme;
    final delegateExpansionTileTheme = widget.delegate.expansionTileTheme;
    final delegateChipBarTheme = widget.delegate.chipBarTheme;
    final delegateGridTileTheme = widget.delegate.gridTileTheme;
    final delegateFieldTileTheme = widget.delegate.fieldTileTheme;
    final delegateSideBarTheme = widget.delegate.sideBarTheme;
    final delegateRangeSliderTheme = widget.delegate.rangeSliderTheme;
    final effectiveTheme = baseTheme.copyWith(
      selectedColor: widget.delegate.selectedColor,
      onSelectedColor: widget.delegate.onSelectedColor,
      backgroundColor: widget.delegate.backgroundColor,
      onBackgroundColor: widget.delegate.onBackgroundColor,
      backgroundColorHigh: widget.delegate.backgroundColorHigh,
      backgroundColorHighest: widget.delegate.backgroundColorHighest,
      onBackgroundColorHighest: widget.delegate.onBackgroundColorHighest,
      panelTheme: widget.delegate.panelTheme == null
          ? null
          : baseTheme.panelTheme.merge(widget.delegate.panelTheme),
      actionBarTheme: delegateActionBarTheme == null
          ? null
          : baseTheme.actionBarTheme.merge(delegateActionBarTheme),
      searchBarTheme: delegateSearchBarTheme == null
          ? null
          : baseTheme.searchBarTheme.merge(delegateSearchBarTheme),
      tabBarTheme: delegateTabBarTheme == null
          ? null
          : baseTheme.tabBarTheme.merge(delegateTabBarTheme),
      listTileTheme: delegateListTileTheme == null
          ? null
          : baseTheme.listTileTheme.merge(delegateListTileTheme),
      expansionTileTheme: delegateExpansionTileTheme == null
          ? null
          : baseTheme.expansionTileTheme.merge(delegateExpansionTileTheme),
      chipBarThemeData: delegateChipBarTheme == null
          ? null
          : baseTheme.chipBarThemeData.merge(delegateChipBarTheme),
      gridTileTheme: delegateGridTileTheme == null
          ? null
          : baseTheme.gridTileTheme.merge(delegateGridTileTheme),
      fieldTileTheme: delegateFieldTileTheme == null
          ? null
          : baseTheme.fieldTileTheme.merge(delegateFieldTileTheme),
      sideBarTheme: delegateSideBarTheme == null
          ? null
          : baseTheme.sideBarTheme.merge(delegateSideBarTheme),
      rangeSliderTheme: delegateRangeSliderTheme == null
          ? null
          : baseTheme.rangeSliderTheme.merge(delegateRangeSliderTheme),
    );
    return SelectTheme(
      data: effectiveTheme,
      child: _PanelDecoratedBox(
        child: SelectControllerProvider(
          controller: _controller,
          child: _buildBody(context),
        ),
      ),
    );
  }

  /// Builds the select body: an async [FutureBuilder] around
  /// [SelectDelegate.asyncEntries] when a loader is used, or the content
  /// directly when entries were supplied synchronously — in which case the
  /// first frame renders the entries without a skeleton pass.
  Widget _buildBody(BuildContext context) {
    if (widget.delegate.hasSyncEntries) {
      return _buildContent(context, widget.delegate.entries!.toList());
    }
    return FutureBuilder<SelectEntries>(
      future: widget.delegate.asyncEntries,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return widget.delegate.buildError(
              context,
              snapshot.error!,
              snapshot.stackTrace,
            );
          } else {
            return _buildContent(
              context,
              snapshot.data?.toList() ?? <SelectEntry>[],
            );
          }
        } else {
          // Request in progress: show loading
          return widget.delegate.buildSkeleton(context);
        }
      },
    );
  }

  /// Validates [entries] up front and builds the search bar (when enabled)
  /// plus the delegate body.
  Widget _buildContent(BuildContext context, List<SelectEntry> entries) {
    // Validate the loaded entries up front so that bad parent/child
    // relationships surface through the error UI and are logged to the
    // console, instead of escaping during a descendant's build phase
    // (which freezes the frame).
    try {
      SelectController.validateEntries(entries);
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'fl_select',
          context: ErrorDescription(
            'while validating select entries for '
            '${widget.delegate.runtimeType}',
          ),
        ),
      );
      return widget.delegate.buildError(context, error, stackTrace);
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Column(
        // Shrink-wrap the panel to its content height: dialog and bottom
        // sheet hosts pass a loose bounded constraint (Flexible(fit: loose)),
        // and a default MainAxisSize.max column would stretch to that cap and
        // leave empty space below short content. The Flexible below still
        // caps the body at the incoming maxHeight, so tall content scrolls
        // internally and the action bar stays pinned to the bottom.
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.delegate.searchEnabled)
            SelectSearchBar(
              controller: _searchController,
              focusNode: _searchFocusNode,
              hintText: widget.delegate.searchHintText,
              onChanged: _onSearchChanged,
            ),
          Flexible(
            fit: FlexFit.loose,
            child: widget.delegate.buildBody(
              context,
              entries,
              _controller.selectedEntries,
              searchQuery: _searchQuery,
            ),
          ),
        ],
      ),
    );
  }
}

/// Wraps the panel content, applying the [SelectPanelTheme] elevation and
/// shape when configured.
///
/// When either [SelectPanelTheme.elevation] or [SelectPanelTheme.shape] is
/// set, the background is rendered as a [Material] so that it casts a shadow and
/// consumes the [ShapeBorder]. Otherwise, a plain [ColoredBox] is used, which
/// preserves the previous flat appearance and keeps hosts that supply their own
/// outer decoration (e.g. [Dialog] / [showModalBottomSheet]) free of a double
/// background.
class _PanelDecoratedBox extends StatelessWidget {
  const _PanelDecoratedBox({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = SelectTheme.of(context);
    final panel = theme.panelTheme;
    final hasDecoration = panel.elevation != null || panel.shape != null;
    if (!hasDecoration) {
      return ColoredBox(
        color: theme.backgroundColor,
        child: child,
      );
    }
    return Material(
      color: theme.backgroundColor,
      elevation: panel.elevation ?? 0,
      shadowColor: panel.shadowColor,
      surfaceTintColor: panel.surfaceTintColor,
      shape: panel.shape,
      clipBehavior: panel.clipBehavior ?? Clip.none,
      child: child,
    );
  }
}
