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
/// The panel loads [SelectDelegate.data] and displays the select body once the data
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
    // Merge the delegate-level [SelectPanelTheme] override (if any) into the
    // ambient theme so that [_PanelDecoratedBox] picks it up. `copyWith` keeps
    // the existing `panelTheme` when the delegate does not supply one.
    final baseTheme =
        widget.selectTheme ?? SelectThemeData.fallback(Theme.of(context));
    final effectiveTheme = widget.delegate.panelTheme == null
        ? baseTheme
        : baseTheme.copyWith(panelTheme: widget.delegate.panelTheme);
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
        children: [
          if (widget.delegate.searchEnabled)
            SelectSearchBar(
              controller: _searchController,
              focusNode: _searchFocusNode,
              hintText: widget.delegate.searchHintText,
              onChanged: _onSearchChanged,
              theme: widget.delegate.searchBarTheme,
            ),
          Expanded(
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
