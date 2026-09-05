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
import 'wrap_view.dart';

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
    @Deprecated(
      'Use SelectWrapView instead. This will be removed in a future version.',
    )
    this.isWrapable = false,
    this.showTitle = true,
    @Deprecated(
      'Use SelectWrapView instead to stack the title above the chips. '
      'This will be removed in a future version.',
    )
    this.direction = Axis.horizontal,
    this.spacing = 0.0,
    @Deprecated(
      'Only read in the deprecated isWrapable mode. '
      'Use SelectWrapView instead.',
    )
    this.runSpacing = 0.0,
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

  /// Whether the chip bar wraps onto multiple rows.
  ///
  /// Deprecated: use [SelectWrapView] for the wrapped layout. When true this
  /// bar delegates to it entirely.
  @Deprecated(
    'Use SelectWrapView instead. This will be removed in a future version.',
  )
  final bool isWrapable;

  /// Whether to show the category title.
  final bool showTitle;

  /// The direction of the [category] title relative to the chip row.
  ///
  /// Defaults to [Axis.horizontal], which lays the title to the left of the
  /// chips in a single row. Set to [Axis.vertical] to stack the title above
  /// the chip row.
  ///
  /// Deprecated: the vertical (title-above) layout moved to [SelectWrapView].
  @Deprecated(
    'Use SelectWrapView instead to stack the title above the chips. '
    'This will be removed in a future version.',
  )
  final Axis direction;

  /// The width of the separators between chips in the row.
  ///
  /// Defaults to 0.0.
  final double spacing;

  /// Vertical spacing between wrapped chip rows.
  ///
  /// Deprecated: only read in the deprecated [isWrapable] mode; see
  /// [SelectWrapView.runSpacing].
  @Deprecated(
    'Only read in the deprecated isWrapable mode. '
    'Use SelectWrapView instead.',
  )
  final double runSpacing;

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
  /// selection logic. Custom range entries still render as the built-in
  /// min/max input field.
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

  /// Lays the category title out around [chipGroup].
  ///
  /// [Axis.horizontal] (the default) puts the title to the left of the chip
  /// group in a single row; [Axis.vertical] stacks the title above it.
  Widget layoutTitleAround(
    Widget chipGroup, {
    required Axis direction,
    required bool showTitle,
    SelectEntry? category,
  }) {
    if (direction == Axis.vertical) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showTitle && category?.name != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: DefaultTextStyle.merge(
                style: Theme.of(context).textTheme.titleSmall ??
                    const TextStyle(fontSize: 16),
                child: Text(category?.name ?? ''),
              ),
            ),
          chipGroup,
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showTitle && category?.name != null)
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: DefaultTextStyle.merge(
              style: Theme.of(context).textTheme.titleSmall ??
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
    // Deprecated wrap mode: delegate the entire layout to [SelectWrapView].
    // ignore: deprecated_member_use_from_same_package
    if (widget.isWrapable) {
      return SelectWrapView(
        key: widget.key,
        category: widget.category,
        entries: widget.entries,
        selectedEntries: widget.selectedEntries,
        showTitle: widget.showTitle,
        spacing: widget.spacing,
        // ignore: deprecated_member_use_from_same_package
        runSpacing: widget.runSpacing,
        backgroundColor: widget.backgroundColor,
        padding: widget.padding,
        variant: widget.variant,
        fieldVariant: widget.fieldVariant,
        itemBuilder: widget.itemBuilder,
        chipColor: widget.chipColor,
        selectedChipColor: widget.selectedChipColor,
        labelStyle: widget.labelStyle,
        selectedLabelStyle: widget.selectedLabelStyle,
        toText: widget.toText,
        onChanged: widget.onChanged,
      );
    }

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
          children: buildChipChildren(style)
              .separateWith(SizedBox(width: widget.spacing)),
        ),
      ),
    );

    // In vertical layout the title sits above the chip row, so the bar
    // height must grow to fit the chips rather than being fixed.
    // ignore: deprecated_member_use_from_same_package
    final useVertical = widget.direction == Axis.vertical;
    final isFixedHeight = !useVertical && !hasCustomRange;

    Widget content = layoutTitleAround(
      chipGroup,
      // ignore: deprecated_member_use_from_same_package
      direction: widget.direction,
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
    @Deprecated(
      'Use SelectWrapViewSkeleton instead. '
      'This will be removed in a future version.',
    )
    this.isWrapable = false,
    this.showTitle = true,
    @Deprecated(
      'Use SelectWrapViewSkeleton instead to stack the title placeholder '
      'above the chips. This will be removed in a future version.',
    )
    this.direction = Axis.horizontal,
    this.spacing = 0.0,
    this.runSpacing = 0.0,
    this.backgroundColor,
    this.padding,
  });

  /// The number of placeholder chips to render.
  ///
  /// Defaults to `4`.
  final int itemCount;

  /// Whether the placeholder chips wrap onto multiple rows.
  ///
  /// Deprecated: use [SelectWrapViewSkeleton] for the wrapped layout. When
  /// true this skeleton delegates to it entirely.
  @Deprecated(
    'Use SelectWrapViewSkeleton instead. '
    'This will be removed in a future version.',
  )
  final bool isWrapable;

  /// Whether to render a placeholder for the category title.
  ///
  /// Defaults to true, matching [SelectChipBar.showTitle].
  final bool showTitle;

  /// The direction of the title placeholder relative to the chip row.
  ///
  /// Defaults to [Axis.horizontal], which lays the title placeholder to the
  /// left of the chips in a single row. Set to [Axis.vertical] to stack the
  /// title placeholder above the chip row.
  ///
  /// Deprecated: the vertical (title-above) layout moved to
  /// [SelectWrapViewSkeleton].
  @Deprecated(
    'Use SelectWrapViewSkeleton instead to stack the title placeholder '
    'above the chips. This will be removed in a future version.',
  )
  final Axis direction;

  /// Horizontal spacing between placeholder chips.
  ///
  /// Defaults to 0.0, matching [SelectChipBar.spacing].
  final double spacing;

  /// Vertical spacing between wrapped placeholder chip rows.
  ///
  /// Only read in the deprecated [isWrapable] mode.
  final double runSpacing;

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
    // Deprecated wrap mode: delegate to [SelectWrapViewSkeleton].
    // ignore: deprecated_member_use_from_same_package
    if (isWrapable) {
      return SelectWrapViewSkeleton(
        itemCount: itemCount,
        showTitle: showTitle,
        spacing: spacing,
        runSpacing: runSpacing,
        backgroundColor: backgroundColor,
        padding: padding,
      );
    }

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
      child: Row(
        children: chips.separateWith(SizedBox(width: spacing)),
      ),
    );

    // ignore: deprecated_member_use_from_same_package
    final content = direction == Axis.vertical
        ? Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showTitle)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SkeletonTile(
                    width: (random.nextInt(72) + 72).toDouble(),
                    height: 24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              chipGroup,
            ],
          )
        : Row(
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
      // ignore: deprecated_member_use_from_same_package
      height: direction == Axis.horizontal ? kSelectChipBarHeight : null,
      color: effectiveBackgroundColor,
      padding: effectivePadding,
      child: SkeletonView(child: content),
    );
  }
}
