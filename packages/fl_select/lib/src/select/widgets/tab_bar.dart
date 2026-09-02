import 'package:flutter/material.dart';

import '../select_entry.dart';
import '../select_theme.dart';
import '../select_theme_data.dart';
import 'badge.dart';
import 'constants.dart';
import 'skeleton_view.dart';
import 'tab_bar_theme.dart';

enum SelectTabBarIndicatorSize {
  tab,
  label,
}

/// The fixed height of [SelectTabBar], matching [TabBar]'s text-only tab
/// height (`_kTabHeight`).
const double _kTabBarHeight = 48.0;

/// Horizontal padding applied inside every tab, around its label.
const double _kTabHorizontalPadding = 4.5;

class SelectTabBar extends StatefulWidget {
  const SelectTabBar({
    super.key,
    required this.entries,
    required this.selectedCategories,
    required this.focusedIndex,
    this.padding,
    this.isScrollable = false,
    this.backgroundColor,
    this.selectedColor,
    this.labelStyle,
    this.selectedLabelStyle,
    this.indicatorColor,
    this.indicatorHeight,
    this.indicatorPadding,
    this.indicatorSize,
    this.indicatorAnimationDuration,
    required this.onChanged,
  });

  /// The category entries to display as tabs in this bar.
  ///
  /// Each entry renders a tab UI and must be a [SelectCategoryEntry]; the
  /// number of tabs equals the length of this list.
  final List<SelectEntry> entries;

  /// The set of categories that hold a "real" selection, i.e. at least one
  /// selected child that is not the "Any" placeholder.
  ///
  /// A tab renders a small badge dot in the top-right corner of its label when
  /// its entry is contained in this set. This mirrors [SelectSideBar]'s
  /// `selectedCategories`: the badge is driven by the selection, not by
  /// [focusedIndex], so a tab stays badged while another tab is focused.
  final SelectEntries selectedCategories;

  /// The index of the tab that is currently active.
  ///
  /// The tab at this index is rendered as selected — its label uses
  /// [selectedLabelStyle] and its indicator is shown — and, when
  /// [isScrollable] is true, a change of this index scrolls the newly focused
  /// tab to the center of the bar.
  final int focusedIndex;

  /// The padding around the whole tab bar.
  ///
  /// If null, [SelectTabBarTheme.padding] is used. If that is also null, the
  /// value is [EdgeInsets.zero]. When [isScrollable] is true, this padding is
  /// ignored in favor of the inner scroll view's padding.
  final EdgeInsetsGeometry? padding;

  /// Whether this tab bar can be scrolled horizontally.
  ///
  /// If true, each tab is sized to fit its own content and the whole bar
  /// becomes horizontally scrollable. Tapping a tab — or focusing one through
  /// [focusedIndex] — scrolls it to the center, matching Flutter's [TabBar]
  /// with `isScrollable: true` (a tab wider than the viewport aligns to the
  /// leading edge, and the target offset is clamped at both ends). If false
  /// (the default), the tabs are expanded to divide the available width
  /// equally.
  final bool isScrollable;

  /// The color of the tab bar itself.
  ///
  /// If null, [SelectTabBarTheme.backgroundColor] is used. If that is also
  /// null, the value is [SelectThemeData.backgroundColor].
  final Color? backgroundColor;

  /// The color of the tab labels and indicator when a tab is selected.
  ///
  /// If null, [SelectTabBarTheme.selectedColor] is used. If that is also
  /// null, the value is [SelectThemeData.selectedColor].
  final Color? selectedColor;

  /// The text style of the tab labels when not selected.
  ///
  /// If null, [SelectTabBarTheme.labelStyle] is used. If that is also null,
  /// the value is [TextTheme.titleSmall].
  final TextStyle? labelStyle;

  /// The text style of the tab labels when selected.
  ///
  /// If null, [SelectTabBarTheme.selectedLabelStyle] is used. If that is also
  /// null, the value defaults to [TextTheme.titleSmall] colored with
  /// [selectedColor].
  final TextStyle? selectedLabelStyle;

  /// The color of the line that appears below the selected tab.
  ///
  /// If null, [SelectTabBarTheme.indicatorColor] is used. If that is also
  /// null, the value is [selectedColor].
  final Color? indicatorColor;

  /// The thickness of the selected tab indicator line.
  ///
  /// If null, [SelectTabBarTheme.indicatorHeight] is used. If that is also
  /// null, the default is 2.0.
  final double? indicatorHeight;

  /// The padding used to inset the indicator from the tab edges.
  ///
  /// If null, [SelectTabBarTheme.indicatorPadding] is used. If that is also
  /// null, the value is [EdgeInsets.zero].
  final EdgeInsetsGeometry? indicatorPadding;

