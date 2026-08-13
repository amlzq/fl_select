import 'package:flutter/material.dart';

import 'select/select_controller.dart';
import 'select/select_delegate.dart';
import 'select/select_entry.dart';
import 'select/select_utils.dart';
import 'select_label_state.dart';

/// Tab label data for [PopupSelectBar].
///
/// Extends [SelectLabelState] (which carries the label / result state shared
/// with [PopupSelectButton]) by adding the tab identity ([index] / [tag]).
/// A standalone [PopupSelectButton] never creates a [PopupTabData]; it uses
/// [SelectLabelState] directly.
class PopupTabData extends SelectLabelState {
  /// Tab index in the [PopupSelectBar].
  final int index;

  /// Optional tag for identifying the tab.
  final String? tag;

  PopupTabData({
    required this.index,
    super.originalLabel,
    this.tag,
    super.labelLoader,
  });

  @override
  String toString() =>
      'PopupTabData(index: $index, originalLabel: $originalLabel)';
}

/// Tab-agnostic change callback used internally by [PopupSelectController].
///
/// Suitable for [PopupSelectButton], which has no tab concept, as well as
/// multi-tab [PopupSelectBar].
typedef PopupSelectLabelChangeCallback = void Function(
    SelectLabelState labelState, SelectEntries selected);

/// Controller for [PopupSelectBar] and its select overlay.
///
/// This controller stores per-tab label data ([PopupTabData]) and manages
/// the overlay visibility. It forwards selection events to listeners
/// registered via [addChangeListener], [addApplyListener], and
/// [addResetListener].
class PopupSelectController extends ChangeNotifier {
  static const Duration _kOverlayAnimationDuration =
      Duration(milliseconds: 240);

  final List<PopupSelectLabelChangeCallback> _changeListeners = [];
  final List<PopupSelectLabelChangeCallback> _applyListeners = [];
  final List<VoidCallback> _resetListeners = [];

  /// Registers a listener to be called when a select reports a selection
  /// change.
  ///
  /// Returns a [VoidCallback] that unregisters the listener when called.
  VoidCallback addChangeListener(PopupSelectLabelChangeCallback listener) {
    _changeListeners.add(listener);
    return () => removeChangeListener(listener);
  }

  /// Unregisters a previously registered change listener.
  void removeChangeListener(PopupSelectLabelChangeCallback listener) {
    _changeListeners.remove(listener);
  }

  /// Registers a listener to be called when a select is applied.
  ///
  /// Returns a [VoidCallback] that unregisters the listener when called.
  VoidCallback addApplyListener(PopupSelectLabelChangeCallback listener) {
    _applyListeners.add(listener);
    return () => removeApplyListener(listener);
  }

  /// Unregisters a previously registered apply listener.
  void removeApplyListener(PopupSelectLabelChangeCallback listener) {
    _applyListeners.remove(listener);
  }

  /// Registers a listener to be called when reset is triggered.
  ///
  /// Returns a [VoidCallback] that unregisters the listener when called.
  VoidCallback addResetListener(VoidCallback listener) {
    _resetListeners.add(listener);
    return () => removeResetListener(listener);
  }

  /// Unregisters a previously registered reset listener.
  void removeResetListener(VoidCallback listener) {
    _resetListeners.remove(listener);
  }

  /// Per-tab label and result data keyed by tab index.
  ///
  /// For [PopupSelectBar] these are [PopupTabData] (tab identity + label
  /// state); for a standalone [PopupSelectButton] the lone trigger is a
  /// plain [SelectLabelState] stored at index `0`.
  final Map<int, SelectLabelState> labelStateMap = {};
  bool _isDisposed = false;

