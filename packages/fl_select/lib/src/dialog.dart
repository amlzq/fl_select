import 'package:flutter/material.dart';

import 'select/select_delegate.dart';
import 'select/select_entry.dart';
import 'select/select_panel.dart';
import 'select_header.dart';

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
/// The optional [title] is rendered above the select panel. A leading and/or
/// trailing widget may be attached via [leading] / [trailing] to mimic a
/// [ListTile] header; they are shown even when [title] is omitted. Set
/// [centerTitle] to `true` to center the [title] (like [AppBar.centerTitle]);
/// when `null` the default is platform-dependent (`true` on iOS/macOS,
/// `false` elsewhere).
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
  Widget? leading,
  Widget? trailing,
  bool? centerTitle,
  double? elevation,
  EdgeInsets? insetPadding,
  Clip? clipBehavior,
  ShapeBorder? shape,
  TransitionBuilder? builder,
  Color? barrierColor,
  RouteSettings? routeSettings,
  Offset? anchorPoint,
}) {
  final route = _SelectDialogRoute<SelectEntries?>(
    pageBuilder: (innerContext) => _SelectDialog(
      delegate: delegate,
      title: title,
      leading: leading,
      trailing: trailing,
      centerTitle: centerTitle,
      elevation: elevation,
      insetPadding: insetPadding,
      clipBehavior: clipBehavior,
      shape: shape,
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
    this.leading,
    this.trailing,
    this.centerTitle,
    this.elevation,
    this.insetPadding,
    this.clipBehavior,
    this.shape,
  });

  final SelectDelegate delegate;
  final Widget? title;
  final Widget? leading;
  final Widget? trailing;
  final bool? centerTitle;
  final double? elevation;
  final EdgeInsets? insetPadding;
  final Clip? clipBehavior;
  final ShapeBorder? shape;

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
      // Fallback chain: explicit argument -> DialogTheme.insetPadding ->
      // the framework's default (horizontal 40 / vertical 24). Mirrors how
      // AlertDialog resolves its padding, and stays compilable on older
      // Flutter versions where Dialog.insetPadding is non-nullable.
      insetPadding: widget.insetPadding ??
          Theme.of(context).dialogTheme.insetPadding ??
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
            if (widget.title != null ||
                widget.leading != null ||
                widget.trailing != null)
              SelectHeader(
                title: widget.title,
                leading: widget.leading,
                trailing: widget.trailing,
                centerTitle: widget.centerTitle,
              ),
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
