import 'package:flutter/material.dart';

/// Declares whether the reset/apply action bar should be hidden for the
/// select widgets in [child]'s subtree.
///
/// [SelectView] wraps its panel with [hidden] set to `true` so that inline
/// selects omit the action bar; modal hosts (dialogs and bottom sheets) do
/// not provide this widget, so the action bar remains visible there.
///
/// This keeps the action bar's "render or not" decision out of the delegate
/// (whose [SelectDelegate.actionBarBuilder] only customizes the bar's UI),
/// avoiding a per-subclass wrapping delegate.
class SelectActionBarVisibility extends InheritedWidget {
  const SelectActionBarVisibility({
    super.key,
    this.hidden = false,
    required super.child,
  });

  /// Whether the action bar should be hidden for selects in this subtree.
  final bool hidden;

  /// Whether the action bar is hidden for selects at [context].
  ///
  /// Defaults to `false` (visible) when no [SelectActionBarVisibility] is
  /// found above [context], so modal hosts that do not wrap their panel keep
  /// showing the action bar.
  static bool isHidden(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<SelectActionBarVisibility>();
    return scope?.hidden ?? false;
  }

  @override
  bool updateShouldNotify(SelectActionBarVisibility oldWidget) =>
      hidden != oldWidget.hidden;
}
