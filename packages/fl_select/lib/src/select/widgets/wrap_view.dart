import 'dart:math';

import 'package:fl_select/src/select/widgets/widgets.dart';
import 'package:flutter/material.dart';

import '../select_delegate.dart';
import '../select_entry.dart';
import 'chip_host.dart';
import 'custom_range_host.dart';

/// A wrap chip group for selecting among sibling [SelectEntry] entries.
///
/// Renders all [SelectEntry] subtypes as chips laid out by a [Wrap], so the
/// group flows onto as many rows as needed and the view's height grows to
/// fit. This is the canonical render target for [SelectWrapLayout].
///
/// A custom range entry (a [SelectRangeEntry] with the special id `custom`,
/// see [SelectRangeEntryExt.isCustom]) placed first or last in [entries] is
/// not rendered as a chip. Instead it is rendered as a min/max input field
/// above or below the chip group, mirroring [SelectGridView]. The committed
/// value is reported through [onChanged] once both fields lose focus.
class SelectWrapView extends StatefulWidget {
  const SelectWrapView({
    super.key,
    this.category,
    required this.entries,
    this.selectedEntries,
    this.showTitle = true,
    this.spacing = 0.0,
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
  /// group's title when [showTitle] is true.
  final SelectEntry? category;

  /// The sibling entries to display as chips.
  final List<SelectEntry> entries;

  /// The set of currently selected entries.
  ///
  /// Chips whose entry is contained in this set are rendered in the selected
  /// state. When null, no chip is considered selected.
  final SelectEntries? selectedEntries;

  /// Whether to show the category title.
  ///
  /// The title is always stacked above the chip group — the wrap form has no
  /// title-left layout.
  final bool showTitle;

  /// Horizontal spacing between chips in a row; the [Wrap.spacing].
  final double spacing;

  /// Vertical spacing between wrapped chip rows; the [Wrap.runSpacing].
  final double runSpacing;

  /// The color of the group's background.
  ///
  /// If null, the value from the surrounding [SelectChipBarTheme] or the
  /// default is used.
  final Color? backgroundColor;

  /// The padding around the group's contents.
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
  /// gesture handler so taps keep flowing through this view's normal
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
  final TextStyle? labelStyle;

  /// The text style for a selected chip's `label`.
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
  State<SelectWrapView> createState() => _SelectWrapViewState();
}

class _SelectWrapViewState extends State<SelectWrapView>
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
  void didUpdateWidget(covariant SelectWrapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _selectedEntries = widget.selectedEntries ?? {};
    updateCustomRange(oldSelectedEntries: oldWidget.selectedEntries ?? {});
  }

  @override
  void dispose() {
    disposeCustomRange();
    super.dispose();
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

    final showTitle = widget.showTitle && widget.category?.name != null;

    return Container(
      color: style.backgroundColor,
      padding: style.padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showTitle)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: DefaultTextStyle.merge(
                style: Theme.of(context).textTheme.titleSmall ??
                    const TextStyle(fontSize: 16),
                child: Text(widget.category?.name ?? ''),
              ),
            ),
          if (firstCustomRange != null)
            buildCustomRangeFieldTile(
              isHeader: true,
              padding: const EdgeInsets.only(bottom: 10.0),
              variant: widget.fieldVariant,
            ),
          Wrap(
            spacing: widget.spacing,
            runSpacing: widget.runSpacing,
            children: buildChipChildren(style),
          ),
          if (lastCustomRange != null)
            buildCustomRangeFieldTile(
              isHeader: false,
              padding: const EdgeInsets.only(top: 10.0),
              variant: widget.fieldVariant,
            ),
        ],
      ),
    );
  }
}

/// Loading skeleton for [SelectWrapView].
///
/// Renders [itemCount] placeholder chips shaped like real chips (see
/// [SelectChip]) flowing through a [Wrap], plus an optional title
/// placeholder, mirroring the layout that [SelectWrapView] produces for the
/// same arguments.
class SelectWrapViewSkeleton extends StatelessWidget {
  const SelectWrapViewSkeleton({
    super.key,
    this.itemCount = 4,
    this.showTitle = true,
    this.spacing = 0.0,
    this.runSpacing = 0.0,
    this.backgroundColor,
    this.padding,
  });

  /// The number of placeholder chips to render.
  ///
  /// Defaults to `4`.
  final int itemCount;

  /// Whether to render a placeholder for the category title.
  ///
  /// Defaults to true, matching [SelectWrapView.showTitle].
  final bool showTitle;

  /// Horizontal spacing between placeholder chips.
  ///
  /// Defaults to 0.0, matching [SelectWrapView.spacing].
  final double spacing;

  /// Vertical spacing between wrapped placeholder chip rows.
  ///
  /// Defaults to 0.0, matching [SelectWrapView.runSpacing].
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

    return Container(
      color: effectiveBackgroundColor,
      padding: effectivePadding,
      child: SkeletonView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showTitle)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SkeletonTile(
                  width: (random.nextInt(72) + 72).toDouble(),
                  height: 24,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            Wrap(spacing: spacing, runSpacing: runSpacing, children: chips),
          ],
        ),
      ),
    );
  }
}
