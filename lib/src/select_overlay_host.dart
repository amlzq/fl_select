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
///   descendants (e.g. [SelectPanel]).
/// - [CompositedTransformTarget] + [OverlayPortal] + [CompositedTransformFollower]
///   to anchor the overlay to the trigger's actual painted position, which is
///   robust to scrolling and ancestor transforms ([SelectOverlay] relies on
///   this follower to make the Stack origin equal the screen's top-left).
/// - [SelectOverlay] to position, animate, and clip the [SelectPanel].
///
/// The trigger only supplies its own UI ([triggerChild]) plus the already
/// resolved [style], [selectTheme], and [direction], and optionally whether
/// the panel should keep at least the trigger's width ([minWidthFromTrigger]).
///
/// This widget is package-internal (kept in `lib/src/` and not re-exported from
/// the public API barrel).
class SelectOverlayHost extends StatelessWidget {
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

  /// Rect of this host (= the trigger) expressed in the coordinate system of
  /// the [overlay] it is inserted into, used by [SelectOverlay] to position
  /// the panel relative to the trigger and keep it on screen.
  ///
  /// Measuring relative to the overlay (rather than the global root) lets the
  /// overlay render correctly inside a scoped overlay — for example a phone
  /// preview that wraps the select in its own [Navigator]/[Overlay], possibly
  /// behind a [FittedBox] transform. When [overlay] is `null` (no scoped
  /// overlay, i.e. the default root overlay) the result is identical to the
  /// previous root-global measurement, so behavior is unchanged for normal use.
  Rect _targetRect(RenderBox? renderBox, RenderBox? overlayBox) {
    if (renderBox == null) return Rect.zero;
    final offset = overlayBox == null
        ? renderBox.localToGlobal(Offset.zero)
        : renderBox.localToGlobal(Offset.zero, ancestor: overlayBox);
    return Rect.fromLTWH(
      offset.dx,
      offset.dy,
      renderBox.size.width,
      renderBox.size.height,
    );
  }

  Size _targetSize(RenderBox? renderBox) => renderBox?.size ?? Size.zero;

  @override
  Widget build(BuildContext context) {
    final renderBox = context.findRenderObject() as RenderBox?;
    // Resolve the overlay the portal is inserted into so the trigger rect can
    // be measured relative to it (see [_targetRect]).
    final overlayBox =
        Overlay.maybeOf(context)?.context.findRenderObject() as RenderBox?;
    final targetRect = _targetRect(renderBox, overlayBox);

    // Keep the panel at least as wide as the trigger when requested (button).
    // An explicit style.minWidth always wins; any style maxWidth still applies
    // as a hard cap. SelectOverlay translates the panel to stay on screen
    // rather than shrinking it.
    final resolvedStyle = minWidthFromTrigger
        ? (style ?? const SelectOverlayStyle()).copyWith(
            minWidth: style?.minWidth ??
                (_targetSize(renderBox).width > 0
                    ? _targetSize(renderBox).width
                    : null),
          )
        : style;

    return PopupSelectControllerProvider(
      controller: controller,
      child: CompositedTransformTarget(
        link: controller.layerLink,
        child: OverlayPortal(
          controller: controller.portalCtrl,
          overlayChildBuilder: (context) {
            return CompositedTransformFollower(
              link: controller.layerLink,
              showWhenUnlinked: false,
              // Shift the follower origin from the trigger's top-left to the
              // screen's top-left. This ensures the Stack's hit-test bounds
              // (size = screenSize, origin = (0,0)) cover the entire screen,
              // so taps on panel areas that extend left of the trigger (when
              // the panel is clamped on screen) are not silently dropped.
              offset: Offset(-targetRect.left, -targetRect.top),
              child: SelectOverlay(
                targetRect: targetRect,
                direction: direction,
                style: resolvedStyle,
                animation: controller.overlayAnimation,
                onOverlayTap: () => controller.hideSelect(),
                child: SelectPanel(
                  controller: controller.selectController,
                  delegate: controller.previousSelectDelegate!,
                  selectTheme: selectTheme,
                ),
              ),
            );
          },
          child: triggerChild,
        ),
      ),
    );
  }
}