  /// Defines how the selected tab indicator's size is computed.
  ///
  /// If null, [SelectTabBarTheme.indicatorSize] is used. If that is also
  /// null, the default is [SelectTabBarIndicatorSize.tab].
  final SelectTabBarIndicatorSize? indicatorSize;

  /// The duration of the indicator's size animation when the selection changes.
  ///
  /// If null, [SelectTabBarTheme.indicatorAnimationDuration] is used. If that
  /// is also null, the default is 200ms.
  final Duration? indicatorAnimationDuration;

  /// Called when a tab is tapped.
  ///
  /// The callback receives the tapped tab's index and its [SelectEntry].
  final OnChanged onChanged;

  @override
  State<SelectTabBar> createState() => _SelectTabBarState();
}

class _SelectTabBarState extends State<SelectTabBar> {
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _tabKeys = {};
  int? _previousFocusedIndex;

  @override
  void initState() {
    super.initState();
    _syncTabKeys();
    _previousFocusedIndex = widget.focusedIndex;
  }

  @override
  void didUpdateWidget(covariant SelectTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncTabKeys();
    if (_previousFocusedIndex != widget.focusedIndex) {
      _previousFocusedIndex = widget.focusedIndex;
      // Covers programmatic category switches; taps scroll in [_handleTap].
      _scrollToTab(widget.focusedIndex);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Keeps [_tabKeys] in sync with the current number of tabs, reusing
  /// existing keys so tab rects stay measurable across rebuilds.
  void _syncTabKeys() {
    if (!widget.isScrollable) {
      _tabKeys.clear();
      return;
    }
    for (int i = 0; i < widget.entries.length; i++) {
      _tabKeys.putIfAbsent(i, () => GlobalKey());
    }
    _tabKeys.removeWhere((index, _) => index >= widget.entries.length);
  }

  void _handleTap(int index, SelectEntry entry) {
    // Mark as handled so the didUpdateWidget pass triggered by onChanged
    // doesn't scroll a second time.
    _previousFocusedIndex = index;
    widget.onChanged(index, entry);
    _scrollToTab(index);
  }

  /// Scrolls the scrollable bar so the tab at [index] is centered.
  ///
  /// Matches Flutter [TabBar]'s behavior: a tab narrower than the viewport is
  /// centered, a wider one aligns to the leading edge, and the target offset
  /// is clamped at the scroll extents (RTL-safe).
  Future<void> _scrollToTab(int index) async {
    if (!widget.isScrollable) return;
    if (!_scrollController.hasClients) {
      // The bar may not be laid out yet; retry once after the current frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _scrollToTab(index);
        }
      });
      return;
    }
    final RenderObject? object =
        _tabKeys[index]?.currentContext?.findRenderObject();
    if (object == null) return;
    await _scrollController.position.ensureVisible(
      object,
      alignment: 0.5,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  double _measureLabelWidth(
      BuildContext context, String label, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: label, style: style),
      textDirection: Directionality.of(context),
      maxLines: 1,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    return painter.width;
  }

