import 'package:flutter/material.dart';

import 'select/select_delegate.dart';
import 'select/select_entry.dart';
import 'select/select_panel.dart';

/// Shows a select in a modal dialog.
///
/// Returns the selected [SelectEntries] when the user applies the selection,
/// or `null` when the dialog is dismissed (for example by tapping the barrier
/// when [barrierDismissible] is `true`, or via the system back gesture).
///
/// The concrete select type (Cascading, List, Grid or Flatten) is determined
/// entirely by the concrete [SelectDelegate] passed via [delegate]. Any
/// [SelectDelegate] subclass works, so no separate functions are required.
///
/// The interaction mirrors Flutter's [showTimePicker]:
/// - In single-selection mode, tapping an item applies the selection
///   immediately and closes the dialog.
/// - In multi-selection mode, the action bar's "Apply" button must be tapped
///   to confirm; "Reset" only clears the current selection without closing.
///
/// The optional [title] is rendered above the select panel.
///
/// The [elevation], [shape] and [clipBehavior] parameters are forwarded to the
/// outer [Dialog] decoration. These are independent of
/// [SelectDelegate.panelTheme] (which decorates the panel background itself);
/// use either layer, or both, depending on the desired look. All other styling
/// (colors, per-widget themes) is carried by [delegate].
Future<SelectEntries?> showSelect({
  required BuildContext context,
  required SelectDelegate delegate,
  bool barrierDismissible = true,
  bool useRootNavigator = true,
  Widget? title,
  double? elevation,
  ShapeBorder? shape,
  Clip? clipBehavior,
  TransitionBuilder? builder,
  Color? barrierColor,
  RouteSettings? routeSettings,
  Offset? anchorPoint,
}) {
  final route = _SelectDialogRoute<SelectEntries?>(
    pageBuilder: (innerContext) => _SelectDialog(
      delegate: delegate,
      title: title,
      elevation: elevation,
      shape: shape,
      clipBehavior: clipBehavior,
    ),
    barrierDismissible: barrierDismissible,
    barrierColor: barrierColor ?? Colors.black54,
    barrierLabel: barrierDismissible
        ? MaterialLocalizations.of(context).modalBarrierDismissLabel
        : null,
    settings: routeSettings,
    anchorPoint: anchorPoint,
    builder: builder,
  );

  return Navigator.of(context, rootNavigator: useRootNavigator)
      .push<SelectEntries?>(route);
}

/// Modal route used by [showSelect].
///
/// Mirrors the structure of Flutter's `_TimePickerDialogRoute`: it builds the
/// page via [pageBuilder] and applies a fade + scale transition.
class _SelectDialogRoute<T> extends RawDialogRoute<T> {
  _SelectDialogRoute({
    required WidgetBuilder pageBuilder,
    super.barrierDismissible = true,
    required Color barrierColor,
    super.barrierLabel,
    super.settings,
    super.anchorPoint,
    TransitionBuilder? builder,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) {
            final Widget page = pageBuilder(context);
            return builder == null ? page : builder(context, page);
          },
          barrierColor: barrierColor,
          transitionDuration: const Duration(milliseconds: 200),
          transitionBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.92, end: 1.0).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
                child: child,
              ),
            );
          },
        );
}

/// The dialog body rendered by [_SelectDialogRoute].
///
/// Wraps a [SelectPanel] and closes the route (returning the selection) when
/// the panel fires its apply callback.
class _SelectDialog extends StatefulWidget {
  const _SelectDialog({
    required this.delegate,
    this.title,
    this.elevation,
    this.shape,
    this.clipBehavior,
  });

  final SelectDelegate delegate;
  final Widget? title;
  final double? elevation;
  final ShapeBorder? shape;
  final Clip? clipBehavior;

  @override
  State<_SelectDialog> createState() => _SelectDialogState();
}

class _SelectDialogState extends State<_SelectDialog> {
  // Guards against double-pop if both an apply callback and a barrier dismiss
  // race (e.g. on some platforms).
  bool _popped = false;

  void _popWith(SelectEntries? result) {
    if (_popped) return;
    _popped = true;
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final panel = SelectPanel(
      delegate: widget.delegate,
      onApplyTap: (selected) => _popWith(selected),
      // Reset is handled internally by the select widget; the dialog stays
      // open so the user can keep adjusting the selection.
      onResetTap: () {},
    );

    return Dialog(
      elevation: widget.elevation,
      shape: widget.shape,
      clipBehavior: widget.clipBehavior ?? Clip.antiAlias,
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: Column(
          // Shrink to the panel's intrinsic height when content is short
          // (e.g. a 6-row single-select list) so there is no empty space,
          // while still capping at 0.7 of the screen height.
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.title != null) _SelectDialogHeader(title: widget.title!),
            // `loose` lets the panel take only as much height as it needs when
            // content is small, but never exceed the free space (0.7 screen
            // height minus the header) when content is large, so the select
            // scrolls internally and its action bar stays pinned to the bottom.
            Flexible(
              fit: FlexFit.loose,
              child: panel,
            ),
          ],
        ),
      ),
    );
  }
}

/// Optional header shown above the select panel inside [_SelectDialog].
class _SelectDialogHeader extends StatelessWidget {
  const _SelectDialogHeader({required this.title});

  final Widget title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.titleLarge ?? theme.textTheme.titleMedium;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      alignment: Alignment.centerLeft,
      child: DefaultTextStyle(
        style: textStyle!,
        child: title,
      ),
    );
  }
}
