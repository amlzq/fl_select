import 'dart:math';

import 'package:flutter/material.dart';

import '../constants.dart';
import '../select_entry.dart';
import 'chip.dart';
import 'chip_bar_theme.dart';
import 'constants.dart';
import 'custom_range_host.dart';
import 'extensions.dart';
import 'field_tile_theme.dart';
import 'skeleton_view.dart';

/// Default height of the single-row [SelectChipBar].
const kSelectChipBarHeight = 44.0;

/// A single-row, horizontally scrollable chip bar for selecting among
/// sibling [SelectEntry] entries — the classic "quick filter" strip.
///
/// Renders all [SelectEntry] subtypes as chips using their [SelectEntry.name]
/// as the label. Selection state is provided by [selectedEntries] and user
/// interactions are reported via [onChanged]. The bar keeps a fixed height
/// ([kSelectChipBarHeight]) unless the title is stacked vertically or a
/// custom range field is present.
///
/// A custom range entry (a [SelectRangeEntry] with the special id `custom`,
/// see [SelectRangeEntryExt.isCustom]) placed first or last in [entries] is
/// not rendered as a chip. Instead it is rendered as a min/max input field
/// above or below the chip row, mirroring [SelectGridView]. The committed
/// value is reported through [onChanged] once both fields lose focus.
///
/// For the multi-row wrapped variant see [SelectWrapView].
class SelectChipBar extends StatefulWidget {
  const SelectChipBar({
    super.key,
    this.category,
    required this.entries,
    this.selectedEntries,
    this.selectionMode = SelectionMode.single,
    this.showTitle = true,
    this.spacing = 0.0,
    this.backgroundColor,
    this.padding,
    this.variant,
    this.fieldVariant,
    this.chipColor,
    this.selectedChipColor,
    this.labelStyle,
    this.selectedLabelStyle,
    this.toText = '-',
    required this.onChanged,
  });

  /// The parent [SelectEntry] whose [SelectEntry.name] is displayed as the
  /// bar's title when [showTitle] is true.
  final SelectEntry? category;

  /// The sibling entries to display as chips in the bar.
  final List<SelectEntry> entries;

  /// The set of currently selected entries.
  ///
  /// Chips whose entry is contained in this set are rendered in the selected
  /// state. When null, no chip is considered selected.
  final SelectEntries? selectedEntries;

  /// How many chips can be selected at the same time.
  ///
  /// Defaults to [SelectionMode.single].
  final SelectionMode selectionMode;

  /// Whether to show the category title.
  final bool showTitle;

  /// The width of the separators between chips in the row.
  ///
  /// Defaults to 0.0.
  final double spacing;

  /// The color of the chip bar's background.
  ///
  /// If null, the value from the surrounding [SelectChipBarTheme] or the
  /// default is used.
  final Color? backgroundColor;

  /// The padding around the chip bar's contents.
  ///
  /// Defaults to [SelectChipBarTheme.padding] or [EdgeInsets.zero].
  final EdgeInsetsGeometry? padding;

  /// The visual style of the chips.
  ///
  /// See [SelectChipVariant] for the available styles. Defaults to
  /// [SelectChipVariant.filled].
  final SelectChipVariant? variant;

  /// The visual variant of the custom range input field, if [entries]
  /// contains a custom range entry.
  final SelectFieldTileVariant? fieldVariant;

  /// The color of an unselected chip.
  ///
  /// When [variant] is [SelectChipVariant.filled] this is used as the chip's
  /// background color; otherwise it is used as the chip's border color.
  final Color? chipColor;

  /// The color of a selected chip.
  ///
  /// When [variant] is [SelectChipVariant.filled] this is used as the chip's
  /// background color; otherwise it is used as the chip's border and label
  /// color.
  final Color? selectedChipColor;

  /// The text style for an unselected chip's `label`.
  ///
  /// If null, the value from the surrounding [SelectChipBarTheme] or the
  /// default is used.
  final TextStyle? labelStyle;

  /// The text style for a selected chip's `label`.
  ///
  /// If null, the value from the surrounding [SelectChipBarTheme] or the
  /// default is used.
  final TextStyle? selectedLabelStyle;

  /// Text rendered between the two custom range input fields.
  ///
  /// Only used when [entries] contains a custom range entry. Defaults to
  /// `'-'`.
  final String toText;

