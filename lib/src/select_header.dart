import 'package:flutter/material.dart';

/// Optional header shown above a select panel.
///
/// Mirrors [ListTile]: an optional [leading] widget on the left, the [title]
/// expanded in the middle and an optional [trailing] widget on the right. The
/// title alignment is controlled by [centerTitle], which behaves like
/// [AppBar.centerTitle].
///
/// Shared by both [showSelect] (modal dialog) and
/// [showModalBottomSelect] (bottom sheet) so their headers stay visually and
/// behaviorally identical.
class SelectHeader extends StatelessWidget {
  const SelectHeader({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
    this.centerTitle,
  });

  /// The title rendered in the middle of the header.
  final Widget title;

  /// An optional widget rendered on the left of the [title].
  final Widget? leading;

  /// An optional widget rendered on the right of the [title].
  final Widget? trailing;

  /// Whether the [title] is centered.
  ///
  /// When null, falls back to [AppBarTheme.centerTitle] and then to a
  /// platform-dependent default, mirroring [AppBar.centerTitle].
  final bool? centerTitle;

  /// Resolves the effective [centerTitle] value.
  ///
  /// Mirrors [AppBar]'s resolution: explicit [centerTitle] wins, then
  /// [AppBarTheme.centerTitle], then a platform-dependent default. On iOS /
  /// macOS the title is centered; everywhere else it is left-aligned.
  bool _getEffectiveCenterTitle(ThemeData theme, AppBarThemeData appBarTheme) {
    bool platformCenter() {
      switch (theme.platform) {
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          return false;
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
          return true;
      }
    }

    return centerTitle ?? appBarTheme.centerTitle ?? platformCenter();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.titleLarge ?? theme.textTheme.titleMedium;
    final titleWidget = DefaultTextStyle(
      style: textStyle!,
      child: title,
    );
    final isCentered = _getEffectiveCenterTitle(theme, theme.appBarTheme);

    // To keep the [title] truly centered across the full header width even
    // when [leading] and [trailing] are asymmetrical, use an outer [Stack]:
    // [leading] and [trailing] are absolutely positioned at the edges while a
    // full-width [Row] carries the [title]. A [Positioned.fill] title would
    // instead force the [Stack] to expand to its parent's (possibly unbounded)
    // height, which crashes when the header lives in a `mainAxisSize: min`
    // [Column] (e.g. inside the dialog / bottom sheet).
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Non-positioned child: it determines the [Stack]'s size (the title
          // height) and spans the full width so the title centers relative to
          // the whole header, not to the gap between [leading] and [trailing].
          Row(
            children: [
              Expanded(
                child: isCentered
                    ? Center(child: titleWidget)
                    : Align(
                        alignment: Alignment.centerLeft,
                        child: titleWidget,
                      ),
              ),
            ],
          ),
          if (leading != null)
            Positioned(
              left: 0,
              child: leading!,
            ),
          if (trailing != null)
            Positioned(
              right: 0,
              child: trailing!,
            ),
        ],
      ),
    );
  }
}
