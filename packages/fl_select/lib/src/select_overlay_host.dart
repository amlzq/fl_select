import 'package:flutter/material.dart';

import 'popup_select_controller.dart';
import 'select/select_panel.dart';
import 'select/select_theme_data.dart';
import 'select_overlay.dart';
import 'select_overlay_style.dart';

/// Shared host that wires a trigger widget (a [PopupSelectBar] or a
/// [PopupSelectButton]) to its select overlay.
///
/// This widget owns the boilerplate that used to be duplicated verbatim in both
/// triggers:
/// - [PopupSelectControllerProvider] to expose the [controller] to
/// descendants (e.g. [SelectPanel]).
/// - [CompositedTransformTarget] + [OverlayPortal] + [CompositedTransformFollower]
///   to anchor the overlay to the trigger's actual painted position, which is
///   robust to scrolling and ancestor transforms ([SelectOverlay] relies on
///   this follower to make the Stack origin equal the screen's top-left).
/// - [SelectOverlay] to position, animate, and clip the [SelectPanel].
///
/// The trigger only supplies its own UI ([triggerChild]) plus the already
/// resolved [style], [selectTheme], and [direction], and optionally whether the
/// panel should keep at least the trigger's width ([minWidthFromTrigger]).
///
/// Trigger geometry is measured in a post-frame callback and cached — never
/// during [State.build]. Reading render geometry in the build phase crashes
/// when an ancestor render object (e.g. a freshly inflated route-transition
/// wrapper such as an aligned Transform) has not been laid out yet in the
/// current frame.
///
/// This widget is package-internal (kept in `lib/src/` and not re-exported from
/// the public API barrel).
class SelectOverlayHost extends StatefulWidget {
  const SelectOverlayHost({
    super.key,
    required this.controller,
    required this.direction,
    required this.style,
    required this.selectTheme,
    required this.triggerChild,
    this.minWidthFromTrigger = false,
  });

  final PopupSelectController controller;
  final PopupSelectDirection direction;
  final SelectOverlayStyle? style;
  final SelectThemeData? selectTheme;

  /// When true, the overlay panel's [SelectOverlayStyle.minWidth] defaults to
  /// the trigger's width ([PopupSelectButton]). When false, any explicit
  /// [style.minWidth] is used as-is ([PopupSelectBar]).
  final bool minWidthFromTrigger;

  /// The trigger UI (the bar or the button) that toggles the overlay.
  final Widget triggerChild;

  @override
  State<SelectOverlayHost> createState() => _SelectOverlayHostState();
}

class _SelectOverlayHostState extends State<SelectOverlayHost> {
  /// Trigger rect expressed in the coordinate system of the overlay the
  /// portal is inserted into, used by [SelectOverlay] to position the panel
  /// relative to the trigger and keep it on screen.
  Rect _targetRect = Rect.zero;

  /// Trigger size, kept for [SelectOverlayHost.minWidthFromTrigger].
  Size _targetSize = Size.zero;

  bool _measureScheduled = false;

  /// Measures the trigger rect after layout completes and caches the result.
  ///
  /// Measuring relative to the overlay (rather than the global root) lets the
  /// overlay render correctly inside a scoped overlay — for example a phone
  /// preview that wraps the select in its own [Navigator]/[Overlay], possibly
  /// behind a [FittedBox] transform. When the scoped overlay cannot be
  /// resolved (i.e. the default root overlay) the result is identical to a
  /// root-global measurement.
  void _scheduleMeasure() {
    if (_measureScheduled) return;
    _measureScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureScheduled = false;
      if (!mounted) return;
      final renderObject = context.findRenderObject();
      if (renderObject is! RenderBox ||
          !renderObject.attached ||
          !renderObject.hasSize) {
        return;
      }
      final overlayBox =
          Overlay.maybeOf(context)?.context.findRenderObject() as RenderBox?;
      final Offset offset = overlayBox == null || !overlayBox.hasSize
          ? renderObject.localToGlobal(Offset.zero)
          : renderObject.localToGlobal(Offset.zero, ancestor: overlayBox);
      final rect = offset & renderObject.size;
      if (rect != _targetRect || renderObject.size != _targetSize) {
        setState(() {
          _targetRect = rect;
          _targetSize = renderObject.size;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Re-measure after this frame keeps the cached rect fresh; the
    // CompositedTransformFollower still anchors the panel in real time
    // between measurements.
    _scheduleMeasure();

    // Keep the panel at least as wide as the trigger when requested (button).
    // An explicit style.minWidth always wins; any style maxWidth still applies
    // as a hard cap. SelectOverlay translates the panel to stay on screen
    // rather than shrinking it.
    final resolvedStyle = widget.minWidthFromTrigger
        ? (widget.style ?? const SelectOverlayStyle()).copyWith(
            minWidth: widget.style?.minWidth ??
                (_targetSize.width > 0 ? _targetSize.width : null),
          )
        : widget.style;

    return PopupSelectControllerProvider(
      controller: widget.controller,
      child: CompositedTransformTarget(
        link: widget.controller.layerLink,
        child: OverlayPortal(
          controller: widget.controller.portalCtrl,
          overlayChildBuilder: (context) {
            return CompositedTransformFollower(
              link: widget.controller.layerLink,
              showWhenUnlinked: false,
              // Shift the follower origin from the trigger's top-left to the
              // screen's top-left. This ensures the Stack's hit-test bounds
              // (size = screenSize, origin = (0,0)) cover the entire screen,
              // so taps on panel areas that extend left of the trigger (when
              // the panel is clamped on screen) are not silently dropped.
              offset: Offset(-_targetRect.left, -_targetRect.top),
              child: SelectOverlay(
                targetRect: _targetRect,
                direction: widget.direction,
                style: resolvedStyle,
                animation: widget.controller.overlayAnimation,
                onOverlayTap: () => widget.controller.hideSelect(),
                child: SelectPanel(
                  controller: widget.controller.selectController,
                  delegate: widget.controller.previousSelectDelegate!,
                  selectTheme: widget.selectTheme,
                ),
              ),
            );
          },
          child: widget.triggerChild,
        ),
      ),
    );
  }
}