  /// Called when the user taps a chip or commits the custom range input.
  ///
  /// The `index` of the tapped entry within [entries] and the tapped entry
  /// itself are passed to the callback.
  final OnChanged onChanged;

  @override
  State<SelectChipBar> createState() => _SelectChipBarState();
}

class _SelectChipBarState extends State<SelectChipBar> with CustomRangeHost {
  late SelectEntries _selectedEntries;

  @override
  List<SelectEntry> get customRangeEntries => widget.entries;

  @override
  SelectEntry? get customRangeCategory => widget.category;

  @override
  SelectEntries get customRangeSelectedEntries => _selectedEntries;

  @override
  String get customRangeToText => widget.toText;

  @override
  void notifyCustomRangeChanged(int index, SelectEntry entry) =>
      widget.onChanged(index, entry);

  void onChipTap(int index, SelectEntry entry) =>
      widget.onChanged(index, entry);

  @override
  void initState() {
    super.initState();

    _selectedEntries = widget.selectedEntries ?? {};

    initCustomRange();
  }

  @override
  void didUpdateWidget(covariant SelectChipBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    _selectedEntries = widget.selectedEntries ?? {};

    updateCustomRange(oldSelectedEntries: oldWidget.selectedEntries ?? {});
  }

  @override
  void dispose() {
    disposeCustomRange();

    super.dispose();
  }

  /// Handles a chip tap: the chip's selection replaces any in-progress
  /// custom range input, then [onChipTap] forwards the tap.
  void handleChipTap(int index, SelectEntry item) {
    clearCustomRangeInput();
    onChipTap(index, item);
  }

  @override
  Widget build(BuildContext context) {
    final theme = SelectChipBarTheme.of(context);

    final effectiveVariant =
        widget.variant ?? theme.variant ?? SelectChipVariant.filled;

    final defaults = SelectChipBarDefaults(context, effectiveVariant);

    final effectiveBackgroundColor =
        widget.backgroundColor ??
        theme.backgroundColor ??
        defaults.backgroundColor!;

    final effectivePadding =
        widget.padding ?? theme.padding ?? defaults.padding!;

    final effectiveChipColor =
        widget.chipColor ?? theme.chipColor ?? defaults.chipColor!;

    final effectiveSelectedChipColor =
        widget.selectedChipColor ??
        theme.selectedChipColor ??
        defaults.selectedChipColor!;

    final selectedTextColor = SelectChipDefaults.selectedTextColor(
      effectiveVariant,
      effectiveSelectedChipColor,
    );

    final effectiveLabelStyle =
        (widget.labelStyle ?? theme.labelStyle ?? defaults.labelStyle!)
            .copyWith(inherit: true);

    final effectiveSelectedLabelStyle =
        (widget.selectedLabelStyle ??
                theme.selectedLabelStyle ??
                defaults.selectedLabelStyle!)
            .copyWith(inherit: true, color: selectedTextColor);

    final chipGroup = Scrollbar(
      child: SingleChildScrollView(
        padding: EdgeInsets.zero,
        physics: const ClampingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            if (firstCustomRange != null)
              buildCustomRangeFieldTile(
                isHeader: true,
                padding: const EdgeInsets.only(bottom: 10.0),
                variant: widget.fieldVariant,
              ),
            for (final entry in customRangeEntries.asMap().entries)
              if (testNotCustomItem(entry.value))
                () {
                  final index = entry.key;
                  final item = entry.value;
                  final selected = customRangeSelectedEntries.contains(item);
                  return SelectChip(
                    label: item.name ?? '',
                    selected: selected,
                    variant: effectiveVariant,
                    color: effectiveChipColor,
                    selectedColor: effectiveSelectedChipColor,
                    labelStyle: effectiveLabelStyle,
                    selectedLabelStyle: effectiveSelectedLabelStyle,
                    enabled: item.enabled,
                    onTap: () => handleChipTap(index, item),
                  );
                }(),
            if (lastCustomRange != null)
              buildCustomRangeFieldTile(
                isHeader: false,
                padding: const EdgeInsets.only(top: 10.0),
                variant: widget.fieldVariant,
              ),
          ].separateWith(SizedBox(width: widget.spacing)),
        ),
      ),
    );

    // A custom range entry grows the bar above its fixed height.
    final isFixedHeight = !hasCustomRange;

    final showTitle = widget.showTitle && widget.category?.name != null;

    return Container(
      height: isFixedHeight ? kSelectChipBarHeight : null,
      color: effectiveBackgroundColor,
      padding: effectivePadding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showTitle)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: DefaultTextStyle.merge(
                style:
                    Theme.of(context).textTheme.titleSmall ??
                    const TextStyle(fontSize: 16),
                child: Text(widget.category?.name ?? ''),
              ),
            ),
          Expanded(child: chipGroup),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}

