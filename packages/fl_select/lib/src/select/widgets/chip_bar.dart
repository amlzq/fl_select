import 'dart:math';

import 'package:flutter/material.dart';

import '../constants.dart';
import '../select_delegate.dart';
import '../select_entry.dart';
import 'chip_bar_theme.dart';
import 'chip_host.dart';
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
    this.itemBuilder,
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

  /// Optional builder that fully replaces each chip's widget.
  ///
  /// When non-null, regular entries render as the returned widget instead of
  /// the default chip; the builder renders its own selected-state visuals
  /// from `selected` and wires `onTap` (e.g. via [InkWell]) to its own
  /// gesture handler so taps keep flowing through this bar's normal
  /// selection logic. Returning null falls back to the default chip. Custom
  /// range entries still render as the built-in min/max input field.
  final SelectItemBuilder? itemBuilder;

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

class _SelectChipBarState extends State<SelectChipBar>
    with CustomRangeHost, SelectChipHost {
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

  @override
  SelectItemBuilder? get chipItemBuilder => widget.itemBuilder;

  @override
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

  /// Lays the category title out to the left of [chipGroup] in a single row.
  Widget layoutTitleAround(
    Widget chipGroup, {
    required bool showTitle,
    SelectEntry? category,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showTitle && category?.name != null)
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: DefaultTextStyle.merge(
              style:
                  Theme.of(context).textTheme.titleSmall ??
                  const TextStyle(fontSize: 16),
              child: Text(category?.name ?? ''),
            ),
          ),
        Expanded(child: chipGroup),
        const SizedBox(width: 12),
      ],
    );
  }

  /// Scaffolds the custom range field (if any) around [content]: a header
  /// field above when [CustomRangeHost.firstCustomRange] is set, a footer
  /// field below when [CustomRangeHost.lastCustomRange] is set.
  Widget wrapCustomRangeFields(
    Widget content, {
    SelectFieldTileVariant? fieldVariant,
  }) {
    if (!hasCustomRange) return content;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (firstCustomRange != null)
          buildCustomRangeFieldTile(
            isHeader: true,
            padding: const EdgeInsets.only(bottom: 10.0),
            variant: fieldVariant,
          ),
        content,
        if (lastCustomRange != null)
          buildCustomRangeFieldTile(
            isHeader: false,
            padding: const EdgeInsets.only(top: 10.0),
            variant: fieldVariant,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = resolveSelectChipBarStyle(
      context,
      variant: widget.variant,
      backgroundColor: widget.backgroundColor,
      padding: widget.padding,
      chipColor: widget.chipColor,
      selectedChipColor: widget.selectedChipColor,
      labelStyle: widget.labelStyle,
      selectedLabelStyle: widget.selectedLabelStyle,
    );

    final chipGroup = Scrollbar(
      child: SingleChildScrollView(
        padding: EdgeInsets.zero,
        physics: const ClampingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        child: Row(
          children: buildChipChildren(
            style,
          ).separateWith(SizedBox(width: widget.spacing)),
        ),
      ),
    );

    // A custom range entry grows the bar above its fixed height.
    final isFixedHeight = !hasCustomRange;

    Widget content = layoutTitleAround(
      chipGroup,
      showTitle: widget.showTitle,
      category: widget.category,
    );

    content = wrapCustomRangeFields(content, fieldVariant: widget.fieldVariant);

    return Container(
      height: isFixedHeight ? kSelectChipBarHeight : null,
      color: style.backgroundColor,
      padding: style.padding,
      child: content,
    );
  }
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

    final content = Row(
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
    );

    return Container(
      height: kSelectChipBarHeight,
      color: effectiveBackgroundColor,
      padding: effectivePadding,
      child: SkeletonView(child: content),
    );
  }
}
