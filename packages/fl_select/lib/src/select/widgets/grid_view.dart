import 'dart:math';

import 'package:flutter/material.dart';

import '../constants.dart';
import '../select_delegate.dart';
import '../select_entry.dart';
import 'constants.dart';
import 'custom_range_host.dart';
import 'field_tile_theme.dart';
import 'grid_tile.dart';
import 'grid_tile_theme.dart';
import 'skeleton_view.dart';

/// A grid view that renders terminal-node [SelectEntry] entries as selectable
/// grid tiles.
///
/// Handles all [SelectEntry] subtypes: [SelectTextEntry] and non-custom
/// [SelectRangeEntry] are rendered as tiles; a single custom
/// [SelectRangeEntry] is rendered as an input field at the header or footer.
///
/// This is the canonical render target for [SelectGridLayout].
/// Only used in tabs or flatten; uses AutomaticKeepAliveClientMixin.
class SelectGridView extends StatefulWidget {
  const SelectGridView({
    super.key,
    required this.crossAxisCount,
    this.mainAxisSpacing = 0.0,
    this.crossAxisSpacing = 0.0,
    this.childAspectRatio = 1.0,
    this.category,
    required this.entries,
    this.selectedEntries,
    required this.onChanged,
    this.padding,
    this.tileVariant,
    this.fieldVariant,
    this.itemBuilder,
    this.showTitle = true,
    this.toText = '-',
  });

  /// The category this grid belongs to, used to render its title.
  ///
  /// If provided and [showTitle] is true, the category's name is displayed as
  /// a header above the grid. Otherwise no header is shown.
  final SelectCategoryEntry? category;

  /// The terminal-node entries to display as grid tiles.
  ///
  /// This list must be a terminal-node list (no further sub-categories). When
  /// it contains a custom range entry, an input field is rendered at the header
  /// or footer of the grid.
  final List<SelectEntry> entries;

  /// The set of currently selected entries.
  ///
  /// A tile is rendered as selected when it is contained in this set.
  final SelectEntries? selectedEntries;

  /// Called when a tile is tapped or a custom range value changes.
  ///
  /// The callback receives the affected item's index and its [SelectEntry].
  /// For custom range entries the view has already parsed and normalized the
  /// min/max values onto the entry before invoking this callback, so the
  /// listener only needs to update selection state.
  final OnChanged onChanged;

  /// The padding around the grid, including the title and any range input.
  ///
  /// Defaults to [EdgeInsets.zero].
  final EdgeInsetsGeometry? padding;

  /// The number of grid columns.
  final int crossAxisCount;

  /// The vertical spacing between grid rows.
  ///
  /// Defaults to 0.0.
  final double mainAxisSpacing;

  /// The horizontal spacing between grid columns.
  ///
  /// Defaults to 0.0.
  final double crossAxisSpacing;

  /// The ratio of the cross-axis to the main-axis extent of each tile.
  ///
  /// Defaults to 1.0, which makes each tile square.
  final double childAspectRatio;

  /// The visual variant used to render the non-custom grid tiles.
  final SelectGridTileVariant? tileVariant;

  /// The visual variant used to render the optional range input field.
  final SelectFieldTileVariant? fieldVariant;

  /// Optional builder that fully replaces each grid tile's widget.
  ///
  /// When non-null, regular entries render as the returned widget instead of
  /// the default grid tile; the builder renders its own selected-state
  /// visuals from `selected` and wires `onTap` (e.g. via [InkWell]) to its own
  /// gesture handler so taps keep flowing through this view's normal selection
  /// logic. Custom range entries still render as the built-in min/max input
  /// field.
  final SelectItemBuilder? itemBuilder;

  /// Whether to show the [category] name as a header above the grid.
  ///
  /// Defaults to true. Has no effect when [category] is null.
  final bool showTitle;

  /// Text rendered between the two range input fields (default: `'-'`).
  final String toText;

  @override
  State<SelectGridView> createState() => SelectGridViewState();
}

