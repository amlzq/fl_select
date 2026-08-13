import 'package:flutter/material.dart';

import 'select/action_bar_visibility.dart';
import 'select/constants.dart';
import 'select/select_controller.dart';
import 'select/select_delegate.dart';
import 'select/select_panel.dart';

/// A high-level, ready-to-use select.
///
/// [SelectView] is the public entry point for embedding a select
/// directly in a page or dialog body. It wraps [SelectPanel] — now an
/// internal implementation detail that is no longer exported — and takes care
/// of the controller lifecycle so callers get a complete, styled component
/// without extra wiring.
///
/// Inline selects do not show the apply/reset action bar: [SelectView]
/// wraps its panel in a [SelectActionBarVisibility] scope that hides it, so
/// selections apply immediately through [onChanged]. The action bar is still
/// shown by the modal hosts ([showSelect] / [showModalBottomSelect]), which
/// do not provide that scope. The [delegate]'s
/// [SelectDelegate.actionBarBuilder] only customizes the bar's UI and has no
/// effect inside a [SelectView].
///
/// Styling is carried entirely by the [delegate] (colors, per-widget themes
/// and the panel decoration via [SelectDelegate.panelTheme]). When a select
/// is the only one in its host, a separate `selectTheme` parameter is
/// unnecessary.
///
/// If [controller] is omitted, [SelectView] creates and owns an internal
/// [SelectController]; otherwise the caller-provided controller is used and
/// remains owned by the caller.
///
/// In addition to select-specific options, [SelectView] accepts the same
/// sizing and decorating parameters as [Container] — [width], [height],
/// [constraints], [padding], [margin] and [decoration]. These surround the
/// [SelectPanel] exactly as [Container] surrounds its child: the panel is
/// inset by [padding] (inflated by any border in the [decoration]), the
/// [decoration] is painted to fill the padded extent, then [constraints]
/// (combining [width]/[height]) are applied, and finally the [margin]
/// surrounds everything. The [maxHeightFactor] still caps the height in
/// unbounded contexts; a smaller bound from [width]/[height]/[constraints]
/// always wins.
class SelectView extends StatefulWidget {
  /// Creates a select box.
  ///
  /// The [width] and [height] values include the [padding] (but not the
  /// [margin]), mirroring [Container].
  SelectView({
    super.key,
    required this.delegate,
    this.controller,
    this.maxHeightFactor = 0.5,
    this.padding,
    this.decoration,
    double? width,
    double? height,
    BoxConstraints? constraints,
    this.margin,
    required this.onChanged,
  })  : assert(maxHeightFactor > 0 && maxHeightFactor <= 1),
        assert(margin == null || margin.isNonNegative),
        assert(padding == null || padding.isNonNegative),
        assert(decoration == null || decoration.debugAssertIsValid()),
        assert(constraints == null || constraints.debugAssertIsValid()),
        constraints = (width != null || height != null)
            ? constraints?.tighten(width: width, height: height) ??
                BoxConstraints.tightFor(width: width, height: height)
            : constraints;

  /// Configuration describing how entries are loaded and how the select body
  /// is rendered. Determines the concrete select type (Cascading, List, Grid
  /// or Flatten). Also carries all theme overrides (colors, per-widget themes
  /// and the panel decoration via [SelectDelegate.panelTheme]).
  final SelectDelegate delegate;

  /// Optional controller that drives the selection state.
  ///
  /// When provided, callers can drive the selection programmatically (for
  /// example with [SelectController.select]); the caller still owns it and is
  /// responsible for disposing it. When omitted, an internal controller is
  /// created and disposed by [SelectView].
  final SelectController? controller;

  /// Fired when the selection changes.
  final SelectCallback onChanged;

  /// Caps the select's height to this fraction of the screen height when it
  /// is embedded in an unbounded context (e.g. a [Column] with
  /// `mainAxisSize: min`).
  ///
  /// The cascading select lays out its body/skeleton with a `Column(min)` +
  /// `Expanded`, which requires a bounded height. This constraint only limits
  /// growth: a smaller bound from an ancestor (such as a [SizedBox] or
  /// [Expanded]) still wins via `min(parent, factor * screenHeight)`. Content
  /// shorter than the cap still shrinks to fit.
  ///
  /// When [width], [height] or [constraints] are provided, they are combined
  /// with this cap (a tighter bound still wins); see [constraints].
  ///
  /// It has no effect on the modal [showSelect] / [showModalBottomSelect],
  /// which use [SelectPanel] directly with their own height constraints.
  final double maxHeightFactor;

