import 'dart:async';

import 'package:flutter/material.dart';

import 'i18n/select_localizations.dart';
import 'popup_select_button_theme.dart';
import 'popup_select_controller.dart';
import 'select/select_delegate.dart';
import 'select/select_entry.dart';
import 'select_label_state.dart';
import 'select_overlay.dart';
import 'select_overlay_host.dart';
import 'select_overlay_style.dart';

/// Visual variants for [PopupSelectButton].
enum PopupSelectButtonVariant {
  /// A button with elevation and a subtle surface tint (like [ElevatedButton]).
  elevated,

  /// A filled button using the color scheme primary (like [FilledButton]).
  filled,

  /// A button with a transparent background and an outline border
  /// (like [OutlinedButton]).
  outlined,
}

/// Callback invoked with the selected entries only — used by
typedef PopupSelectButtonResultCallback = void Function(SelectEntries selected);

typedef PopupSelectButtonWillToggleCallback = FutureOr<bool> Function();

/// Default height used when the button size cannot be measured yet.
const kPopupSelectButtonHeight = 40.0;

/// A single-button alternative to [PopupSelectBar].
///
/// Where [PopupSelectBar] renders a horizontal row of tabs, this widget
/// exposes a single trigger styled like a Material button (one of
/// [PopupSelectButtonVariant]) that opens the select overlay on tap,
/// similar to [PopupMenuButton]. The interaction (overlay positioning,
/// animation, dismissal on outside tap, auto-close on apply) is driven by the
/// same [PopupSelectController] machinery as [PopupSelectBar].
///
/// Provide a [selectDelegate] to define the select content, and a [label]
/// or [child] for the trigger. The trailing [icon] rotates while the overlay is
/// open. After an apply, the button label is updated with the resulting label.
class PopupSelectButton extends StatefulWidget {
  /// Creates a filled button (the default variant).
  const PopupSelectButton({
    super.key,
    required this.selectDelegate,
    this.variant = PopupSelectButtonVariant.filled,
    this.label,
    this.child,
    this.icon,
    this.overlayStyle,
    VoidCallback? onSelectShowed,
    VoidCallback? onSelectHidden,
    PopupSelectButtonWillToggleCallback? onSelectWillShow,
    PopupSelectButtonWillToggleCallback? onSelectWillHide,
    this.onChanged,
    required this.onApplied,
    this.onReset,
    this.labelLoader,
    this.direction = PopupSelectDirection.below,
    @Deprecated(
        'Use onSelectShowed instead. This will be removed in a future minor version.')
    VoidCallback? onSelectorShowed,
    @Deprecated(
        'Use onSelectHidden instead. This will be removed in a future minor version.')
    VoidCallback? onSelectorHidden,
    @Deprecated(
        'Use onSelectWillShow instead. This will be removed in a future minor version.')
    PopupSelectButtonWillToggleCallback? onSelectorWillShow,
    @Deprecated(
        'Use onSelectWillHide instead. This will be removed in a future minor version.')
    PopupSelectButtonWillToggleCallback? onSelectorWillHide,
  })  : onSelectShowed = onSelectShowed ?? onSelectorShowed,
        onSelectHidden = onSelectHidden ?? onSelectorHidden,
        onSelectWillShow = onSelectWillShow ?? onSelectorWillShow,
        onSelectWillHide = onSelectWillHide ?? onSelectorWillHide,
        assert(onSelectShowed == null || onSelectorShowed == null,
            'Either provide onSelectShowed or onSelectorShowed, not both.'),
        assert(onSelectHidden == null || onSelectorHidden == null,
            'Either provide onSelectHidden or onSelectorHidden, not both.'),
        assert(onSelectWillShow == null || onSelectorWillShow == null,
            'Either provide onSelectWillShow or onSelectorWillShow, not both.'),
        assert(onSelectWillHide == null || onSelectorWillHide == null,
            'Either provide onSelectWillHide or onSelectorWillHide, not both.');

