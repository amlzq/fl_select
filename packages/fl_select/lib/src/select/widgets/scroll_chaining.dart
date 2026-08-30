import 'dart:math' as math;

import 'package:flutter/foundation.dart' show precisionErrorTolerance;
import 'package:flutter/material.dart';

/// Touch-gesture scroll chaining shared by the select bodies hosted inside a
/// page-level scrollable.
///
/// Flutter natively chains only pointer-wheel scrolling: once an inner
/// scrollable consumes what it can, the surplus is offered to the ancestor
/// (see `ScrollPosition.pointerScroll`). Touch drags have no such support —
/// the inner scrollable wins the gesture arena and simply stops dead at its
/// edge, which makes a panel hosted in a page-level scroll view feel stuck.
///
/// [ChainingClampingScrollPhysics] restores the native nested-scrolling feel
/// (iOS `UIScrollView` chaining, Android `NestedScrollingParent`) by handing
/// unconsumed gestures to the nearest same-direction ancestor scrollable.

/// [ClampingScrollPhysics] extended with touch-gesture scroll chaining.
///
/// - Dragging past the end/start edge scrolls the ancestor by the leftover.
/// - Dragging back first unwinds the ancestor's chained offset while the body
///   rests at its edge, and only then scrolls the body itself.
/// - A fling released while the body rests at an edge (and thus produces no
///   simulation of its own) hands its momentum to the ancestor by starting a
///   ballistic simulation on it.
///
/// Falls back to plain [ClampingScrollPhysics] behavior whenever no
/// same-direction scrollable ancestor exists.
class ChainingClampingScrollPhysics extends ClampingScrollPhysics {
  const ChainingClampingScrollPhysics({super.parent});

  @override
  ChainingClampingScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return ChainingClampingScrollPhysics(parent: buildParent(ancestor));
  }

  /// The nearest same-direction vertical ancestor scrollable of the
  /// scrollable this position belongs to — typically the page-level
  /// [SingleChildScrollView] hosting the panel — or null when there is none
  /// to chain to.
  ///
  /// The framework always invokes physics methods with the owning
  /// [ScrollPosition], whose [ScrollPosition.context]'s [ScrollContext
  /// .storageContext] is the inner [Scrollable]'s own context;
  /// [Scrollable.maybeOf] from there walks the ancestors (the inner
  /// scrollable itself is never revisited, per its documentation) and skips
  /// non-vertical ancestors to the nearest vertical one.
  ScrollPositionWithSingleContext? _findOuter(ScrollMetrics metrics) {
    if (metrics is! ScrollPosition) return null;
    final outer = Scrollable.maybeOf(
      metrics.context.storageContext,
      axis: Axis.vertical,
    );
    if (outer == null) return null;
    final outerPosition = outer.position;
    if (outerPosition is! ScrollPositionWithSingleContext) return null;
    if (!outerPosition.hasContentDimensions) return null;
    // Select bodies never reverse (AxisDirection.down); a reversed ancestor
    // would need inverted deltas, so it is not chained to.
    if (outerPosition.axisDirection != AxisDirection.down) return null;
    return outerPosition;
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    final outer = _findOuter(position);
    if (outer == null || !outer.hasContentDimensions) {
      return super.applyPhysicsToUserOffset(position, offset);
    }

    // Work in pixel space: the body would land on `target` for this raw
    // offset because the framework applies it as `setPixels(pixels - result)`.
    double target = position.pixels - offset;

    if (target > position.maxScrollExtent) {
      // Dragging past the end of the content: whatever the body cannot
      // consume chains to the ancestor.
      _moveOuterBy(outer, target - position.maxScrollExtent);
      target = position.maxScrollExtent;
    } else if (target < position.minScrollExtent) {
      // Dragging past the start of the content chains likewise.
      _moveOuterBy(outer, target - position.minScrollExtent);
      target = position.minScrollExtent;
    } else if (target < position.pixels &&
        position.pixels >= position.maxScrollExtent - precisionErrorTolerance &&
        outer.pixels > outer.minScrollExtent) {
      // Dragging back towards the start while the body rests at its end
      // and the ancestor still carries a chained offset: unwind the
      // ancestor first — the body only scrolls once the ancestor is done.
      final unwind = math.min(
          position.pixels - target, outer.pixels - outer.minScrollExtent);
      _moveOuterBy(outer, -unwind);
      target += unwind;
    }

    final result = position.pixels - target;
    if (result == 0.0) {
      // The whole gesture was consumed by the ancestor.
      return 0.0;
    }
    return super.applyPhysicsToUserOffset(position, result);
  }

  /// Moves [outer] by [delta], clamped to its scroll range.
  void _moveOuterBy(ScrollPosition outer, double delta) {
    if (delta == 0.0) return;
    final target = (outer.pixels + delta)
        .clamp(outer.minScrollExtent, outer.maxScrollExtent);
    if (target != outer.pixels) {
      // jumpTo also stops any ancestor ballistic activity, which is the
      // correct grab behavior while the user's finger is down on the panel.
      outer.jumpTo(target);
    }
  }

  @override
  Simulation? createBallisticSimulation(
      ScrollMetrics position, double velocity) {
    final simulation = super.createBallisticSimulation(position, velocity);
    if (simulation != null) return simulation;

    if (velocity == 0.0) return null;
    if (velocity.abs() < toleranceFor(position).velocity) return null;
    final outer = _findOuter(position);
    if (outer == null || !outer.hasContentDimensions) return null;

    // The fling dies at the body's edge (super returned no simulation);
    // hand its momentum to the ancestor if it can still travel that way.
    final bool towardsEnd = velocity > 0;
    final bool bodyAtEdge = towardsEnd
        ? position.pixels >= position.maxScrollExtent - precisionErrorTolerance
        : position.pixels <= position.minScrollExtent + precisionErrorTolerance;
    final bool outerHasRoom = towardsEnd
        ? outer.pixels < outer.maxScrollExtent - precisionErrorTolerance
        : outer.pixels > outer.minScrollExtent + precisionErrorTolerance;
    if (!bodyAtEdge || !outerHasRoom) return null;

    // Hand the momentum over: the ancestor runs its own ballistic activity
    // from this velocity, using its own physics.
    outer.goBallistic(velocity);
    return null;
  }
}
