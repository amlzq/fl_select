import 'package:flutter/material.dart';

import 'search_bar_theme.dart';

/// A search bar widget used inside the select panel to filter entries.
///
/// Shows a text field with a search icon and an optional clear button. The
/// clear button is visible only when the text field is non-empty.
///
/// Styling is resolved from [theme] when provided, otherwise from the
/// surrounding [SelectSearchBarTheme], with Material defaults as fallback.
class SelectSearchBar extends StatefulWidget {
  const SelectSearchBar({
    super.key,
    required this.controller,
    this.focusNode,
    this.hintText,
    this.onChanged,
    this.theme,
    this.decoration,
  });

  /// Controls the text being edited.
  final TextEditingController controller;

  /// Optional focus node for the text field.
  final FocusNode? focusNode;

  /// Placeholder text shown when the input is empty.
  final String? hintText;

  /// Called when the text changes.
  final ValueChanged<String>? onChanged;

  /// Theme overrides for this search bar.
  ///
  /// When `null`, the surrounding [SelectSearchBarTheme] is used.
  final SelectSearchBarTheme? theme;

  /// Optional decoration override for the text field.
  ///
  /// When provided, it takes precedence over [theme] values.
  final InputDecoration? decoration;

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
    final searchBarTheme = widget.theme ?? SelectSearchBarTheme.of(context);

    final padding = searchBarTheme.padding ?? defaults.padding!;
    final borderRadius = searchBarTheme.borderRadius ?? defaults.borderRadius!;
    final borderWidth = searchBarTheme.borderWidth ?? defaults.borderWidth!;
    final enabledBorderColor =
        searchBarTheme.enabledBorderColor ?? defaults.enabledBorderColor!;
    final focusedBorderColor =
        searchBarTheme.focusedBorderColor ?? defaults.focusedBorderColor!;
    final iconColor = searchBarTheme.iconColor ?? defaults.iconColor!;
    final iconSize = searchBarTheme.iconSize ?? defaults.iconSize!;
    final hintStyle = searchBarTheme.hintStyle ?? defaults.hintStyle!;
    final textStyle = searchBarTheme.textStyle ?? defaults.textStyle!;
    final contentPadding =
        searchBarTheme.contentPadding ?? defaults.contentPadding!;

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: BorderSide(color: enabledBorderColor, width: borderWidth),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: BorderSide(color: focusedBorderColor, width: borderWidth),
    );

    return Padding(
      padding: padding,
      child: ValueListenableBuilder(
        valueListenable: widget.controller,
        builder: (context, TextEditingValue value, _) {
          final hasText = value.text.isNotEmpty;
          return TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            onChanged: widget.onChanged,
            style: textStyle,
            decoration: widget.decoration ??
                InputDecoration(
                  hintText: widget.hintText ?? 'Search',
                  hintStyle: hintStyle,
                  prefixIcon: Icon(Icons.search, size: iconSize),
                  prefixIconColor: iconColor,
                  suffixIcon: hasText
                      ? IconButton(
                          icon: Icon(Icons.close,
                              size: iconSize > 0 ? iconSize - 2 : iconSize),
                          onPressed: () {
                            widget.controller.clear();
                            widget.onChanged?.call('');
                          },
                        )
                      : null,
                  suffixIconColor: iconColor,
                  isDense: true,
                  filled: searchBarTheme.filled,
                  fillColor: searchBarTheme.fillColor,
                  contentPadding: contentPadding,
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
  TextStyle? get hintStyle => _theme.textTheme.bodyMedium
      ?.copyWith(color: _theme.colorScheme.onSurfaceVariant);

  @override
  TextStyle? get textStyle => _theme.textTheme.bodyMedium;
}
