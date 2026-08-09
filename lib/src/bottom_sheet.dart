import 'package:flutter/material.dart';

import 'select/select_delegate.dart';
import 'select/select_entry.dart';
import 'select/select_panel.dart';

/// Shows a select in a modal bottom sheet built with Flutter's
/// [showModalBottomSheet].
///
/// Returns the selected [SelectEntries] when the user applies the selection,
/// or `null` when the sheet is dismissed (for example by tapping the barrier
/// when [isDismissible] is `true`, dragging it down, or via the system back
/// gesture).
///
/// The concrete select type (Cascading, List, Grid or Flatten) is determined
/// entirely by the concrete [SelectDelegate] passed via [delegate]. Any
/// [SelectDelegate] subclass works, so no separate functions are required.
///
/// The interaction mirrors [showSelect]:
/// - In single-selection mode, tapping an item applies the selection
///   immediately and closes the sheet.
/// - In multi-selection mode, the action bar's "Apply" button must be tapped
///   to confirm; "Reset" only clears the current selection without closing.
///
/// The optional [title] is rendered above the select panel.
///
/// Most of the remaining parameters ([backgroundColor], [elevation], [shape],
/// [clipBehavior], [constraints], [barrierColor], [isScrollControlled],
/// [useRootNavigator], [isDismissible], [enableDrag], [showDragHandle],
/// [useSafeArea] and [routeSettings]) are forwarded directly to
/// [showModalBottomSheet].
///
/// [isScrollControlled] defaults to `true` so the sheet can size to its
/// content. Because the select body is shrink-wrapped (it has no outer
/// scroll), a default max height of 90% of the screen is applied automatically
/// and the body scrolls internally, unless [constraints] is provided.
///
/// Styling (colors, per-widget themes and the panel decoration via
/// [SelectDelegate.panelTheme]) is carried entirely by [delegate].
Future<SelectEntries?> showModalBottomSelect({
  required BuildContext context,
  required SelectDelegate delegate,
  bool isScrollControlled = false,
  bool useRootNavigator = false,
  bool isDismissible = true,
  bool useSafeArea = false,
  Widget? title,
  Color? backgroundColor,
  double? elevation,
  ShapeBorder? shape,
  Clip? clipBehavior,
  BoxConstraints? constraints,
  Color? barrierColor,
  bool enableDrag = true,
  bool? showDragHandle,
  RouteSettings? routeSettings,
  Offset? anchorPoint,
}) {
  // With [isScrollControlled] true Flutter does not cap the sheet height, but
  // the select body is shrink-wrapped and has no outer scroll. Without a max
  // height tall content would overflow off-screen and hide the action bar, so
  // apply a sensible default unless the caller overrides [constraints].
  final effectiveConstraints = constraints ??
      BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      );
  return showModalBottomSheet<SelectEntries?>(
    context: context,
    isScrollControlled: isScrollControlled,
    useRootNavigator: useRootNavigator,
    isDismissible: isDismissible,
    useSafeArea: useSafeArea,
    backgroundColor: backgroundColor,
    elevation: elevation,
    shape: shape,
    clipBehavior: clipBehavior,
    constraints: effectiveConstraints,
    barrierColor: barrierColor,
    enableDrag: enableDrag,
    showDragHandle: showDragHandle,
    routeSettings: routeSettings,
    anchorPoint: anchorPoint,
    builder: (sheetContext) => _ModalBottomSheetContent(
      delegate: delegate,
      title: title,
    ),
  );
}

/// The bottom-sheet body rendered by [showModalBottomSheet].
///
/// Wraps a [SelectPanel] and closes the sheet (returning the selection) when
/// the panel fires its apply callback.
class _ModalBottomSheetContent extends StatefulWidget {
  const _ModalBottomSheetContent({
    required this.delegate,
    this.title,
  });

  final SelectDelegate delegate;
  final Widget? title;

  @override
  State<_ModalBottomSheetContent> createState() =>
      _ModalBottomSheetContentState();
}

class _ModalBottomSheetContentState extends State<_ModalBottomSheetContent> {
  // Guards against double-pop if both an apply callback and a drag/barrier
  // dismiss race.
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
      // Reset is handled internally by the select widget; the sheet stays
      // open so the user can keep adjusting the selection.
      onResetTap: () {},
    );

    // Shrink to the panel's intrinsic height when content is short (e.g. a
    // 6-row single-select list) so there is no empty space, while still capping
    // at the bottom sheet's own max height (0.9 of the screen when
    // [isScrollControlled] is false) when content is large. The select then
    // scrolls internally and its action bar stays pinned to the bottom.
    //
    // SafeArea with bottom:true is required here because Flutter's
    // useSafeArea parameter on showModalBottomSheet uses SafeArea(bottom: false),
    // meaning it only handles top/left/right safe areas. The bottom safe area
    // (e.g., iPhone home indicator) must be handled by the content itself.
    return SafeArea(
      top: false,
      bottom: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.title != null) _BottomSheetHeader(title: widget.title!),
          Flexible(
            fit: FlexFit.loose,
            child: panel,
          ),
        ],
      ),
    );
  }
}

/// Optional header shown above the select panel inside the bottom sheet.
class _BottomSheetHeader extends StatelessWidget {
  const _BottomSheetHeader({required this.title});

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
