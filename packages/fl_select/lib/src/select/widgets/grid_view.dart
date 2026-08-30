import 'dart:math';

import 'package:flutter/material.dart';

import '../constants.dart';
import '../select_entry.dart';
import 'constants.dart';
import 'field_tile.dart';
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
    with AutomaticKeepAliveClientMixin {
  SelectRangeEntry? _firstCustomEntry;
  SelectRangeEntry? _lastCustomEntry;

  late List<SelectEntry> _entriesWithoutCustom;

  TextEditingController? _minController;
  TextEditingController? _maxController;

  FocusNode? _minFocusNode;
  FocusNode? _maxFocusNode;

  late SelectEntries _selectedEntries;

  @override
  void initState() {
    super.initState();

    _selectedEntries = widget.selectedEntries ?? {};

    _firstCustomEntry = widget.entries.firstCustomOrNull;
    _lastCustomEntry = widget.entries.lastCustomOrNull;
    _entriesWithoutCustom = widget.entries;
    if (_firstCustomEntry != null || _lastCustomEntry != null) {
      _entriesWithoutCustom = widget.entries.where(testNotCustomItem).toList();
      _minController ??= TextEditingController();
      _maxController ??= TextEditingController();
      _minFocusNode ??= FocusNode();
      _maxFocusNode ??= FocusNode();
    }

    // Restore selection state for custom items.
    _restoreCustomSelectionToInputs();

    _minFocusNode?.addListener(_focusListener);
    _maxFocusNode?.addListener(_focusListener);
  }

  /// Whether [e] is this view's own custom range entry.
  ///
  /// In a multi-category tree, every category shares the same level-1
  /// selection set and custom entries all use the same id (`custom`). We must
  /// therefore scope restoration to the entry owned by this category
  /// ([widget.category].id) so a value committed in one category never leaks
  /// into another category's input fields.
  bool _isOwnCustom(SelectRangeEntry e) {
    final categoryId = widget.category?.id;
    if (categoryId == null) return e.isCustom;
    return e.isCustom && e.parentId == categoryId;
  }

  void _restoreCustomSelectionToInputs() {
    for (var selectedEntry in _selectedEntries) {
      if (selectedEntry is SelectRangeEntry && _isOwnCustom(selectedEntry)) {
        _minController?.text = selectedEntry.min?.toString() ?? '';
        _maxController?.text = selectedEntry.max?.toString() ?? '';
      }
    }
  }

  @override
  void didUpdateWidget(covariant SelectGridView oldWidget) {
    super.didUpdateWidget(oldWidget);

    _selectedEntries = widget.selectedEntries ?? {};

    _firstCustomEntry = widget.entries.firstCustomOrNull;
    _lastCustomEntry = widget.entries.lastCustomOrNull;
    _entriesWithoutCustom = widget.entries;
    if (_firstCustomEntry != null || _lastCustomEntry != null) {
      _entriesWithoutCustom = widget.entries.where(testNotCustomItem).toList();
    }

    // Restore selection state for custom items.
    _restoreCustomSelectionToInputs();

    // When the custom range was selected and is now removed (e.g. tapping a
    // preset or clicking reset), clear the input fields so stale values are not
    // left behind. We only react to this transition (not every rebuild) to
    // avoid clobbering text the user is actively typing.
    final oldHadCustom = (oldWidget.selectedEntries ?? {})
        .whereType<SelectRangeEntry>()
        .any(_isOwnCustom);
    final newHasCustom =
        _selectedEntries.whereType<SelectRangeEntry>().any(_isOwnCustom);
    if (oldHadCustom && !newHasCustom) {
      _clearAllInput();
      _unfocusAllInput();
    }
  }

  @override
  void dispose() {
    _minFocusNode?.removeListener(_focusListener);
    _maxFocusNode?.removeListener(_focusListener);

    _minController?.dispose();
    _maxController?.dispose();
    _minFocusNode?.dispose();
    _maxFocusNode?.dispose();

    super.dispose();
  }

  void _focusListener() {
    if (!(_minFocusNode?.hasFocus == true) &&
        !(_maxFocusNode?.hasFocus == true)) {
      _commitCustomRange(_firstCustomEntry);
      _commitCustomRange(_lastCustomEntry);
    }
  }

  /// Parses the current min/max input, normalizes it onto [custom], and notifies
  /// the listener via [OnChanged].
  void _commitCustomRange(SelectRangeEntry? custom) {
    if (custom == null) return;
    final minText = _minController!.text;
    final maxText = _maxController!.text;
    var minInt = int.tryParse(minText) ?? 0;
    var maxInt = int.tryParse(maxText) ?? 0;
    // Only normalize an inverted range when both bounds have actually been
    // entered. Otherwise an empty field (parsed as 0) would spuriously trigger
    // a swap and push a freshly-typed min value into the max field (or clear
    // the min field), losing the user's input.
    final bothEntered = minText.isNotEmpty && maxText.isNotEmpty;
    final swapped = bothEntered && minInt > maxInt;
    if (swapped) {
      final temp = minInt;
      minInt = maxInt;
      maxInt = temp;
    }
    custom.min = (minInt == 0) ? null : minInt;
    custom.max = (maxInt == 0) ? null : maxInt;
    // Keep the entry's name in sync with the committed range so downstream
    // consumers (e.g. the applied-result label on a popup trigger) show
    // "111-222" instead of a null name. Mirrors [SelectRangeView]'s slider
    // commit; safe because name is not part of == / hashCode.
    if (custom.hasCustomValue) {
      custom.name = '${custom.min ?? ''}${widget.toText}${custom.max ?? ''}';
    }
    // Reflect the canonical (swapped) order back into the fields so the display
    // immediately shows "left small, right big" instead of the raw typed order.
    if (swapped) {
      _minController?.text = custom.min?.toString() ?? '';
      _maxController?.text = custom.max?.toString() ?? '';
    }
    final index = widget.entries.indexOf(custom);
    widget.onChanged(index, custom);
  }

  bool get inputNotEmpty =>
      (_minController?.text.isNotEmpty ?? false) ||
      (_maxController?.text.isNotEmpty ?? false);

  void _clearAllInput() {
    if (inputNotEmpty) {
      _minController?.clear();
      _maxController?.clear();
    }
  }

  bool get inputHasFocus =>
      (_minFocusNode?.hasFocus ?? false) || (_maxFocusNode?.hasFocus ?? false);

  void _unfocusAllInput() {
    if (inputHasFocus) {
      _minFocusNode?.unfocus();
      _maxFocusNode?.unfocus();
    }
  }

  void _onItemTap(int index, SelectEntry item) {
    // Clear custom input
    _clearAllInput();
    _unfocusAllInput();
    widget.onChanged(index, item);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final showTitle = widget.showTitle && widget.category?.name != null;
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: widget.padding,
      child: Column(
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
          if (_firstCustomEntry != null)
            SelectFieldTile(
              _firstCustomEntry!,
              padding: const EdgeInsets.only(bottom: 10.0),
              minController: _minController,
              maxController: _maxController,
              minFocusNode: _minFocusNode,
              maxFocusNode: _maxFocusNode,
              variant: widget.fieldVariant,
              separator: widget.toText,
              // Pressing enter commits immediately instead of waiting for a
              // focus loss (e.g. closing the panel without tapping outside).
              onMinSubmitted: (_) => _commitCustomRange(_firstCustomEntry),
              onMaxSubmitted: (_) => _commitCustomRange(_firstCustomEntry),
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
          if (_lastCustomEntry != null)
            SelectFieldTile(
              _lastCustomEntry!,
              padding: const EdgeInsets.only(top: 10.0),
              minController: _minController,
              maxController: _maxController,
              minFocusNode: _minFocusNode,
              maxFocusNode: _maxFocusNode,
              variant: widget.fieldVariant,
              separator: widget.toText,
              onMinSubmitted: (_) => _commitCustomRange(_lastCustomEntry),
              onMaxSubmitted: (_) => _commitCustomRange(_lastCustomEntry),
            ),
        ],
      ),
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