  @override
  Widget build(BuildContext context) {
    final SelectTabBarTheme defaults = _SelectTabBarDefaults(context);
    final theme = SelectTabBarTheme.of(context);

    final effectivePadding =
        widget.padding ?? theme.padding ?? defaults.padding!;
    final containerPadding =
        widget.isScrollable ? EdgeInsets.zero : effectivePadding;

    final effectiveBackgroundColor = widget.backgroundColor ??
        theme.backgroundColor ??
        defaults.backgroundColor!;

    final effectiveSelectedColor =
        widget.selectedColor ?? theme.selectedColor ?? defaults.selectedColor!;

    final effectiveLabelStyle =
        widget.labelStyle ?? theme.labelStyle ?? defaults.labelStyle!;

    final effectiveSelectedLabelStyle = widget.selectedLabelStyle ??
        theme.selectedLabelStyle ??
        defaults.selectedLabelStyle!;

    final effectiveIndicatorColor = widget.indicatorColor ??
        theme.indicatorColor ??
        defaults.indicatorColor!;

    final effectiveIndicatorHeight = widget.indicatorHeight ??
        theme.indicatorHeight ??
        defaults.indicatorHeight!;

    final effectiveIndicatorPadding = widget.indicatorPadding ??
        theme.indicatorPadding ??
        defaults.indicatorPadding!;

    final effectiveIndicatorSize =
        widget.indicatorSize ?? theme.indicatorSize ?? defaults.indicatorSize!;

    final effectiveIndicatorAnimationDuration =
        widget.indicatorAnimationDuration ??
            theme.indicatorAnimationDuration ??
            defaults.indicatorAnimationDuration!;

    final tabs = List<Widget>.generate(widget.entries.length, (int index) {
      final entry = widget.entries[index] as SelectCategoryEntry;
      // The active appearance follows [focusedIndex], mirroring
      // [SelectSideBar]; [selectedCategories] only drives the badge, so a tab
      // can be badged while another one is active.
      final selected = index == widget.focusedIndex;
      final label = entry.name ?? '';

      Widget tab = _Tab(
        label: label,
        isScrollable: widget.isScrollable,
        selected: selected,
        showBadge: widget.selectedCategories.contains(entry),
        badgeColor: effectiveSelectedColor,
        padding: effectivePadding,
        selectedColor: effectiveSelectedColor,
        labelStyle:
            selected ? effectiveSelectedLabelStyle : effectiveLabelStyle,
        indicatorColor: effectiveIndicatorColor,
        indicatorHeight: effectiveIndicatorHeight,
        indicatorPadding: effectiveIndicatorPadding,
        indicatorSize: effectiveIndicatorSize,
        indicatorAnimationDuration: effectiveIndicatorAnimationDuration,
        onTap: () => _handleTap(index, entry),
      );

      if (widget.isScrollable) {
        final double labelWidth =
            _measureLabelWidth(context, label, effectiveLabelStyle);
        tab = SizedBox(
          width: labelWidth + _kTabHorizontalPadding * 2,
          child: tab,
        );
        tab = KeyedSubtree(key: _tabKeys[index], child: tab);
      } else {
        tab = Expanded(child: tab);
      }

      return tab;
    });

    final row = Row(
      mainAxisSize: widget.isScrollable ? MainAxisSize.min : MainAxisSize.max,
      // Stretch the tabs to the bar's fixed height so each tab's tap target
      // covers the full height, like [TabBar].
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: tabs,
    );

    return Container(
      // Match [TabBar]'s total height (48 for text-only tabs) so the bar is
      // independent of the label font size / text scale.
      height: _kTabBarHeight,
      padding: containerPadding,
      color: effectiveBackgroundColor,
      child: widget.isScrollable
          ? ScrollConfiguration(
              behavior:
                  ScrollConfiguration.of(context).copyWith(overscroll: false),
              child: SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                padding: widget.padding,
                child: row,
              ),
            )
          : row,
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.labelStyle,
    required this.isScrollable,
    required this.selected,
    required this.showBadge,
    this.badgeColor,
    required this.padding,
    required this.selectedColor,
    required this.indicatorColor,
    required this.indicatorHeight,
    required this.indicatorPadding,
    required this.indicatorSize,
    required this.indicatorAnimationDuration,
    required this.onTap,
  });

  final String label;

  final TextStyle labelStyle;

  final bool selected;

  final bool isScrollable;

  /// Whether a badge dot is rendered in the top-right corner of the label.
  ///
  /// Driven by [SelectTabBar.selectedCategories]; it is independent of
  /// [selected] so a tab can be badged while another one is active.
  final bool showBadge;

  /// The color of the badge dot rendered when [showBadge] is true.
  ///
  /// When null, [selectedColor] is used, matching [SelectSideBar]'s badge.
  final Color? badgeColor;

  final EdgeInsetsGeometry padding;

  final Color? selectedColor;

  final Color indicatorColor;

  final double indicatorHeight;

  final EdgeInsetsGeometry indicatorPadding;

  final SelectTabBarIndicatorSize indicatorSize;

  final Duration indicatorAnimationDuration;

  final GestureTapCallback onTap;

  double _measureLabelWidth(
      BuildContext context, String label, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: label, style: style),
      textDirection: Directionality.of(context),
      maxLines: 1,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    return painter.width;
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = labelStyle.fontSize ?? 14;
    return InkWell(
      onTap: onTap,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final resolvedIndicatorPadding =
              indicatorPadding.resolve(Directionality.of(context));

          final double maxIndicatorWidth =
              (constraints.maxWidth - resolvedIndicatorPadding.horizontal)
                  .clamp(0.0, double.infinity)
                  .toDouble();

          final double labelIndicatorWidth = _measureLabelWidth(
            context,
            label,
            labelStyle,
          ).clamp(0.0, maxIndicatorWidth).toDouble();

          final double indicatorWidth =
              indicatorSize == SelectTabBarIndicatorSize.label
                  ? labelIndicatorWidth
                  : maxIndicatorWidth;

          // Right edge of the (possibly ellipsized) label, relative to this
          // tab's own box: the label is centered inside the horizontal
          // padding, so its right edge sits half of the leftover space away
          // from the center. Used to hang the badge off that corner.
          final double innerWidth =
              (constraints.maxWidth - _kTabHorizontalPadding * 2)
                  .clamp(0.0, double.infinity)
                  .toDouble();
          final double visibleLabelWidth = _measureLabelWidth(
            context,
            label,
            labelStyle,
          ).clamp(0.0, innerWidth).toDouble();
          final double labelRight =
              _kTabHorizontalPadding + (innerWidth + visibleLabelWidth) / 2;

          return Stack(
            // `expand` forwards tight constraints to the tab content, so the
            // tab keeps the exact layout — and the full-width/full-height tap
            // target — it had before the badge was introduced.
            fit: StackFit.expand,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: _kTabHorizontalPadding),
                // Like [TabBar]'s underline indicator: the label centers in
                // the space above the indicator, and the indicator sits at the
                // bottom edge of the (fixed-height) tab.
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: Text(
                          label,
                          style: labelStyle,
                          strutStyle: StrutStyle(
                            fontSize: fontSize,
                            height: 20 / fontSize,
                            forceStrutHeight: true,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    Padding(
                      padding: indicatorPadding,
                      child: Align(
                        alignment: Alignment.center,
                        child: AnimatedContainer(
                          duration: indicatorAnimationDuration,
                          curve: Curves.easeOut,
                          height: indicatorHeight,
                          width: selected ? indicatorWidth : 0,
                          decoration: BoxDecoration(
                            color: indicatorColor,
                            borderRadius:
                                BorderRadius.circular(indicatorHeight / 2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (showBadge)
                Positioned(
                  top: 8.0,
                  // The badge box is 10 wide and its 6-wide dot is centered
                  // in it, so this offset puts the dot's center 2px outside
                  // the label's top-right corner. Clamped so a label that
                  // fills the tab keeps its badge inside the tab.
                  right: (constraints.maxWidth - labelRight - 7.0)
                      .clamp(0.0, double.infinity)
                      .toDouble(),
                  child: SelectBadge(color: badgeColor ?? selectedColor),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Loading skeleton for [SelectTabBar].
class SelectTabBarSkeleton extends StatelessWidget {
  const SelectTabBarSkeleton({
    super.key,
    this.padding,
    this.backgroundColor,
  });

  /// The padding around the skeleton.
  ///
  /// If null, [SelectTabBarTheme.padding] is used. If that is also null, the
  /// value is [EdgeInsets.zero].
  final EdgeInsetsGeometry? padding;

  /// The background color of the skeleton.
  ///
  /// If null, [SelectTabBarTheme.backgroundColor] is used. If that is also
  /// null, the value is [SelectThemeData.backgroundColor].
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final SelectTabBarTheme defaults = _SelectTabBarDefaults(context);
    final theme = SelectTabBarTheme.of(context);

    final effectivePadding = padding ?? theme.padding ?? defaults.padding!;

    final effectiveBackgroundColor =
        backgroundColor ?? theme.backgroundColor ?? defaults.backgroundColor!;

    return Container(
      padding: effectivePadding,
      color: effectiveBackgroundColor,
      child: SkeletonView(
        child: Row(
          children: [
            Expanded(
              child: SkeletonTile(
                width: double.infinity,
                height: _kTabBarHeight - 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 36),
            Expanded(
              child: SkeletonTile(
                width: double.infinity,
                height: _kTabBarHeight - 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectTabBarDefaults extends SelectTabBarTheme {
  _SelectTabBarDefaults(this.context) : super();

  final BuildContext context;
  late final SelectThemeData _theme = SelectTheme.of(context);
  late final TextTheme _textTheme = Theme.of(context).textTheme;

  @override
  Color? get backgroundColor => _theme.backgroundColor;

  @override
  EdgeInsetsGeometry? get padding => EdgeInsets.zero;

  @override
  Color? get selectedColor => _theme.selectedColor;

  @override
  TextStyle? get labelStyle => _textTheme.titleSmall;

  @override
  TextStyle? get selectedLabelStyle =>
      _textTheme.titleSmall?.copyWith(color: selectedColor);

  @override
  Color? get indicatorColor => selectedColor;

  @override
  double? get indicatorHeight => 2;

  @override
  EdgeInsetsGeometry? get indicatorPadding => EdgeInsets.zero;

  @override
  SelectTabBarIndicatorSize? get indicatorSize => SelectTabBarIndicatorSize.tab;

  @override
  Duration? get indicatorAnimationDuration => const Duration(milliseconds: 200);
}
