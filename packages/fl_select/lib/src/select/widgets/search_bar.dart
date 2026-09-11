import 'package:flutter/material.dart';

import '../../i18n/select_localizations.dart';
import 'search_bar_theme.dart';

/// A search bar widget used inside the select panel to filter entries.
///
/// Shows a text field with a search icon and an optional clear button. The
/// clear button is visible only when the text field is non-empty.
///
/// This widget can be styled via [SelectSearchBarTheme] or per-instance
/// overrides.
class SelectSearchBar extends StatefulWidget {
  const SelectSearchBar({
    super.key,
    required this.controller,
    this.focusNode,
    this.hintText,
    this.onChanged,
    this.decoration,
    this.padding,
    this.contentPadding,
    this.borderRadius,
    this.filled,
    this.fillColor,
    this.enabledBorderColor,
    this.focusedBorderColor,
    this.borderWidth,
    this.hintStyle,
    this.textStyle,
    this.iconColor,
    this.iconSize,
  });

  /// Controls the text being edited.
  final TextEditingController controller;

  /// Optional focus node for the text field.
  final FocusNode? focusNode;

  /// Placeholder text shown when the input is empty.
  final String? hintText;

  /// Called when the text changes.
  final ValueChanged<String>? onChanged;

  /// Optional decoration override for the text field.
  ///
  /// When provided, it takes precedence over the theme values.
  final InputDecoration? decoration;

  /// The padding around the search bar.
  ///
  /// If null, the value from the surrounding [SelectSearchBarTheme] or the
  /// default is used.
  final EdgeInsetsGeometry? padding;

  /// The padding inside the text field.
  ///
  /// If null, the value from the surrounding [SelectSearchBarTheme] or the
  /// default is used.
  final EdgeInsetsGeometry? contentPadding;

  /// The corner radius of the text field border.
  ///
  /// If null, the value from the surrounding [SelectSearchBarTheme] or the
  /// default is used.
  final double? borderRadius;

  /// Whether the text field is filled with [fillColor].
  ///
  /// If null, the value from the surrounding [SelectSearchBarTheme] or the
  /// default is used.
  final bool? filled;

  /// The fill color of the text field when [filled] is `true`.
  ///
  /// If null, the value from the surrounding [SelectSearchBarTheme] or the
  /// default is used.
  final Color? fillColor;

  /// The border color of the unfocused text field.
  ///
  /// If null, the value from the surrounding [SelectSearchBarTheme] or the
  /// default is used.
  final Color? enabledBorderColor;

  /// The border color of the focused text field.
  ///
  /// If null, the value from the surrounding [SelectSearchBarTheme] or the
  /// default is used.
  final Color? focusedBorderColor;

  /// The width of the text field border.
  ///
  /// If null, the value from the surrounding [SelectSearchBarTheme] or the
  /// default is used.
  final double? borderWidth;

  /// The text style of the hint shown when the input is empty.
  ///
  /// If null, the value from the surrounding [SelectSearchBarTheme] or the
  /// default is used.
  final TextStyle? hintStyle;

  /// The text style of the input text.
  ///
  /// If null, the value from the surrounding [SelectSearchBarTheme] or the
  /// default is used.
  final TextStyle? textStyle;

  /// The color of the search and clear icons.
  ///
  /// If null, the value from the surrounding [SelectSearchBarTheme] or the
  /// default is used.
  final Color? iconColor;

  /// The size of the search and clear icons.
  ///
  /// If null, the value from the surrounding [SelectSearchBarTheme] or the
  /// default is used.
  final double? iconSize;

  @override
  State<SelectSearchBar> createState() => _SelectSearchBarState();
}