  /// Returns the nearest controller provided by [PopupSelectControllerProvider]
  /// or null if none is found.
  static PopupSelectController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_PopupSelectControllerScope>()
        ?.controller;
  }

  /// Returns the nearest controller provided by [PopupSelectControllerProvider].
  static PopupSelectController of(BuildContext context) {
    final PopupSelectController? controller = maybeOf(context);
    assert(() {
      if (controller == null) {
        throw FlutterError(
          'PopupSelectController.of() was called with a context that does not '
          'contain a PopupSelectControllerProvider widget.\n'
          'The context used was:\n'
          '  $context',
        );
      }
      return true;
    }());
    return controller!;
  }

  final portalCtrl = OverlayPortalController();
  final layerLink = LayerLink();

  TickerProvider? _tickerProvider;
  AnimationController? _overlayAnimCtrl;
  Animation<double>? _overlayAnimation;
  bool _isExpanded = false;

  // OverlayEntry? _entry;

  // BuildContext? get barContext => _barContext;
  // BuildContext? _barContext;

  // void attachBarContext(BuildContext context) {
  //   _barContext = context;
  // }

  // void detachBarContext() {
  //   _barContext = null;
  // }

  /// Currently selected tab index.
  int? currentIndex;

  /// Returns the current tab data for [currentIndex].
  PopupTabData get currentTabData =>
      labelStateMap[currentIndex]! as PopupTabData;

  SelectDelegate? _previousSelectDelegate;

  /// The select previously used for the overlay.
  // ignore: unnecessary_getters_setters
  SelectDelegate? get previousSelectDelegate => _previousSelectDelegate;
  set previousSelectDelegate(SelectDelegate? value) =>
      _previousSelectDelegate = value;

  /// The [SelectController] for the currently active select panel, if any.
  ///
  /// Created when a select is shown (see [_showSelect]) and disposed when
  /// the overlay is hidden. Exposed so that [PopupSelectBar] can pass it to
  /// [SelectPanel] via its `controller` parameter.
  SelectController? get selectController => _selectController;
  SelectController? _selectController;

  /// Localized "Multiple" text used when building apply result labels.
  ///
  /// Injected by [PopupSelectBar] from the active localizations before the
  /// overlay is shown.
  String? applyMultipleText;

  List<SelectDelegate>? _selectDelegates;

  /// Attaches the list of [SelectDelegate] configurations to this controller.
  ///
  /// If the select overlay is currently open, it is refreshed so that live
  /// changes to the delegate (selection mode, tile variant, layout, spacing,
  /// etc.) are reflected immediately in the open panel. The open animation is
  /// not replayed — only the panel content is rebuilt against a fresh
  /// [SelectController] bound to the new delegate. The surrounding rebuild
  /// (driven by the bar/button widget's own `didUpdateWidget`) already re-runs
  /// the overlay entry builder, which reads [previousSelectDelegate] and
  /// [selectController], so no extra notify is required here.
  ///
  /// Stable apps that reuse the same delegate instances are unaffected: when
  /// the new delegate is identical (`==`) to the one already shown, nothing
  /// is rebuilt.
  void attachSelectDelegates(List<SelectDelegate> selectDelegates) {
    if (_isDisposed) return;
    _selectDelegates = selectDelegates;

    if (_isExpanded && currentIndex != null) {
      final newDelegate = _selectDelegateAt(currentIndex!);
      if (newDelegate != null && newDelegate != previousSelectDelegate) {
        previousSelectDelegate = newDelegate;
        _createSelectController();
      }
    }
  }

  SelectDelegate? _selectDelegateAt(int tabIndex) {
    final selectDelegates = _selectDelegates;
    if (selectDelegates == null) return null;
    if (tabIndex < 0 || tabIndex >= selectDelegates.length) return null;
    return selectDelegates[tabIndex];
  }

  Animation<double> get overlayAnimation =>
      _overlayAnimation ?? AlwaysStoppedAnimation(_isExpanded ? 1.0 : 0.0);

  void attachTickerProvider(TickerProvider tickerProvider) {
    if (_isDisposed) return;
    if (identical(_tickerProvider, tickerProvider) &&
        _overlayAnimCtrl != null) {
      return;
    }

    if (_tickerProvider != null &&
        !identical(_tickerProvider, tickerProvider)) {
      detachTickerProvider();
    }

    _tickerProvider = tickerProvider;
    _ensureOverlayAnimationController();
    final animCtrl = _overlayAnimCtrl;
    if (animCtrl == null) return;
    animCtrl.value = _isExpanded ? 1.0 : 0.0;
  }

  void detachTickerProvider() {
    _tickerProvider = null;
    _overlayAnimation = null;
    final animCtrl = _overlayAnimCtrl;
    _overlayAnimCtrl = null;
    animCtrl?.dispose();
  }

  void _ensureOverlayAnimationController() {
    final tickerProvider = _tickerProvider;
    if (tickerProvider == null) return;

    final existingCtrl = _overlayAnimCtrl;
    if (existingCtrl != null) {
      return;
    }

    final animCtrl = AnimationController(
      vsync: tickerProvider,
      duration: _kOverlayAnimationDuration,
    );
    _overlayAnimCtrl = animCtrl;
    _overlayAnimation = CurvedAnimation(
      parent: animCtrl,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void dispose() {
    hideSelect(immediate: true);
    _isDisposed = true;
    detachTickerProvider();
    labelStateMap.clear();
    _changeListeners.clear();
    _applyListeners.clear();
    _resetListeners.clear();
    // removeOverlay();
    super.dispose();
  }

  void _safePortalHide() {
    try {
      portalCtrl.hide();
    } catch (_) {}
  }

  @override
  void notifyListeners() {
    if (_isDisposed) return;
    super.notifyListeners();
  }

  /// Shows or hides the select overlay.
  ///
  /// If [index] differs from [currentIndex], the overlay is shown and
  /// [currentIndex] is updated.
  void toggleSelect({int? index}) {
    if (_isDisposed) return;
    if (currentIndex != index || !_isExpanded) {
      _showSelect(index);
      return;
    }
    hideSelect();
  }

  /// @nodoc
  @Deprecated(
      'Use toggleSelect instead. This will be removed in a future minor version.')
  void toggleSelector({int? index}) => toggleSelect(index: index);

  /// Whether the select overlay is currently showing.
  bool get isSelectShowing => _isExpanded;

  /// @nodoc
  @Deprecated(
      'Use isSelectShowing instead. This will be removed in a future minor version.')
  bool get isSelectorShowing => isSelectShowing;

  /// Hides the select overlay if it is showing.
  void hideSelect({bool immediate = false}) {
    if (_isDisposed) {
      if (immediate) {
        _overlayAnimCtrl?.value = 0.0;
        _safePortalHide();
        _disposeSelectController();
      }
      return;
    }

    if (!_isExpanded && !portalCtrl.isShowing) {
      _disposeSelectController();
      return;
    }

    _isExpanded = false;
    notifyListeners();

    if (immediate) {
      _overlayAnimCtrl?.value = 0.0;
      _safePortalHide();
      _disposeSelectController();
      notifyListeners();
      return;
    }

    final animCtrl = _overlayAnimCtrl;
    if (animCtrl == null) {
      _safePortalHide();
      _disposeSelectController();
      notifyListeners();
      return;
    }

    if (!portalCtrl.isShowing) {
      animCtrl.value = 0.0;
      _disposeSelectController();
      return;
    }

    animCtrl.reverse(from: animCtrl.value).whenComplete(() {
      if (_isDisposed) return;
      if (portalCtrl.isShowing) {
        _safePortalHide();
      }
      _disposeSelectController();
      notifyListeners();
    });
  }

  /// @nodoc
  @Deprecated(
      'Use hideSelect instead. This will be removed in a future minor version.')
  void hideSelector({bool immediate = false}) =>
      hideSelect(immediate: immediate);

  void _showSelect(int? index) {
    if (_isDisposed) return;
    if (index == null) return;

    final newDelegate = _selectDelegateAt(index);
    if (newDelegate == null) return;

    final wasShowing = portalCtrl.isShowing;

    currentIndex = index;
    _isExpanded = true;
    // Bind the panel content to the *target* tab's delegate. Without this,
    // switching from an already-open panel to a different index would rebuild
    // the controller against the previously shown delegate, rendering the old
    // tab's content under the new index.
    previousSelectDelegate = newDelegate;

    // Create (or refresh) the SelectController for this select session.
    _createSelectController();

    _ensureOverlayAnimationController();
    final animCtrl = _overlayAnimCtrl;

    if (!wasShowing) {
      portalCtrl.show();
      animCtrl?.forward(from: 0.0);
      notifyListeners();
      return;
    }

    // Already showing: switch the panel in place without replaying the enter
    // animation, so jumping between tabs doesn't flash or collapse the overlay.
    animCtrl?.value = 1.0;
    notifyListeners();
  }

  /// Creates a [SelectController] bound to [previousSelectDelegate] and wires the
  /// change/apply/reset listeners to this controller's handlers.
  ///
  /// Any previously created controller is disposed first.
  void _createSelectController() {
    _disposeSelectController();
    final select = previousSelectDelegate;
    if (select == null) return;
    final ctrl = SelectController(
      selectionMode: select.selectionMode,
      previousSelected: select.selectedEntries,
      resetSelected: select.resetEntries,
    );
    ctrl.addChangeListener(handleChange);
    ctrl.addApplyListener(
        (selected) => handleApply(selected, applyMultipleText ?? 'Multiple'));
    ctrl.addResetListener(handleReset);
    _selectController = ctrl;
  }

  /// Disposes the current [SelectController], if any.
  void _disposeSelectController() {
    final ctrl = _selectController;
    _selectController = null;
    ctrl?.dispose();
  }

  /// Dispatches a selection change event.
  void handleChange(SelectEntries selected) {
    if (_isDisposed) return;
    final labelState = labelStateMap[currentIndex];
    if (labelState == null) return;
    for (final listener in List.of(_changeListeners)) {
      listener(labelState, selected);
    }
  }

  /// Dispatches an apply event and updates the tab result label.
  void handleApply(SelectEntries selected, String multipleText) {
    if (_isDisposed) return;
    final labelState = labelStateMap[currentIndex];
    if (labelState == null) return;
    hideSelect();
    // Persist the applied selection back onto the delegate so that reopening
    // the select (PopupSelectBar / PopupSelectButton / showSelect
    // / showModalBottomSelect) reconstructs its SelectController with
    // `previousSelected = selected`. Without this write-back, `selectedData`
    // keeps the initial `selectedEntriesLoader` value and the previous selection
    // is lost on reopen — even though `selectedEntriesLoader` was supplied.
    previousSelectDelegate?.selectedEntries = selected;
    for (final listener in List.of(_applyListeners)) {
      listener(labelState, selected);
    }
    final customLabel = labelState.resolvedLabelLoader?.call(selected);
    labelState.resultLabel =
        customLabel ?? SelectUtils.getResultLabel(selected, multipleText);
    notifyListeners();
  }

  /// Programmatically applies selection ids to the tab at [tabIndex].
  ///
  /// This method does not open the select panel. Instead, it resolves
  /// [selectedEntryIds] against the select data, fires apply listeners,
  /// updates the tab label, and notifies listeners.
  ///
  /// Matching rules:
  /// - Matching is performed by entry id only.
  /// - If the same id appears in multiple branches, all matching entries are
  ///   included in the applied result.
  /// - Header and footer entries are supported.
  /// - Custom range entries are not supported.
  /// - Category ids are not allowed in [selectedEntryIds].
  ///
  /// Return value:
  /// - Returns `true` when the apply flow completes successfully, including the
  ///   case where no entry ids match and the result is treated as cleared/empty.
  /// - Returns `false` when the input is invalid or the select data cannot be
  ///   prepared, such as:
  ///   - [tabIndex] does not resolve to a tab/select
  ///   - a category id is present in [selectedEntryIds]
  ///   - a custom range id is present in [selectedEntryIds]
  ///   - select data cannot be loaded
  Future<bool> apply({
    required int tabIndex,
    required Set<String> selectedEntryIds,
    String multipleText = 'Multiple',
  }) async {
    if (_isDisposed) return false;
    final labelState = labelStateMap[tabIndex];
    if (labelState is! PopupTabData) return false;
    final tabData = labelState;

    final select = _selectDelegateAt(tabIndex);
    if (select == null) return false;

    final entriesFuture = select.asyncEntries;
    if (entriesFuture == null) return false;

    late final SelectEntries entries;
    try {
      entries = await entriesFuture;
    } catch (_) {
      return false;
    }

    final ctx = _PopupSelectApplyContext(selectedEntryIds);
    final selected = _buildAppliedSelection(entries.toList(), ctx);
    if (ctx.invalidCategoryHit) return false;
    if (ctx.invalidCustomHit) return false;

    for (final listener in List.of(_applyListeners)) {
      listener(tabData, selected);
    }
    final customLabel = tabData.resolvedLabelLoader?.call(selected);
    tabData.resultLabel =
        customLabel ?? SelectUtils.getResultLabel(selected, multipleText);
    notifyListeners();
    return true;
  }

  Future<bool> select(int tabIndex, Set<String> selectedEntryIds) async {
    if (_isDisposed) return false;
    if (labelStateMap[tabIndex] is! PopupTabData) return false;

    final select = _selectDelegateAt(tabIndex);
    if (select == null) return false;

    previousSelectDelegate = select;

    final entriesFuture = select.asyncEntries;
    if (entriesFuture == null) return false;

    select.resetEntries;

    late final SelectEntries entries;
    try {
      entries = await entriesFuture;
    } catch (_) {
      return false;
    }

    final ctx = _PopupSelectApplyContext(selectedEntryIds);
    final selected = _buildAppliedSelection(entries.toList(), ctx);
    if (ctx.invalidCategoryHit) return false;
    if (ctx.invalidCustomHit) return false;

    select.selectedEntries = selected;
    _showSelect(tabIndex);
    handleChange(selected);
    return true;
  }

  static SelectEntries _buildAppliedSelection(
    List<SelectEntry> roots,
    _PopupSelectApplyContext ctx,
  ) {
    final SelectEntries result = {};
    for (final root in roots) {
      final cropped = _cropEntry(root, ctx);
      if (ctx.invalidCategoryHit || ctx.invalidCustomHit) return {};
      if (cropped != null) result.add(cropped);
    }
    return result;
  }

  static SelectEntry? _cropEntry(
    SelectEntry entry,
    _PopupSelectApplyContext ctx,
  ) {
    if (entry is SelectCategoryEntry) {
      if (ctx.selectedEntryIds.contains(entry.id)) {
        ctx.invalidCategoryHit = true;
        return null;
      }

      final Set<SelectEntry> croppedChildren = {};
      final children = entry.children;
      if (children != null) {
        for (final child in children) {
          final cropped = _cropEntry(child, ctx);
          if (ctx.invalidCategoryHit || ctx.invalidCustomHit) return null;
          if (cropped != null) croppedChildren.add(cropped);
        }
      }

      final header =
          entry.header == null ? null : _cropEntry(entry.header!, ctx);
      if (ctx.invalidCategoryHit || ctx.invalidCustomHit) return null;

      final footer =
          entry.footer == null ? null : _cropEntry(entry.footer!, ctx);
      if (ctx.invalidCategoryHit || ctx.invalidCustomHit) return null;

      if (croppedChildren.isEmpty && header == null && footer == null) {
        return null;
      }

      return SelectCategoryEntry(
        selectionMode: entry.selectionMode,
        header: header,
        headerSelectionMode: entry.headerSelectionMode,
        footer: footer,
        footerSelectionMode: entry.footerSelectionMode,
        layout: entry.layout,
        id: entry.id,
        name: entry.name ?? '',
        children: croppedChildren,
        enabled: entry.enabled,
        immediate: entry.immediate,
      );
    }

    final bool isHit = ctx.selectedEntryIds.contains(entry.id);
    if (isHit) {
      if (entry is SelectRangeEntry && entry.id == kCustomEntryId) {
        ctx.invalidCustomHit = true;
        return null;
      }
      ctx.matchedCount++;
    }

    final Set<SelectEntry> croppedChildren = {};
    final children = entry.children;
    if (children != null) {
      for (final child in children) {
        final cropped = _cropEntry(child, ctx);
        if (ctx.invalidCategoryHit || ctx.invalidCustomHit) return null;
        if (cropped != null) croppedChildren.add(cropped);
      }
    }

    if (!isHit && croppedChildren.isEmpty) return null;

    return _cloneEntry(entry,
        children: croppedChildren.isEmpty ? null : croppedChildren);
  }

  static SelectEntry _cloneEntry(
    SelectEntry entry, {
    required Set<SelectEntry>? children,
  }) {
    if (entry is SelectTextEntry) {
      return SelectTextEntry(
        parentId: entry.parentId,
        id: entry.id,
        name: entry.name,
        children: children,
        enabled: entry.enabled,
        immediate: entry.immediate,
      );
    }

    if (entry is SelectRangeEntry) {
      return SelectRangeEntry(
        min: entry.min,
        max: entry.max,
        inputLabel: entry.inputLabel,
        minHintText: entry.minHintText,
        maxHintText: entry.maxHintText,
        parentId: entry.parentId,
        id: entry.id,
        name: entry.name,
        children: children,
        enabled: entry.enabled,
        immediate: entry.immediate,
        extra: entry.extra,
      );
    }

    if (entry is SelectChildEntry) {
      return SelectChildEntry(
        parentId: entry.parentId,
        id: entry.id,
        name: entry.name,
        children: children,
        enabled: entry.enabled,
        immediate: entry.immediate,
        extra: entry.extra,
      );
    }

    throw UnsupportedError(
        'Unsupported SelectEntry type: ${entry.runtimeType}');
  }

  /// Dispatches a reset event.
  void handleReset() {
    if (_isDisposed) return;
    for (final listener in List.of(_resetListeners)) {
      listener();
    }
  }
}

class _PopupSelectApplyContext {
  final Set<String> selectedEntryIds;
  bool invalidCategoryHit = false;
  bool invalidCustomHit = false;
  int matchedCount = 0;

  _PopupSelectApplyContext(this.selectedEntryIds);
}

class _PopupSelectControllerScope extends InheritedWidget {
  final PopupSelectController? controller;

  const _PopupSelectControllerScope({
    this.controller,
    required super.child,
  });

  @override
  bool updateShouldNotify(covariant _PopupSelectControllerScope oldWidget) {
    return controller != oldWidget.controller;
  }
}

/// Provides a [PopupSelectController] to descendants.
class PopupSelectControllerProvider extends StatelessWidget {
  final PopupSelectController? controller;
  final Widget child;

  const PopupSelectControllerProvider({
    super.key,
    this.controller,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return _PopupSelectControllerScope(controller: controller, child: child);
  }
}
