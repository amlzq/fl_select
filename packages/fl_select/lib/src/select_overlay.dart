import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'select_overlay_style.dart';

const kSelectOverlayMaxHeightFactor = 0.7;

/// Minimum inset kept between the overlay panel and the screen edges.
const kSelectOverlayScreenMargin = 0.0;

/// Vertical placement strategy for the select overlay relative to its trigger
/// (a [PopupSelectButton] or [PopupSelectBar]).
enum PopupSelectDirection {
  /// Always present the panel below the trigger.
  below,

  /// Always present the panel above the trigger.
  above,

  /// Decide automatically: prefer below, but flip above when there is more
  /// room there. The panel is always clamped horizontally so it stays on
  /// screen (mirroring the behavior of [PopupMenuButton]).
  adaptive,
}

/// Overlay container that hosts an arbitrary [child] widget (typically a
/// [SelectPanel]).
///
/// This widget is responsible for the overlay backdrop, expand/collapse
/// animation, max-height constraint, and on-screen positioning. Given the
/// global [targetRect] of the trigger and a [direction], it keeps the panel
/// fully visible by translating it (never scaling it) within the screen, and
/// flips above the trigger when [PopupSelectDirection.adaptive] is used
/// and space below is tight. Compared to the previous "shrink to fit the
/// available side" approach, the panel now keeps its intrinsic size, exactly
/// like [PopupMenuButton].
class SelectOverlay extends StatelessWidget {
  const SelectOverlay({
    super.key,
    required this.child,
    this.style,
    this.animation,
    this.onOverlayTap,
    this.targetRect,
    this.direction = PopupSelectDirection.adaptive,
    this.screenMargin = kSelectOverlayScreenMargin,
  });

  /// The content displayed inside the overlay.
  final Widget child;

  final SelectOverlayStyle? style;

  final Animation<double>? animation;

  final GestureTapCallback? onOverlayTap;

  /// Global rect of the trigger (button or bar), used to position the panel
  /// relative to the trigger and to keep it within the screen. When null, the
  /// panel is centered horizontally near the top of the screen.
  final Rect? targetRect;

  /// Vertical placement strategy. Defaults to [PopupSelectDirection.adaptive].
  final PopupSelectDirection direction;

  /// Minimum inset between the panel and the screen edges.
  final double screenMargin;

  static bool _resolveGrowUp(
    Rect? targetRect,
    Size screenSize,
    PopupSelectDirection direction,
  ) {
    final rect = targetRect;
    if (rect == null) return false;
    final belowSpace = screenSize.height - rect.bottom;
    final aboveSpace = rect.top;
    switch (direction) {
      case PopupSelectDirection.below:
        return false;
      case PopupSelectDirection.above:
        return true;
      case PopupSelectDirection.adaptive:
        return belowSpace < aboveSpace;
    }
  }

  static double _resolveAvailableHeight(
    Rect? targetRect,
    Size screenSize,
    bool growUp,
  ) {
    final rect = targetRect;
    if (rect == null) return screenSize.height;
    return growUp ? rect.top : (screenSize.height - rect.bottom);
  }