/// Theme defaults for [SelectChipBar].
///
/// The chip visuals come from [SelectChipDefaults] — the defaults of the
/// [SelectChip] item that both chip views render — so the single-row bar and
/// the wrap form cannot drift apart. The bar's own container defaults stay
/// here. This class only exposes them through the [SelectChipBarTheme]
/// interface.
///
/// Not part of the package's public API surface; visible only because the
/// theme resolution happens in the view's library.
class SelectChipBarDefaults extends SelectChipBarTheme {
  SelectChipBarDefaults(this.context, [SelectChipVariant? variant])
    : super(variant: variant);

  final BuildContext context;

  /// The shared defaults of the [SelectChip] item.
  late final SelectChipDefaults _chip = SelectChipDefaults(context, variant);

  @override
  Color? get backgroundColor => Colors.transparent;

  @override
  EdgeInsetsGeometry? get padding => EdgeInsets.zero;

  @override
  Color? get chipColor => _chip.chipColor;

  @override
  Color? get selectedChipColor => _chip.selectedChipColor;

  @override
  TextStyle? get labelStyle => _chip.labelStyle;

  @override
  TextStyle? get selectedLabelStyle => _chip.selectedLabelStyle;
}

/// Loading skeleton for [SelectChipBar].
///
/// Renders [itemCount] placeholder chips shaped like real chips (see
/// [SelectChip]) in a single non-wrapping row plus an optional title
/// placeholder, mirroring the layout that [SelectChipBar] produces for the
/// same arguments.
class SelectChipBarSkeleton extends StatelessWidget {
  const SelectChipBarSkeleton({
    super.key,
    this.itemCount = 4,
    this.showTitle = true,
    this.spacing = 0.0,
    this.backgroundColor,
    this.padding,
  });

  /// The number of placeholder chips to render.
  ///
  /// Defaults to `4`.
  final int itemCount;

  /// Whether to render a placeholder for the category title.
  ///
  /// Defaults to true, matching [SelectChipBar.showTitle].
  final bool showTitle;

  /// Horizontal spacing between placeholder chips.
  ///
  /// Defaults to 0.0, matching [SelectChipBar.spacing].
  final double spacing;

  /// The background color of the skeleton.
  ///
  /// If null, [SelectChipBarTheme.backgroundColor] is used. If that is also
  /// null, the value is [Colors.transparent].
  final Color? backgroundColor;

  /// The padding around the skeleton's contents.
  ///
  /// If null, [SelectChipBarTheme.padding] is used. If that is also null,
  /// the value is [EdgeInsets.zero].
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = SelectChipBarTheme.of(context);
    final defaults = SelectChipBarDefaults(context);

    final effectiveBackgroundColor =
        backgroundColor ?? theme.backgroundColor ?? defaults.backgroundColor!;

    final effectivePadding = padding ?? theme.padding ?? defaults.padding!;

    // [SkeletonTile.random] widths start at half the screen width, which is
    // far too wide for chips; generate small chip-like widths instead.
    final random = Random();
    final chips = [
      for (var i = 0; i < itemCount; i++)
        SkeletonTile(
          width: (random.nextInt(48) + 48).toDouble(),
          height: 30,
          borderRadius: BorderRadius.circular(4),
        ),
    ];

    final chipGroup = SingleChildScrollView(
      padding: EdgeInsets.zero,
      physics: const ClampingScrollPhysics(),
      scrollDirection: Axis.horizontal,
      child: Row(children: chips.separateWith(SizedBox(width: spacing))),
    );

    return Container(
      height: kSelectChipBarHeight,
      color: effectiveBackgroundColor,
      padding: effectivePadding,
      child: SkeletonView(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showTitle)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: SkeletonTile(
                  width: 60,
                  height: 24,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            Expanded(child: chipGroup),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}