class _SelectSearchBarState extends State<SelectSearchBar> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
  }

  @override
  void dispose() {
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SelectSearchBarTheme defaults = _SelectSearchBarDefaults(context);
    final theme = SelectSearchBarTheme.of(context);

    final effectivePadding =
        widget.padding ?? theme.padding ?? defaults.padding!;

    final effectiveContentPadding =
        widget.contentPadding ??
        theme.contentPadding ??
        defaults.contentPadding!;

    final effectiveBorderRadius =
        widget.borderRadius ?? theme.borderRadius ?? defaults.borderRadius!;

    final effectiveBorderWidth =
        widget.borderWidth ?? theme.borderWidth ?? defaults.borderWidth!;

    final effectiveEnabledBorderColor =
        widget.enabledBorderColor ??
        theme.enabledBorderColor ??
        defaults.enabledBorderColor!;

    final effectiveFocusedBorderColor =
        widget.focusedBorderColor ??
        theme.focusedBorderColor ??
        defaults.focusedBorderColor!;

    final effectiveIconColor =
        widget.iconColor ?? theme.iconColor ?? defaults.iconColor!;

    final effectiveIconSize =
        widget.iconSize ?? theme.iconSize ?? defaults.iconSize!;

    final effectiveHintStyle =
        widget.hintStyle ?? theme.hintStyle ?? defaults.hintStyle!;

    final effectiveTextStyle =
        widget.textStyle ?? theme.textStyle ?? defaults.textStyle!;

    final effectiveFilled = widget.filled ?? theme.filled;

    final effectiveFillColor = widget.fillColor ?? theme.fillColor;

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(effectiveBorderRadius),
      borderSide: BorderSide(
        color: effectiveEnabledBorderColor,
        width: effectiveBorderWidth,
      ),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(effectiveBorderRadius),
      borderSide: BorderSide(
        color: effectiveFocusedBorderColor,
        width: effectiveBorderWidth,
      ),
    );

    return Padding(
      padding: effectivePadding,
      child: ValueListenableBuilder(
        valueListenable: widget.controller,
        builder: (context, TextEditingValue value, _) {
          final hasText = value.text.isNotEmpty;
          return TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            onChanged: widget.onChanged,
            style: effectiveTextStyle,
            decoration:
                widget.decoration ??
                InputDecoration(
                  hintText:
                      widget.hintText ??
                      SelectLocalizations.of(context)?.search ??
                      'Search',
                  hintStyle: effectiveHintStyle,
                  prefixIcon: Icon(Icons.search, size: effectiveIconSize),
                  prefixIconColor: effectiveIconColor,
                  suffixIcon: hasText
                      ? IconButton(
                          icon: Icon(
                            Icons.close,
                            size: effectiveIconSize > 0
                                ? effectiveIconSize - 2
                                : effectiveIconSize,
                          ),
                          onPressed: () {
                            widget.controller.clear();
                            widget.onChanged?.call('');
                          },
                        )
                      : null,
                  suffixIconColor: effectiveIconColor,
                  isDense: true,
                  filled: effectiveFilled,
                  fillColor: effectiveFillColor,
                  contentPadding: effectiveContentPadding,
                  border: border,
                  enabledBorder: border,
                  focusedBorder: focusedBorder,
                ),
          );
        },
      ),
    );
  }
}

class _SelectSearchBarDefaults extends SelectSearchBarTheme {
  _SelectSearchBarDefaults(this.context) : super();

  final BuildContext context;
  late final ThemeData _theme = Theme.of(context);

  @override
  EdgeInsetsGeometry? get padding =>
      const EdgeInsets.symmetric(horizontal: 12, vertical: 8);

  @override
  EdgeInsetsGeometry? get contentPadding =>
      const EdgeInsets.symmetric(horizontal: 12, vertical: 8);

  @override
  double? get borderRadius => 8.0;

  @override
  double? get borderWidth => 1.0;

  @override
  Color? get enabledBorderColor => _theme.colorScheme.outlineVariant;

  @override
  Color? get focusedBorderColor => _theme.colorScheme.primary;

  @override
  Color? get iconColor => _theme.colorScheme.onSurfaceVariant;

  @override
  double? get iconSize => 20.0;

  @override
  TextStyle? get hintStyle => _theme.textTheme.bodyMedium?.copyWith(
    color: _theme.colorScheme.onSurfaceVariant,
  );

  @override
  TextStyle? get textStyle => _theme.textTheme.bodyMedium;
}