  @override
  Widget build(BuildContext context) {
    final SelectOverlayStyle defaults = _SelectOverlayDefaults(context);

    final maxHeightFactor = style?.maxHeightFactor ?? defaults.maxHeightFactor!;

    final effectiveBarrierColor = style?.barrierColor ?? defaults.barrierColor!;
    final intercept = style?.barrierIntercept ?? true;

    final effectiveAnimation = animation ?? const AlwaysStoppedAnimation(1.0);

    final screenSize = MediaQuery.sizeOf(context);
    final bool growUp = _resolveGrowUp(targetRect, screenSize, direction);
    final double availableHeight =
        _resolveAvailableHeight(targetRect, screenSize, growUp);

    final maxHeight = availableHeight * maxHeightFactor.clamp(0.0, 1.0);

    final minWidth = style?.minWidth;
    final maxWidth = style?.maxWidth;
    Widget content = child;
    if (minWidth != null || maxWidth != null) {
      content = ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: minWidth ?? 0.0,
          maxWidth: maxWidth ?? double.infinity,
        ),
        child: content,
      );
    }
    content = ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: content,
    );

    return AnimatedBuilder(
      animation: effectiveAnimation,
      child: content,
      builder: (context, child) {
        final t = effectiveAnimation.value;
        final barrierColor =
            Color.lerp(Colors.transparent, effectiveBarrierColor, t) ??
                effectiveBarrierColor;

        // Screen rect in Stack-local coordinates.
        // Stack origin = screen's top-left (from CompositedTransformFollower
        // with offset: Offset(-targetRect.left, -targetRect.top)), so the
        // screen's top-left corner is at (0, 0) in Stack space.
        final screenRect =
            Rect.fromLTWH(0, 0, screenSize.width, screenSize.height);

        return Stack(
          clipBehavior:
              Clip.none, // Allow barrier/panel to extend beyond bounds
          children: [
            // Barrier layer: covers only the direction-specific half of the screen.
            // - direction=below (growUp=false): covers area below the trigger
            // - direction=above (growUp=true):  covers area above the trigger
            // The trigger (Bar/Button) itself is never covered, so no ClipPath needed.
            // Coordinates are in screen space (Stack origin = screen top-left).
            if (targetRect != null)
              Positioned(
                left: 0,
                top: growUp ? 0 : targetRect!.bottom,
                width: screenSize.width,
                height: growUp
                    ? targetRect!.top
                    : (screenSize.height - targetRect!.bottom),
                child: _buildBarrier(
                  intercept: intercept,
                  onOverlayTap: onOverlayTap,
                  barrierColor: barrierColor,
                ),
              )
            else
              Positioned.fromRect(
                rect: screenRect,
                child: _buildBarrier(
                  intercept: intercept,
                  onOverlayTap: onOverlayTap,
                  barrierColor: barrierColor,
                ),
              ),
            // Panel layer: positioned by CustomSingleChildLayout in screen
            // coordinates, renders on top of the barrier.
            // below: panel top = targetRect.bottom
            // above: panel top = targetRect.top - childHeight
            CustomSingleChildLayout(
              delegate: _SelectOverlayPositionDelegate(
                targetRect: targetRect,
                screenSize: screenSize,
                growUp: growUp,
                margin: screenMargin,
              ),
              child: FadeTransition(
                opacity: effectiveAnimation,
                child: SizeTransition(
                  sizeFactor: effectiveAnimation,
                  axisAlignment: growUp ? 1.0 : -1.0,
                  child: child,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Builds the barrier widget that captures taps and shows the backdrop color.
  Widget _buildBarrier({
    required bool intercept,
    required GestureTapCallback? onOverlayTap,
    required Color barrierColor,
  }) {
    return GestureDetector(
      onTap: intercept ? onOverlayTap : null,
      behavior:
          intercept ? HitTestBehavior.opaque : HitTestBehavior.translucent,
      child: ColoredBox(color: barrierColor),
    );
  }
}

/// Positions the overlay child relative to the trigger rect, keeping it fully
/// on screen by translating it. This mirrors the strategy used by
/// [PopupMenuButton]'s [positionDependentBox] (preserve size, clamp position)
/// rather than scaling the panel down.
class _SelectOverlayPositionDelegate extends SingleChildLayoutDelegate {
  _SelectOverlayPositionDelegate({
    required this.targetRect,
    required this.screenSize,
    required this.growUp,
    required this.margin,
  });

  final Rect? targetRect;
  final Size screenSize;
  final bool growUp;
  final double margin;

  @override
  Size getSize(BoxConstraints constraints) => constraints.constrain(screenSize);

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final maxW = math.max(0.0, screenSize.width - margin * 2);
    final double maxH;
    final rect = targetRect;
    if (rect == null) {
      maxH = screenSize.height - margin * 2;
    } else {
      maxH = (growUp ? rect.top : screenSize.height - rect.bottom) - margin;
    }
    return BoxConstraints(
      maxWidth: maxW,
      maxHeight: math.max(0.0, maxH),
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final rect = targetRect;
    if (rect == null) {
      // No anchor: center horizontally near the top.
      final dx = (screenSize.width - childSize.width) / 2;
      return Offset(dx, margin);
    }

    // Horizontal: anchor the panel's left edge at the trigger's left edge,
    // then clamp so the whole panel stays within [margin, screenW - margin].
    double left = rect.left;
    final maxLeft = screenSize.width - margin - childSize.width;
    if (left > maxLeft) left = maxLeft;
    if (left < margin) left = margin;

    // Vertical: below the trigger, or above it when [growUp] is set. The
    // returned offset is in screen coordinates (Stack origin = screen
    // top-left via the CompositedTransformFollower offset).
    final double top = growUp ? rect.top - childSize.height : rect.bottom;
    return Offset(left, top);
  }

  @override
  bool shouldRelayout(covariant _SelectOverlayPositionDelegate old) =>
      old.targetRect != targetRect ||
      old.screenSize != screenSize ||
      old.growUp != growUp ||
      old.margin != margin;
}

class _SelectOverlayDefaults extends SelectOverlayStyle {
  const _SelectOverlayDefaults(this.context)
      : super(maxHeightFactor: kSelectOverlayMaxHeightFactor);

  final BuildContext context;

  @override
  Color? get barrierColor => Colors.transparent;
}