  /// Creates an elevated button. The [variant] is fixed to
  /// [PopupSelectButtonVariant.elevated].
  const PopupSelectButton.elevated({
    super.key,
    required this.selectDelegate,
    this.label,
    this.child,
    this.icon,
    this.overlayStyle,
    VoidCallback? onSelectShowed,
    VoidCallback? onSelectHidden,
    PopupSelectButtonWillToggleCallback? onSelectWillShow,
    PopupSelectButtonWillToggleCallback? onSelectWillHide,
    this.onChanged,
    required this.onApplied,
    this.onReset,
    this.labelLoader,
    this.direction = PopupSelectDirection.below,
    @Deprecated(
        'Use onSelectShowed instead. This will be removed in a future minor version.')
    VoidCallback? onSelectorShowed,
    @Deprecated(
        'Use onSelectHidden instead. This will be removed in a future minor version.')
    VoidCallback? onSelectorHidden,
    @Deprecated(
        'Use onSelectWillShow instead. This will be removed in a future minor version.')
    PopupSelectButtonWillToggleCallback? onSelectorWillShow,
    @Deprecated(
        'Use onSelectWillHide instead. This will be removed in a future minor version.')
    PopupSelectButtonWillToggleCallback? onSelectorWillHide,
  })  : variant = PopupSelectButtonVariant.elevated,
        onSelectShowed = onSelectShowed ?? onSelectorShowed,
        onSelectHidden = onSelectHidden ?? onSelectorHidden,
        onSelectWillShow = onSelectWillShow ?? onSelectorWillShow,
        onSelectWillHide = onSelectWillHide ?? onSelectorWillHide,
        assert(onSelectShowed == null || onSelectorShowed == null,
            'Either provide onSelectShowed or onSelectorShowed, not both.'),
        assert(onSelectHidden == null || onSelectorHidden == null,
            'Either provide onSelectHidden or onSelectorHidden, not both.'),
        assert(onSelectWillShow == null || onSelectorWillShow == null,
            'Either provide onSelectWillShow or onSelectorWillShow, not both.'),
        assert(onSelectWillHide == null || onSelectorWillHide == null,
            'Either provide onSelectWillHide or onSelectorWillHide, not both.');

  /// Creates an outlined button. The [variant] is fixed to
  /// [PopupSelectButtonVariant.outlined].
  const PopupSelectButton.outlined({
    super.key,
    required this.selectDelegate,
    this.label,
    this.child,
    this.icon,
    this.overlayStyle,
    VoidCallback? onSelectShowed,
    VoidCallback? onSelectHidden,
    PopupSelectButtonWillToggleCallback? onSelectWillShow,
    PopupSelectButtonWillToggleCallback? onSelectWillHide,
    this.onChanged,
    required this.onApplied,
    this.onReset,
    this.labelLoader,
    this.direction = PopupSelectDirection.below,
    @Deprecated(
        'Use onSelectShowed instead. This will be removed in a future minor version.')
    VoidCallback? onSelectorShowed,
    @Deprecated(
        'Use onSelectHidden instead. This will be removed in a future minor version.')
    VoidCallback? onSelectorHidden,
    @Deprecated(
        'Use onSelectWillShow instead. This will be removed in a future minor version.')
    PopupSelectButtonWillToggleCallback? onSelectorWillShow,
    @Deprecated(
        'Use onSelectWillHide instead. This will be removed in a future minor version.')
    PopupSelectButtonWillToggleCallback? onSelectorWillHide,
  })  : variant = PopupSelectButtonVariant.outlined,
        onSelectShowed = onSelectShowed ?? onSelectorShowed,
        onSelectHidden = onSelectHidden ?? onSelectorHidden,
        onSelectWillShow = onSelectWillShow ?? onSelectorWillShow,
        onSelectWillHide = onSelectWillHide ?? onSelectorWillHide,
        assert(onSelectShowed == null || onSelectorShowed == null,
            'Either provide onSelectShowed or onSelectorShowed, not both.'),
        assert(onSelectHidden == null || onSelectorHidden == null,
            'Either provide onSelectHidden or onSelectorHidden, not both.'),
        assert(onSelectWillShow == null || onSelectorWillShow == null,
            'Either provide onSelectWillShow or onSelectorWillShow, not both.'),
        assert(onSelectWillHide == null || onSelectorWillHide == null,
            'Either provide onSelectWillHide or onSelectorWillHide, not both.');