class SelectGridViewState extends State<SelectGridView>
    with CustomRangeHost, AutomaticKeepAliveClientMixin {
  late List<SelectEntry> _entriesWithoutCustom;

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
  void initState() {
    super.initState();

    _selectedEntries = widget.selectedEntries ?? {};

    initCustomRange();

    _entriesWithoutCustom = hasCustomRange
        ? widget.entries.where(testNotCustomItem).toList()
        : widget.entries;
  }

  @override
  void didUpdateWidget(covariant SelectGridView oldWidget) {
    super.didUpdateWidget(oldWidget);

    _selectedEntries = widget.selectedEntries ?? {};

    updateCustomRange(oldSelectedEntries: oldWidget.selectedEntries ?? {});

    _entriesWithoutCustom = hasCustomRange
        ? widget.entries.where(testNotCustomItem).toList()
        : widget.entries;
  }

  @override
  void dispose() {
    disposeCustomRange();

    super.dispose();
  }

  void _onItemTap(int index, SelectEntry item) {
    // Clear custom input
    clearCustomRangeInput();
    widget.onChanged(index, item);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final showTitle = widget.showTitle && widget.category?.name != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category label
        if (showTitle)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: DefaultTextStyle.merge(
              style: Theme.of(context).textTheme.titleSmall ??
                  const TextStyle(fontSize: 16),
              child: Text(widget.category?.name ?? ''),
            ),
          ),
        // An input item at header
        if (firstCustomRange != null)
          buildCustomRangeFieldTile(
            isHeader: true,
            padding: const EdgeInsets.only(bottom: 10.0),
            variant: widget.fieldVariant,
          ),
        // Grid of items (3 columns)
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: widget.crossAxisCount,
            childAspectRatio: widget.childAspectRatio,
            mainAxisSpacing: widget.mainAxisSpacing,
            crossAxisSpacing: widget.crossAxisSpacing,
          ),
          itemCount: _entriesWithoutCustom.length,
          itemBuilder: (context, index) {
            final entry = _entriesWithoutCustom[index];
            final selected = _selectedEntries.contains(entry);
            final customBuilder = widget.itemBuilder;
            if (customBuilder != null) {
              return customBuilder(
                context,
                entry,
                selected: selected,
                onTap: () => _onItemTap(index, entry),
              );
            }
            return SelectGridTile(
              onTap: () => _onItemTap.call(index, entry),
              enabled: entry.enabled,
              label: entry.name ?? '',
              selected: selected,
              variant: widget.tileVariant,
            );
          },
        ),
        // An input item at footer
        if (lastCustomRange != null)
          buildCustomRangeFieldTile(
            isHeader: false,
            padding: const EdgeInsets.only(top: 10.0),
            variant: widget.fieldVariant,
          ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}

/// Loading skeleton for [SelectGridView].
class SelectGridSkeleton extends StatelessWidget {
  const SelectGridSkeleton({
    super.key,
    required this.itemCount,
    this.padding,
    required this.crossAxisCount,
    this.mainAxisSpacing = 0.0,
    this.crossAxisSpacing = 0.0,
    this.childAspectRatio = 1.0,
  });

  /// The number of placeholder tiles to render in the skeleton grid.
  final int itemCount;

  /// The padding around the skeleton, including the title and grid.
  ///
  /// Defaults to [EdgeInsets.zero].
  final EdgeInsetsGeometry? padding;

  /// The number of grid columns in the skeleton.
  final int crossAxisCount;

  /// The vertical spacing between skeleton rows.
  ///
  /// Defaults to 0.0.
  final double mainAxisSpacing;

  /// The horizontal spacing between skeleton columns.
  ///
  /// Defaults to 0.0.
  final double crossAxisSpacing;

  /// The ratio of the cross-axis to the main-axis extent of each placeholder
  /// tile.
  ///
  /// Defaults to 1.0.
  final double childAspectRatio;

  @override
  Widget build(BuildContext context) {
    final random = Random();
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: SkeletonView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SkeletonTile(random: random, height: 24),
            ),
            Flexible(
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: childAspectRatio,
                  mainAxisSpacing: mainAxisSpacing,
                  crossAxisSpacing: crossAxisSpacing,
                ),
                itemCount: itemCount,
                itemBuilder: (context, index) {
                  return SkeletonTile(
                    borderRadius: BorderRadius.circular(4),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