  /// Empty space to inscribe inside the [decoration]. The [SelectPanel] is
  /// placed inside this padding.
  ///
  /// This padding is in addition to any padding inherent in the [decoration]
  /// (e.g. borders in a [BoxDecoration]); see [Decoration.padding].
  final EdgeInsetsGeometry? padding;

  /// Empty space to surround the [decoration] and the select content.
  final EdgeInsetsGeometry? margin;

  /// The decoration to paint behind the select content.
  ///
  /// Commonly a [BoxDecoration]. The [SelectPanel] is not clipped to the
  /// decoration; to clip it to a particular shape, consider wrapping the box
  /// in a [ClipPath].
  final Decoration? decoration;

  /// Additional constraints to apply to the select content.
  ///
  /// The constructor [width] and [height] arguments are combined with this
  /// [constraints] argument to set the effective constraints, exactly as in
  /// [Container]. The [padding] goes inside the constraints.
  ///
  /// When this is null and no [width]/[height] is given, the
  /// [maxHeightFactor] caps the height in unbounded contexts. When provided, a
  /// smaller bound wins and a tighter [width]/[height] takes precedence, while
  /// [maxHeightFactor] still applies as an upper cap.
  final BoxConstraints? constraints;

  /// The padding including any padding inherent in the [decoration].
  EdgeInsetsGeometry? get _paddingIncludingDecoration {
    return switch ((padding, decoration?.padding)) {
      (null, final EdgeInsetsGeometry? padding) => padding,
      (final EdgeInsetsGeometry? padding, null) => padding,
      (_) => padding!.add(decoration!.padding),
    };
  }

  @override
  State<SelectView> createState() => _SelectViewState();
}

class _SelectViewState extends State<SelectView> {
  SelectController? _internalController;

  SelectController get _controller => widget.controller ?? _internalController!;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _createInternalController();
    }
  }

  void _createInternalController() {
    _internalController = SelectController(
      selectionMode: widget.delegate.selectionMode,
      previousSelected: widget.delegate.selectedEntries,
      resetSelected: widget.delegate.resetEntries,
    );
  }

  @override
  void didUpdateWidget(covariant SelectView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      if (oldWidget.controller == null) {
        _internalController?.dispose();
        _internalController = null;
      }
      if (widget.controller == null) {
        _createInternalController();
      }
    }
  }

  @override
  void dispose() {
    _internalController?.dispose();
    _internalController = null;
    super.dispose();
  }

  /// Combines [SelectView.constraints] (already merged with
  /// [SelectView.width]/[height] by the constructor) with the
  /// [SelectView.maxHeightFactor] cap. A smaller bound always wins, and
  /// unbounded contexts are still protected when no explicit size is given.
  BoxConstraints _effectiveConstraints(BuildContext context) {
    final BoxConstraints? sizeConstraints = widget.constraints;
    final double maxHeight =
        widget.maxHeightFactor * MediaQuery.of(context).size.height;
    final BoxConstraints heightCap = BoxConstraints(maxHeight: maxHeight);
    if (sizeConstraints != null) {
      // Enforce clamps the cap's values into the user's range, so a tighter
      // user bound wins while the cap still applies when the user leaves a
      // dimension open.
      return heightCap.enforce(sizeConstraints);
    }
    return heightCap;
  }

  @override
  Widget build(BuildContext context) {
    // The controller is owned here, but the selection body (and the
    // delegate-owned action bar) is rendered by the internal SelectPanel,
    // which is kept as the building block used by dialogs and bottom sheets.
    //
    // Layout mirrors [Container]: the [SelectPanel] is surrounded by
    // [padding] (inflated by any border in the [decoration]), then the
    // [decoration] is painted, then constraints are applied (combining
    // [width]/[height]/[constraints] with the [maxHeightFactor] cap), and
    // finally the [margin] surrounds everything. The cascading select lays
    // out its body/skeleton with a Column(min) + Expanded, which requires a
    // bounded height; the constraints guarantee that.
    Widget current = SelectActionBarVisibility(
      hidden: true,
      child: SelectPanel(
        delegate: widget.delegate,
        controller: _controller,
        onChangeTap: widget.onChanged,
        onApplyTap: widget.onChanged,
      ),
    );

    final EdgeInsetsGeometry? effectivePadding =
        widget._paddingIncludingDecoration;
    if (effectivePadding != null) {
      current = Padding(padding: effectivePadding, child: current);
    }

    if (widget.decoration != null) {
      current = DecoratedBox(decoration: widget.decoration!, child: current);
    }

    current = ConstrainedBox(
      constraints: _effectiveConstraints(context),
      child: current,
    );

    if (widget.margin != null) {
      current = Padding(padding: widget.margin!, child: current);
    }

    return current;
  }
}