  /// Select configuration for the single trigger.
  final SelectDelegate selectDelegate;

  /// Visual style of the trigger button.
  final PopupSelectButtonVariant variant;

  /// Default label shown on the trigger. Replaced by the applied result label
  /// after a selection is applied. Mutually exclusive with [child].
  final String? label;

  /// Custom trigger content. Takes precedence over [label].
  final Widget? child;

  /// Trailing icon. Defaults to [Icons.arrow_drop_down] and rotates by 180°
  /// while the overlay is open.
  final Widget? icon;

  /// Overrides the default value of [SelectOverlayStyle].
  final SelectOverlayStyle? overlayStyle;

  /// Fired when the select overlay is shown.
  final VoidCallback? onSelectShowed;

  /// Fired when the select overlay is hidden.
  final VoidCallback? onSelectHidden;

  /// Invoked just before the overlay is shown. The returned [Future] (if any)
  /// is awaited before the overlay appears, e.g. to scroll a header into place.
  /// Returning `false` cancels the show, leaving the overlay hidden.
  final PopupSelectButtonWillToggleCallback? onSelectWillShow;

  /// Invoked just before the overlay is hidden. Returning `false` cancels the
  /// hide, leaving the overlay visible.
  final PopupSelectButtonWillToggleCallback? onSelectWillHide;

  /// @nodoc
  @Deprecated(
      'Use onSelectShowed instead. This will be removed in a future minor version.')
  VoidCallback? get onSelectorShowed => onSelectShowed;

  /// @nodoc
  @Deprecated(
      'Use onSelectHidden instead. This will be removed in a future minor version.')
  VoidCallback? get onSelectorHidden => onSelectHidden;

  /// @nodoc
  @Deprecated(
      'Use onSelectWillShow instead. This will be removed in a future minor version.')
  PopupSelectButtonWillToggleCallback? get onSelectorWillShow =>
      onSelectWillShow;

  /// @nodoc
  @Deprecated(
      'Use onSelectWillHide instead. This will be removed in a future minor version.')
  PopupSelectButtonWillToggleCallback? get onSelectorWillHide =>
      onSelectWillHide;

  /// Fired whenever a select reports a selection change.
  final PopupSelectButtonResultCallback? onChanged;

  /// Fired when a select is applied.
  final PopupSelectButtonResultCallback onApplied;

  /// Fired when reset is triggered.
  final VoidCallback? onReset;

  /// Optional custom label loader based on the applied selection result.
  ///
  /// Receives only the selected entries; the canonical [SelectLabelLoader]
  /// form. When provided, the trigger label is built from the applied selection
  /// instead of the default [label] / result label. Mutually exclusive with
  /// [child] only in spirit — both may be set, but the loaded label replaces
  /// the displayed text.
  final SelectLabelLoader? labelLoader;

  /// Vertical placement of the select panel relative to the trigger.
  ///
  /// Defaults to [PopupSelectDirection.below], which always shows the
  /// panel under the trigger. Use [PopupSelectDirection.adaptive] to let
  /// it flip above when there is more room there, or
  /// [PopupSelectDirection.above] to force the panel above. Regardless of
  /// the value, the panel is always kept fully on screen horizontally.
  final PopupSelectDirection direction;

  @override
  State<PopupSelectButton> createState() => _PopupSelectButtonState();
}

