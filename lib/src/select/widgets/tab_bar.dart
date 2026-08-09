import 'package:flutter/material.dart';

import '../select_entry.dart';
import '../select_theme.dart';
import '../select_theme_data.dart';
import 'constants.dart';
import 'skeleton_view.dart';
import 'tab_bar_theme.dart';

enum SelectTabBarIndicatorSize {
  tab,
  label,
}

class SelectTabBar extends StatelessWidget {
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

  /// The set of currently selected categories.
  ///
  /// A tab is rendered as selected when its entry is contained in this set,
  /// and its indicator is shown accordingly.
  final SelectEntries selectedCategories;

  /// The index of the tab that should be considered focused.
  ///
  /// Used to track which tab receives visual emphasis or keyboard focus; it
  /// does not by itself change the selected state.
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
  /// becomes horizontally scrollable. If false (the default), the tabs are
  /// expanded to divide the available width equally.
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

    final effectivePadding = padding ?? theme.padding ?? defaults.padding!;
    final containerPadding = isScrollable ? EdgeInsets.zero : effectivePadding;

    final effectiveBackgroundColor =
        backgroundColor ?? theme.backgroundColor ?? defaults.backgroundColor!;

    final effectiveSelectedColor =
        selectedColor ?? theme.selectedColor ?? defaults.selectedColor!;

    final effectiveLabelStyle =
        labelStyle ?? theme.labelStyle ?? defaults.labelStyle!;

    final effectiveSelectedLabelStyle = selectedLabelStyle ??
        theme.selectedLabelStyle ??
        defaults.selectedLabelStyle!;

    final effectiveIndicatorColor =
        indicatorColor ?? theme.indicatorColor ?? defaults.indicatorColor!;

    final effectiveIndicatorHeight =
        indicatorHeight ?? theme.indicatorHeight ?? defaults.indicatorHeight!;

    final effectiveIndicatorPadding = indicatorPadding ??
        theme.indicatorPadding ??
        defaults.indicatorPadding!;

    final effectiveIndicatorSize =
        indicatorSize ?? theme.indicatorSize ?? defaults.indicatorSize!;

    final effectiveIndicatorAnimationDuration = indicatorAnimationDuration ??
        theme.indicatorAnimationDuration ??
        defaults.indicatorAnimationDuration!;

    final tabs = List<Widget>.generate(entries.length, (int index) {
      final entry = entries[index] as SelectCategoryEntry;
      final selected = selectedCategories.contains(entry);
      final label = entry.name ?? '';

      Widget tab = _Tab(
        label: label,
        isScrollable: isScrollable,
        selected: selected,
        padding: effectivePadding,
        selectedColor: effectiveSelectedColor,
        labelStyle:
            selected ? effectiveSelectedLabelStyle : effectiveLabelStyle,
        indicatorColor: effectiveIndicatorColor,
        indicatorHeight: effectiveIndicatorHeight,
        indicatorPadding: effectiveIndicatorPadding,
        indicatorSize: effectiveIndicatorSize,
        indicatorAnimationDuration: effectiveIndicatorAnimationDuration,
        onTap: () => onChanged(index, entry),
      );

      if (isScrollable) {
        const double horizontalPadding = 4.5;
        final double labelWidth =
            _measureLabelWidth(context, label, effectiveLabelStyle);
        tab = SizedBox(width: labelWidth + horizontalPadding * 2, child: tab);
      } else {
        tab = Expanded(child: tab);
      }

      return tab;
    });

    final row = Row(
      mainAxisSize: isScrollable ? MainAxisSize.min : MainAxisSize.max,
      children: tabs,
    );

    return Container(
      padding: containerPadding,
      color: effectiveBackgroundColor,
      child: isScrollable
          ? ScrollConfiguration(
              behavior:
                  ScrollConfiguration.of(context).copyWith(overscroll: false),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                padding: padding,
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

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
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
                const SizedBox(height: 4),
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
                height: 40,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 36),
            Expanded(
              child: SkeletonTile(
                width: double.infinity,
                height: 40,
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
  SelectTabBarIndicatorSize? get indicatorSize =>
      SelectTabBarIndicatorSize.tab;

  @override
  Duration? get indicatorAnimationDuration => const Duration(milliseconds: 200);
}
