import 'package:flutter/material.dart';

/// Optional header shown above a select panel.
///
/// Mirrors [ListTile]: an optional [leading] widget on the left, the optional
/// [title] expanded in the middle and an optional [trailing] widget on the
/// right. The title alignment is controlled by [centerTitle], which behaves
/// like [AppBar.centerTitle].
///
/// Like [AppBar], the header content has a fixed toolbar height
/// ([AppBarTheme.toolbarHeight], defaulting to [kToolbarHeight]) so
/// [leading] and [trailing] (e.g. a 48x48 [CloseButton]) are vertically
/// centered within the toolbar instead of growing the header.
///
/// Shared by both [showSelect] (modal dialog) and
/// [showModalBottomSelect] (bottom sheet) so their headers stay visually and
/// behaviorally identical.
class SelectHeader extends StatelessWidget {
  const SelectHeader({
    super.key,
    this.title,
    this.leading,
    this.trailing,
    this.centerTitle,
  });

  /// The title rendered in the middle of the header.
  ///
  /// When null, only [leading] and/or [trailing] are shown (there is nothing
  /// to center, so [centerTitle] is ignored).
  final Widget? title;

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
    final titleWidget = (title == null || textStyle == null)
        ? null
        : DefaultTextStyle(
            style: textStyle,
            child: title!,
          );
    // Without a title there is nothing to center; only [leading] and/or
    // [trailing] are shown, laid out from the edges inward.
    final isCentered = titleWidget != null &&
        _getEffectiveCenterTitle(theme, theme.appBarTheme);

    // Horizontal gap between [leading]/[trailing] and the [title].
    const horizontalGap = 12.0;

    // Like [AppBar], give the header content a fixed toolbar height so that
    // [leading] / [trailing] never grow the header: they receive the toolbar
    // height as their maximum height and are vertically centered within it,
    // exactly like [AppBar.leading] / [AppBar.actions].
    final double toolbarHeight =
        theme.appBarTheme.toolbarHeight ?? kToolbarHeight;

    final Widget content;
    if (!isCentered) {
      // Left-aligned title flows naturally after [leading] inside a [Row] so
      // they can never overlap; [trailing] sits at the right edge.
      content = Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: horizontalGap),
          ],
          if (titleWidget != null)
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: titleWidget,
              ),
            )
          else
            const Spacer(),
          if (trailing != null) ...[
            const SizedBox(width: horizontalGap),
            trailing!,
          ],
        ],
      );
    } else {
      // To keep the [title] truly centered across the full header width even
      // when [leading] and [trailing] are asymmetrical, use an outer [Stack]:
      // [leading] and [trailing] are absolutely positioned at the edges while
      // a full-width [Row] carries the [title]. A [Positioned.fill] title
      // would instead force the [Stack] to expand to its parent's (possibly
      // unbounded) height, which crashes when the header lives in a
      // `mainAxisSize: min` [Column] (e.g. inside the dialog / bottom sheet).
      content = Stack(
        alignment: Alignment.center,
        children: [
          // Non-positioned child: spans the full width so the title centers
          // relative to the whole header, not to the gap between [leading]
          // and [trailing].
          Row(
            children: [
              Expanded(child: Center(child: titleWidget)),
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
      );
    }

    // The header's total height matches [AppBar] exactly: [toolbarHeight]
    // already includes the vertical spacing, so no extra vertical padding is
    // added on top of it.
    return Container(
      height: toolbarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: content,
    );
  }
}