class _PopupSelectButtonState extends State<PopupSelectButton>
    with SingleTickerProviderStateMixin {
  late final PopupSelectController _controller;
  final SelectLabelState _labelState = SelectLabelState();

  VoidCallback? _removeChangeListener;
  VoidCallback? _removeApplyListener;
  VoidCallback? _removeResetListener;

  @override
  void initState() {
    super.initState();
    _controller = PopupSelectController();
    _controller.addListener(_handleControllerTick);
    _removeChangeListener = _controller.addChangeListener(_handleWidgetChange);
    _removeApplyListener = _controller.addApplyListener(_handleWidgetApply);
    _removeResetListener = _controller.addResetListener(_handleWidgetReset);
    _controller.attachSelectDelegates([widget.selectDelegate]);
    _controller.attachTickerProvider(this);
    _labelState.originalLabel = widget.label;
    _labelState.labelLoader = widget.labelLoader;
    _controller.labelStateMap[0] = _labelState;
  }

  @override
  void didUpdateWidget(covariant PopupSelectButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.attachSelectDelegates([widget.selectDelegate]);
    _controller.attachTickerProvider(this);
    if (oldWidget.label != widget.label) {
      _labelState.originalLabel = widget.label;
      _controller.notifyListeners();
    }
    if (oldWidget.labelLoader != widget.labelLoader) {
      _labelState.labelLoader = widget.labelLoader;
      _controller.notifyListeners();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerTick);
    _removeChangeListener?.call();
    _removeApplyListener?.call();
    _removeResetListener?.call();
    _controller.hideSelect(immediate: true);
    _controller.detachTickerProvider();
    _controller.dispose();
    super.dispose();
  }

  void _handleControllerTick() => setState(() {});

  void _handleWidgetChange(
          SelectLabelState labelState, SelectEntries selected) =>
      widget.onChanged?.call(selected);

  void _handleWidgetApply(
          SelectLabelState labelState, SelectEntries selected) =>
      widget.onApplied(selected);

  void _handleWidgetReset() => widget.onReset?.call();

  Future<void> _handleTap() async {
    final willShow = !_controller.isSelectShowing;
    bool proceed = willShow
        ? await widget.onSelectWillShow?.call() ?? true
        : await widget.onSelectWillHide?.call() ?? true;
    if (!proceed) return;
    _controller.previousSelectDelegate = widget.selectDelegate;
    _controller.toggleSelect(index: 0);
    if (_controller.isSelectShowing) {
      widget.onSelectShowed?.call();
    } else {
      widget.onSelectHidden?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final PopupSelectButtonTheme defaults =
        _PopupSelectButtonDefaults(context, widget.variant);
    final PopupSelectButtonTheme? theme =
        PopupSelectButtonTheme.maybeOf(context);

    final resolved = defaults.copyWith(
      backgroundColor: theme?.backgroundColor,
      foregroundColor: theme?.foregroundColor,
      overlayColor: theme?.overlayColor,
      shadowColor: theme?.shadowColor,
      surfaceTintColor: theme?.surfaceTintColor,
      side: theme?.side,
      shape: theme?.shape,
      textStyle: theme?.textStyle,
      iconColor: theme?.iconColor,
      padding: theme?.padding,
      elevation: theme?.elevation,
      overlayStyle: theme?.overlayStyle,
      selectTheme: theme?.selectTheme,
    );

    final overlayStyle = widget.overlayStyle ?? resolved.overlayStyle;
    final effectiveSelectTheme = resolved.selectTheme;

    final localizations = SelectLocalizations.of(context);
    _controller.applyMultipleText = localizations?.multiple ?? 'Multiple';

    return SelectOverlayHost(
      controller: _controller,
      direction: widget.direction,
      style: overlayStyle,
      selectTheme: effectiveSelectTheme,
      minWidthFromTrigger: true,
      triggerChild: _buildButton(context, resolved),
    );
  }

  Widget _buildButton(BuildContext context, PopupSelectButtonTheme resolved) {
    final textTheme = Theme.of(context).textTheme;

    final backgroundColor = resolved.backgroundColor!;
    final foregroundColor = resolved.foregroundColor!;
    final elevation = resolved.elevation!;
    final side = resolved.side!;
    final baseShape = resolved.shape ??
        const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8.0)),
        );
    final shape = baseShape.copyWith(side: side);
    final BorderRadius inkBorderRadius = baseShape is RoundedRectangleBorder
        ? baseShape.borderRadius.resolve(TextDirection.ltr)
        : BorderRadius.circular(8.0);
    final textStyle = resolved.textStyle ?? textTheme.labelLarge!;
    final iconColor = resolved.iconColor ?? foregroundColor;
    final padding = resolved.padding ??
        const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0);
    final splash =
        resolved.overlayColor ?? foregroundColor.withValues(alpha: 0.12);

    final icon = widget.icon ?? const Icon(Icons.arrow_drop_down, size: 20);

    final labelText = _labelState.label ?? widget.label ?? '';

    final content = widget.child ??
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                labelText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4.0),
            RotationTransition(
              turns: Tween<double>(begin: 0.0, end: 0.5).animate(
                CurvedAnimation(
                  parent: _controller.overlayAnimation,
                  curve: Curves.easeOutCubic,
                ),
              ),
              child: IconTheme(
                data: IconThemeData(color: iconColor, size: 20),
                child: icon,
              ),
            ),
          ],
        );

    return Material(
      color: backgroundColor,
      elevation: elevation,
      shadowColor: resolved.shadowColor,
      surfaceTintColor: resolved.surfaceTintColor,
      shape: shape,
      type: widget.variant == PopupSelectButtonVariant.outlined
          ? MaterialType.transparency
          : MaterialType.button,
      child: InkWell(
        onTap: _handleTap,
        splashColor: splash,
        highlightColor: splash.withValues(alpha: 0.5),
        borderRadius: inkBorderRadius,
        child: Padding(
          padding: padding,
          child: DefaultTextStyle(
            style: textStyle.copyWith(color: foregroundColor),
            child: IconTheme(
              data: IconThemeData(color: iconColor),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}

class _PopupSelectButtonDefaults extends PopupSelectButtonTheme {
  _PopupSelectButtonDefaults(this.context, this.variant)
      : super(
          elevation: variant == PopupSelectButtonVariant.elevated ? 1.0 : 0.0,
        );

  final BuildContext context;
  final PopupSelectButtonVariant variant;

  late final ColorScheme _colors = Theme.of(context).colorScheme;
  late final TextTheme _textTheme = Theme.of(context).textTheme;

  @override
  Color? get backgroundColor {
    switch (variant) {
      case PopupSelectButtonVariant.elevated:
        return _colors.surfaceContainerLow;
      case PopupSelectButtonVariant.filled:
        return _colors.primary;
      case PopupSelectButtonVariant.outlined:
        return Colors.transparent;
    }
  }

  @override
  Color? get foregroundColor {
    switch (variant) {
      case PopupSelectButtonVariant.elevated:
        return _colors.onSurface;
      case PopupSelectButtonVariant.filled:
        return _colors.onPrimary;
      case PopupSelectButtonVariant.outlined:
        return _colors.primary;
    }
  }

  @override
  Color? get shadowColor => _colors.shadow;

  @override
  Color? get surfaceTintColor =>
      variant == PopupSelectButtonVariant.elevated ? _colors.surfaceTint : null;

  @override
  BorderSide? get side {
    if (variant == PopupSelectButtonVariant.outlined) {
      return BorderSide(color: _colors.outline);
    }
    return BorderSide.none;
  }

  @override
  OutlinedBorder? get shape => const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8.0)),
      );

  @override
  TextStyle? get textStyle => _textTheme.labelLarge;

  @override
  Color? get iconColor => foregroundColor;

  @override
  EdgeInsetsGeometry? get padding =>
      const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0);

  @override
  Color? get overlayColor => foregroundColor?.withValues(alpha: 0.12);
}
